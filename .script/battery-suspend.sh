#!/bin/sh
# Suspend at the kernel's BAT0 alarm trip point. Invoked by the existing udev
# rule on BAT0 and AC events; no timer or polling is needed.

set -u

PATH=/usr/bin:/usr/sbin:/bin:/sbin
export PATH

BAT=/sys/class/power_supply/BAT0
AC=/sys/class/power_supply/AC
STATE=/run/battery-suspend.state
LOG=/run/battery-suspend.log
ALARM_CACHE=/run/battery-notify.alarm

log() {
	echo "$(date '+%F %T') $*" >>"$LOG" 2>/dev/null
}

read_int() {
	v=$(cat "$1" 2>/dev/null) || v=
	case "$v" in
	'' | *[!0-9]*) echo 0 ;;
	*) echo "$v" ;;
	esac
}

# Remember the kernel's alarm in case firmware clears it after the trip point.
remember_alarm() {
	a=$(read_int "$BAT/alarm")
	[ "$a" -gt 0 ] || return 0
	[ "$(cat "$ALARM_CACHE" 2>/dev/null)" = "$a" ] && return 0
	echo "$a" >"$ALARM_CACHE" 2>/dev/null
}

suspend_if_low() {
	[ "$(cat "$BAT/status" 2>/dev/null)" = Discharging ] || return 0
	[ "$(read_int "$AC/online")" -eq 0 ] || return 0
	energy=$(read_int "$BAT/energy_now")
	alarm=$(read_int "$BAT/alarm")
	[ "$energy" -gt 0 ] && [ "$alarm" -gt 0 ] && [ "$energy" -le "$alarm" ] || return 0

	# BAT0 and AC events can arrive together. Only one may request suspend.
	(set -C; : >"$STATE") 2>/dev/null || return 0
	if [ "$(read_int "$AC/online")" -ne 0 ]; then
		rm -f "$STATE"
		return 0
	fi

	log "suspend: energy=$energy alarm=$alarm"
	if ! timeout 10 loginctl suspend; then
		log 'suspend: loginctl failed; allowing retry on next event'
		rm -f "$STATE"
	fi
}

remember_alarm

case "${1:-}" in
bat)
	suspend_if_low
	;;
ac)
	if [ "$(read_int "$AC/online")" -eq 1 ]; then
		rm -f "$STATE"

		# Restore only the alarm value previously set by the kernel.
		if [ "$(read_int "$BAT/alarm")" -eq 0 ]; then
			known=$(read_int "$ALARM_CACHE")
			if [ "$known" -gt 0 ] && echo "$known" >"$BAT/alarm" 2>/dev/null; then
				log "alarm: restored $known"
			else
				log 'alarm: restore failed'
			fi
		fi
	else
		# An unplug below the alarm has no threshold crossing to trigger BAT0.
		suspend_if_low
	fi
	;;
*)
	echo "usage: ${0##*/} {bat|ac}" >&2
	exit 2
	;;
esac
