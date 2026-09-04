#!/bin/sh
# Runs once per invocation (interval: 3 in config.jsonc).
# Keeps a cache in /tmp to avoid fetching on every call.
#
# POSIX sh port of tickers.sh: no arrays, no [[ ]], no local, no mapfile.
# The resolved symbol list lives in a temp file instead of an array; awk does
# the numeric formatting and column alignment.

TICKERS_FILE="$(dirname "$0")/tickers.txt"
WEBULL_ENV="${WEBULL_ENV:-$HOME/.webull/.env}"
CACHE_FILE="/tmp/waybar-tickers.json"
STATE_FILE="/tmp/waybar-tickers.state"
CHECKSUM_FILE="/tmp/waybar-tickers.checksum"
REFRESH_INTERVAL=15

# Placeholders: {ticker} {arrow} {price} {currency} {change} {change_abs}
FORMAT="{ticker} {arrow} {price} {currency} {change}%"

# Pin the bar to one symbol instead of rotating. Set to "" to rotate again.
PINNED_SYMBOL="BTC-USD"

SYMBOLS_FILE=""
cleanup() {
    [ -n "$SYMBOLS_FILE" ] && rm -f "$SYMBOLS_FILE"
    return 0
}
trap cleanup EXIT
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM

trim_lines() {
    tr -d '\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^$'
}

read_tickers() {
    grep -v '^[[:space:]]*#' "$TICKERS_FILE" 2>/dev/null | trim_lines
}

# Pull WEBULL_SYMBOL_WHITELIST out of the webull .env without sourcing it —
# that file holds credentials and must not land in this script's environment.
read_whitelist() {
    [ -r "$WEBULL_ENV" ] || return 0
    _wl_line=$(grep -E '^[[:space:]]*(export[[:space:]]+)?WEBULL_SYMBOL_WHITELIST=' \
        "$WEBULL_ENV" 2>/dev/null | head -n 1)
    [ -n "$_wl_line" ] || return 0
    _wl_line=${_wl_line#*=}
    _wl_line=$(printf '%s' "$_wl_line" | tr -d '\r')
    case "$_wl_line" in
        \"*) _wl_line=${_wl_line#\"} ;;
        \'*) _wl_line=${_wl_line#\'} ;;
    esac
    case "$_wl_line" in
        *\") _wl_line=${_wl_line%\"} ;;
        *\') _wl_line=${_wl_line%\'} ;;
    esac
    printf '%s\n' "$_wl_line" | tr ',' '\n' | trim_lines
}

# tickers.txt first, then any whitelist symbol not already listed.
read_symbols() {
    { read_tickers; read_whitelist; } | awk '!seen[$0]++'
}

cache_field() {
    jq -r --arg s "$1" ".[\$s].$2 // empty" "$CACHE_FILE" 2>/dev/null
}

# Reads the symbol list from $SYMBOLS_FILE (redirect, not a pipe, so the
# counters below survive the loop).
fetch_cache() {
    _fc_tmp=$(mktemp)
    _fc_first=1
    _fc_fresh=0
    printf '{' > "$_fc_tmp"
    while IFS= read -r _fc_sym; do
        [ -n "$_fc_sym" ] || continue
        _fc_body=$(mktemp)
        _fc_code=$(curl -s -o "$_fc_body" --max-time 10 \
            -H "User-Agent: Mozilla/5.0" \
            -w "%{http_code}" \
            "https://query1.finance.yahoo.com/v8/finance/chart/${_fc_sym}?interval=1d&range=2d")
        if [ "$_fc_code" != "200" ]; then
            rm -f "$_fc_body"
            _fc_cp=$(cache_field "$_fc_sym" price)
            _fc_cc=$(cache_field "$_fc_sym" change)
            _fc_cu=$(cache_field "$_fc_sym" currency)
            if [ -n "$_fc_cp" ] && [ -n "$_fc_cc" ]; then
                [ "$_fc_first" -eq 0 ] && printf ',' >> "$_fc_tmp"
                printf '"%s":{"price":%s,"change":%s,"currency":"%s"}' \
                    "$_fc_sym" "$_fc_cp" "$_fc_cc" "$_fc_cu" >> "$_fc_tmp"
                _fc_first=0
            fi
            continue
        fi
        _fc_curr=$(jq -r '.chart.result[0].meta.regularMarketPrice // empty' "$_fc_body")
        _fc_prev=$(jq -r '.chart.result[0].meta.chartPreviousClose // empty' "$_fc_body")
        _fc_cur_sym=$(jq -r '.chart.result[0].meta.currency // empty' "$_fc_body")
        rm -f "$_fc_body"
        if [ -z "$_fc_prev" ] || [ -z "$_fc_curr" ]; then
            continue
        fi
        _fc_change=$(awk -v c="$_fc_curr" -v p="$_fc_prev" 'BEGIN { printf "%.4f", (c-p)/p*100 }')
        [ "$_fc_first" -eq 0 ] && printf ',' >> "$_fc_tmp"
        printf '"%s":{"price":%s,"change":%s,"currency":"%s"}' \
            "$_fc_sym" "$_fc_curr" "$_fc_change" "$_fc_cur_sym" >> "$_fc_tmp"
        _fc_first=0
        _fc_fresh=$((_fc_fresh + 1))
    done < "$SYMBOLS_FILE"
    printf '}' >> "$_fc_tmp"
    if [ "$_fc_fresh" -gt 0 ]; then
        mv "$_fc_tmp" "$CACHE_FILE"
    else
        rm -f "$_fc_tmp"
        [ -f "$CACHE_FILE" ] && touch "$CACHE_FILE"
    fi
    return 0
}

render() {
    printf '%s' "$1" \
        | sed "s/{ticker}/$2/g" \
        | sed "s/{arrow}/$3/g" \
        | sed "s/{price}/$4/g" \
        | sed "s/{currency}/$5/g" \
        | sed "s/{change}/$6/g" \
        | sed "s/{change_abs}/$7/g"
}

build_tooltip() {
    _tt_rows=$(mktemp)
    while IFS= read -r _tt_sym; do
        [ -n "$_tt_sym" ] || continue
        _tt_price=$(cache_field "$_tt_sym" price)
        _tt_change=$(cache_field "$_tt_sym" change)
        _tt_currency=$(cache_field "$_tt_sym" currency)
        if [ -z "$_tt_price" ] || [ -z "$_tt_change" ]; then
            continue
        fi
        printf '%s\t%s\t%s\t%s\n' "$_tt_sym" "$_tt_price" "$_tt_currency" "$_tt_change" \
            >> "$_tt_rows"
    done < "$SYMBOLS_FILE"

    _tt_updated="—"
    if [ -f "$CACHE_FILE" ]; then
        _tt_mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null)
        if [ -n "$_tt_mtime" ]; then
            _tt_updated=$(date -d "@${_tt_mtime}" '+%d %b %H:%M:%S' 2>/dev/null) || _tt_updated="—"
        fi
        [ -n "$_tt_updated" ] || _tt_updated="—"
    fi

    awk -v updated="$_tt_updated" '
        BEGIN { FS = "\t"; n = 0; mt = 0; mp = 0; mc = 0 }
        {
            n++
            tick[n] = $1
            price[n] = sprintf("%.2f", $2)
            curr[n] = $3
            chg[n] = sprintf("%+.2f%%", $4)
            v = $4 + 0
            if (v > 0.1)       { arrow[n] = "↑"; color[n] = "#98c379" }
            else if (v < -0.1) { arrow[n] = "↓"; color[n] = "#e06c75" }
            else               { arrow[n] = "→"; color[n] = "#e5c07b" }
            if (length(tick[n]) > mt)  mt = length(tick[n])
            if (length(price[n]) > mp) mp = length(price[n])
            if (length(chg[n]) > mc)   mc = length(chg[n])
        }
        END {
            fmt = "%s  %-" mt "s  %" mp "s %-3s  %" mc "s"
            for (i = 1; i <= n; i++) {
                line = sprintf(fmt, arrow[i], tick[i], price[i], curr[i], chg[i])
                printf "<span font_family='"'"'monospace'"'"' color='"'"'%s'"'"'>%s</span>\n", color[i], line
            }
            print ""
            printf "<span font_family='"'"'monospace'"'"' color='"'"'#6c7086'"'"'>  Last update: %s</span>\n", updated
        }
    ' "$_tt_rows" | sed 's/$/\\n/' | tr -d '\n'

    rm -f "$_tt_rows"
}

