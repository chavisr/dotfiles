#!/usr/bin/env bash
# Runs once per invocation (interval: 3 in config.jsonc).
# Keeps a cache in /tmp to avoid fetching on every call.

TICKERS_FILE="$(dirname "$0")/tickers.txt"
WEBULL_ENV="${WEBULL_ENV:-$HOME/.webull/.env}"
CACHE_FILE="/tmp/waybar-tickers.json"
STATE_FILE="/tmp/waybar-tickers.state"
CHECKSUM_FILE="/tmp/waybar-tickers.checksum"
REFRESH_INTERVAL=15

# Placeholders: {ticker} {arrow} {price} {currency} {change} {change_abs}
FORMAT="{ticker} {arrow} {price} {currency} {change}%"

trim_lines() {
    tr -d '\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^$'
}

read_tickers() {
    grep -v '^\s*#' "$TICKERS_FILE" 2>/dev/null | trim_lines
}

# Pull WEBULL_SYMBOL_WHITELIST out of the webull .env without sourcing it —
# that file holds credentials and must not land in this script's environment.
read_whitelist() {
    [[ -r "$WEBULL_ENV" ]] || return 0
    local line
    line=$(grep -m1 -E '^[[:space:]]*(export[[:space:]]+)?WEBULL_SYMBOL_WHITELIST=' "$WEBULL_ENV" 2>/dev/null) || return 0
    line=${line#*=}
    line=${line%$'\r'}
    line=${line#[\"\']}
    line=${line%[\"\']}
    tr ',' '\n' <<< "$line" | trim_lines
}

# tickers.txt first, then any whitelist symbol not already listed.
read_symbols() {
    { read_tickers; read_whitelist; } | awk '!seen[$0]++'
}

fetch_cache() {
    local tickers=("$@")
    local tmp first=1 fresh=0
    tmp=$(mktemp)
    printf '{' > "$tmp"
    for sym in "${tickers[@]}"; do
        local body http_code curr prev currency change
        body=$(mktemp)
        http_code=$(curl -s -o "$body" --max-time 10 \
            -H "User-Agent: Mozilla/5.0" \
            -w "%{http_code}" \
            "https://query1.finance.yahoo.com/v8/finance/chart/${sym}?interval=1d&range=2d")
        if [[ "$http_code" != "200" ]]; then
            rm -f "$body"
            local cp cc cu
            cp=$(jq -r --arg s "$sym" '.[$s].price // empty' "$CACHE_FILE" 2>/dev/null)
            cc=$(jq -r --arg s "$sym" '.[$s].change // empty' "$CACHE_FILE" 2>/dev/null)
            cu=$(jq -r --arg s "$sym" '.[$s].currency // empty' "$CACHE_FILE" 2>/dev/null)
            if [[ -n "$cp" && -n "$cc" ]]; then
                [[ "$first" -eq 0 ]] && printf ',' >> "$tmp"
                printf '"%s":{"price":%s,"change":%s,"currency":"%s"}' "$sym" "$cp" "$cc" "$cu" >> "$tmp"
                first=0
            fi
            continue
        fi
        curr=$(jq -r '.chart.result[0].meta.regularMarketPrice // empty' "$body")
        prev=$(jq -r '.chart.result[0].meta.chartPreviousClose // empty' "$body")
        currency=$(jq -r '.chart.result[0].meta.currency // empty' "$body")
        rm -f "$body"
        [[ -z "$prev" || -z "$curr" ]] && continue
        change=$(awk -v c="$curr" -v p="$prev" 'BEGIN { printf "%.4f", (c-p)/p*100 }')
        [[ "$first" -eq 0 ]] && printf ',' >> "$tmp"
        printf '"%s":{"price":%s,"change":%s,"currency":"%s"}' "$sym" "$curr" "$change" "$currency" >> "$tmp"
        first=0
        (( fresh++ ))
    done
    printf '}' >> "$tmp"
    if [[ "$fresh" -gt 0 ]]; then
        mv "$tmp" "$CACHE_FILE"
    else
        rm -f "$tmp"
        [[ -f "$CACHE_FILE" ]] && touch "$CACHE_FILE"
    fi
}

render() {
    local template="$1" ticker="$2" arrow="$3" price="$4" currency="$5" change="$6" change_abs="$7"
    printf '%s' "$template" \
        | sed "s/{ticker}/$ticker/g" \
        | sed "s/{arrow}/$arrow/g" \
        | sed "s/{price}/$price/g" \
        | sed "s/{currency}/$currency/g" \
        | sed "s/{change}/$change/g" \
        | sed "s/{change_abs}/$change_abs/g"
}

build_tooltip() {
    local tip_arrows=() tip_tickers=() tip_prices=() tip_currencies=() tip_changes=() tip_colors=()
    for sym in "${TICKERS[@]}"; do
        local price change currency arrow price_fmt change_fmt color
        price=$(jq -r --arg s "$sym" '.[$s].price // empty' "$CACHE_FILE")
        change=$(jq -r --arg s "$sym" '.[$s].change // empty' "$CACHE_FILE")
        currency=$(jq -r --arg s "$sym" '.[$s].currency // empty' "$CACHE_FILE")
        [[ -z "$price" || -z "$change" ]] && continue
        arrow=$(awk -v p="$change" 'BEGIN { if (p > 0.1) print "↑"; else if (p < -0.1) print "↓"; else print "→" }')
        price_fmt=$(awk -v p="$price" 'BEGIN { printf "%.2f", p }')
        change_fmt=$(awk -v c="$change" 'BEGIN { printf "%+.2f", c }')
        color=$(awk -v p="$change" 'BEGIN { if (p > 0.1) print "#98c379"; else if (p < -0.1) print "#e06c75"; else print "#e5c07b" }')
        tip_arrows+=("$arrow")
        tip_tickers+=("$sym")
        tip_prices+=("$price_fmt")
        tip_currencies+=("$currency")
        tip_changes+=("${change_fmt}%")
        tip_colors+=("$color")
    done
    local max_t=0 max_p=0 max_c=0
    for (( k=0; k<${#tip_tickers[@]}; k++ )); do
        (( ${#tip_tickers[k]} > max_t )) && max_t=${#tip_tickers[k]}
        (( ${#tip_prices[k]} > max_p )) && max_p=${#tip_prices[k]}
        (( ${#tip_changes[k]} > max_c )) && max_c=${#tip_changes[k]}
    done
    local lines=()
    for (( k=0; k<${#tip_tickers[@]}; k++ )); do
        local line
        line=$(printf "%s  %-*s  %*s %-3s  %*s" \
            "${tip_arrows[k]}" "$max_t" "${tip_tickers[k]}" \
            "$max_p" "${tip_prices[k]}" "${tip_currencies[k]}" \
            "$max_c" "${tip_changes[k]}")
        lines+=("<span font_family='monospace' color='${tip_colors[k]}'>${line}</span>")
    done
    local updated="—"
    if [[ -f "$CACHE_FILE" ]]; then
        local mtime
        mtime=$(stat -c %Y "$CACHE_FILE" 2>/dev/null)
        updated=$(date -d "@${mtime}" '+%d %b %H:%M:%S' 2>/dev/null || echo "—")
    fi
    lines+=("")
    lines+=("<span font_family='monospace' color='#6c7086'>  Last update: ${updated}</span>")
    printf '%s\n' "${lines[@]}" | sed 's/$/\\n/' | tr -d '\n'
}

mapfile -t TICKERS < <(read_symbols)
[[ "${#TICKERS[@]}" -eq 0 ]] && exit 0

# Checksum the resolved list, so edits to either source trigger a refetch.
checksum=$(printf '%s\n' "${TICKERS[@]}" | md5sum | cut -d' ' -f1)
prev_checksum=""
[[ -f "$CHECKSUM_FILE" ]] && prev_checksum=$(cat "$CHECKSUM_FILE")

if [[ "$checksum" != "$prev_checksum" ]]; then
    printf '%s' "$checksum" > "$CHECKSUM_FILE"
    printf '0' > "$STATE_FILE"
    fetch_cache "${TICKERS[@]}"
else
    now=$(date +%s)
    cache_age=999999
    [[ -f "$CACHE_FILE" ]] && cache_age=$(( now - $(stat -c %Y "$CACHE_FILE") ))
    (( cache_age >= REFRESH_INTERVAL )) && fetch_cache "${TICKERS[@]}"
fi

[[ ! -f "$CACHE_FILE" ]] && exit 0

# Rotate one ticker per invocation
i=0
[[ -f "$STATE_FILE" ]] && i=$(cat "$STATE_FILE")
sym="${TICKERS[$((i % ${#TICKERS[@]}))]}"
printf '%d' $(( (i + 1) % ${#TICKERS[@]} )) > "$STATE_FILE"

price=$(jq -r --arg s "$sym" '.[$s].price // empty' "$CACHE_FILE")
change=$(jq -r --arg s "$sym" '.[$s].change // empty' "$CACHE_FILE")
currency=$(jq -r --arg s "$sym" '.[$s].currency // empty' "$CACHE_FILE")
[[ -z "$price" || -z "$change" ]] && exit 0

css=$(awk -v p="$change" 'BEGIN { if (p > 0.1) print "up"; else if (p < -0.1) print "down"; else print "neutral" }')
arrow=$(awk -v p="$change" 'BEGIN { if (p > 0.1) print "↑"; else if (p < -0.1) print "↓"; else print "→" }')
price_fmt=$(awk -v p="$price" 'BEGIN { printf "%.2f", p }')
change_fmt=$(awk -v c="$change" 'BEGIN { printf "%+.2f", c }')
change_abs=$(awk -v c="$change" 'BEGIN { printf "%.2f", (c < 0 ? -c : c) }')

text=$(render "$FORMAT" "$sym" "$arrow" "$price_fmt" "$currency" "$change_fmt" "$change_abs")
tooltip=$(build_tooltip)

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$css"