SYMBOLS_FILE=$(mktemp)
read_symbols > "$SYMBOLS_FILE"
count=$(grep -c '' "$SYMBOLS_FILE")
[ "$count" -eq 0 ] && exit 0

# Checksum the resolved list, so edits to either source trigger a refetch.
checksum=$(md5sum < "$SYMBOLS_FILE" | cut -d' ' -f1)
prev_checksum=""
[ -f "$CHECKSUM_FILE" ] && prev_checksum=$(cat "$CHECKSUM_FILE")

if [ "$checksum" != "$prev_checksum" ]; then
    printf '%s' "$checksum" > "$CHECKSUM_FILE"
    printf '0' > "$STATE_FILE"
    fetch_cache
else
    now=$(date +%s)
    cache_age=999999
    [ -f "$CACHE_FILE" ] && cache_age=$(( now - $(stat -c %Y "$CACHE_FILE") ))
    [ "$cache_age" -ge "$REFRESH_INTERVAL" ] && fetch_cache
fi

[ -f "$CACHE_FILE" ] || exit 0

if [ -n "$PINNED_SYMBOL" ]; then
    sym="$PINNED_SYMBOL"
else
    # Rotate one ticker per invocation
    i=0
    [ -f "$STATE_FILE" ] && i=$(cat "$STATE_FILE")
    case "$i" in
        ''|*[!0-9]*) i=0 ;;
    esac
    sym=$(sed -n "$(( i % count + 1 ))p" "$SYMBOLS_FILE")
    printf '%d' $(( (i + 1) % count )) > "$STATE_FILE"
fi

price=$(cache_field "$sym" price)
change=$(cache_field "$sym" change)
currency=$(cache_field "$sym" currency)
if [ -z "$price" ] || [ -z "$change" ]; then
    exit 0
fi

css=$(awk -v p="$change" 'BEGIN { if (p > 0.1) print "up"; else if (p < -0.1) print "down"; else print "neutral" }')
arrow=$(awk -v p="$change" 'BEGIN { if (p > 0.1) print "↑"; else if (p < -0.1) print "↓"; else print "→" }')
price_fmt=$(awk -v p="$price" 'BEGIN { printf "%.2f", p }')
change_fmt=$(awk -v c="$change" 'BEGIN { printf "%+.2f", c }')
change_abs=$(awk -v c="$change" 'BEGIN { printf "%.2f", (c < 0 ? -c : c) }')

text=$(render "$FORMAT" "$sym" "$arrow" "$price_fmt" "$currency" "$change_fmt" "$change_abs")
tooltip=$(build_tooltip)

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$css"
