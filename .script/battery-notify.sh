#!/bin/sh
# battery-notify - low battery notification driven entirely by the ACPI _BTP
# battery trip point. No daemon, no timer, no polling, no loop.
#
# This kernel emits no uevent on battery capacity change (measured: 100s across
# 90%->92% and 13min across 96%->95%, both completely silent), which is why
# upowerd polls. It does emit uevents on *status* change and on AC plug/unplug.
#
# So instead of watching capacity, we listen for the trip point the firmware has
# already armed at /sys/class/power_supply/BAT0/alarm (2770000 uWh, ~5%): the EC
# raises an interrupt when the battery crosses it, the driver turns that into a
# uevent, and udev runs this script once. Nothing runs until the battery is low.
#
# We deliberately never set a threshold of our own. The firmware re-arms its
# default at every boot, so there is nothing here to maintain and no boot-time
# dependency. (A 20% variant was tried and rejected for exactly that reason.)
#
# Invoked only by /etc/udev/rules.d/99-battery-notify.rules, as root:
#   battery-notify bat     a BAT0 uevent - while discharging, the trip point fired
#   battery-notify ac      an AC uevent - plugged in or unplugged
#   battery-notify test    force a notification, to verify the session hand-off

set -u

# udev provides a minimal environment; do not inherit whatever PATH it has.
PATH=/usr/bin:/usr/sbin:/bin:/sbin
export PATH

BAT=/sys/class/power_supply/BAT0
AC=/sys/class/power_supply/AC
STATE=/run/battery-notify.state
LOG=/run/battery-notify.log

# This machine's own trip point, from its _BIX design_capacity_warning
# (2770000 uWh, ~5% of a 55.4 Wh pack). We never change the threshold - this
# constant exists only so we can restore the firmware's value unchanged if the
# firmware ever zeroes it. This firmware does not, so it is a no-op safety net.
FIRMWARE_ALARM_UWH=2770000

log() {
	# /run is tmpfs: no disk writes, no rotation needed, gone on reboot.
	echo "$(date '+%F %T') $*" >>"$LOG" 2>/dev/null
}

read_int() {
	# echo the contents of $1 as an integer, or 0 if unreadable/not a number.
	v=$(cat "$1" 2>/dev/null) || v=
	case "$v" in
	'' | *[!0-9]*) echo 0 ;;
	*) echo "$v" ;;
	esac
}

capacity() {
	cat "$BAT/capacity" 2>/dev/null || echo '?'
}

notify() {
	summary=$1
	body=$2

	# The session bus is at a random /tmp path (dbus-run-session niri
	# --session), and /run/user/1000/bus does not exist here, so the only
	# reliable source for it is the compositor's own environment.
	pid=$(pgrep -x niri | head -n1)
	if [ -z "$pid" ]; then
		log "notify: no niri process; cannot deliver"
		return 1
	fi

	# notify-send is a pure D-Bus client, so the bus address is all we need.
	# WAYLAND_DISPLAY is deliberately not forwarded: niri creates the display
	# rather than inheriting it, so its own environ does not carry the variable,
	# and mako picks it up from the D-Bus activation environment that
	# `niri --session` exports.
	user=$(stat -c %U "/proc/$pid" 2>/dev/null)
	bus=$(tr '\0' '\n' <"/proc/$pid/environ" 2>/dev/null |
		sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p' | head -n1)

	if [ -z "$user" ] || [ -z "$bus" ]; then
		log "notify: could not read session env from pid $pid"
		return 1
	fi

	# udev waits for RUN+= to return, so never block indefinitely. notify-send
	# returns as soon as dbus replies. mako is not running most of the time; it
	# is D-Bus activated on demand via fr.emersion.mako.service, and because
	# dbus-daemon spawns it rather than us, it survives udev reaping this
	# event's processes.
	timeout 10 runuser -u "$user" -- \
		env DBUS_SESSION_BUS_ADDRESS="$bus" \
		notify-send -u critical -a Battery -i battery-caution "$summary" "$body"
	log "notify: '$summary' -> $user rc=$?"
}

warn_low() {
	: >"$STATE"
	notify 'Battery critically low' "$(capacity)% remaining - plug in now"
}

case "${1:-}" in
bat)
	status=$(cat "$BAT/status" 2>/dev/null || echo Unknown)
	energy=$(read_int "$BAT/energy_now")
	alarm=$(read_int "$BAT/alarm")
	log "bat: status=$status capacity=$(capacity)% energy=$energy alarm=$alarm"

	# Reaching here while discharging means the trip point fired.
	[ "$status" = Discharging ] || exit 0
	[ "$alarm" -gt 0 ] || exit 0
	[ "$energy" -le "$alarm" ] || exit 0
	[ -e "$STATE" ] && exit 0

	warn_low
	;;

ac)
	online=$(read_int "$AC/online")
	log "ac: online=$online capacity=$(capacity)%"

	if [ "$online" -eq 1 ]; then
		# Plugged in: allow the next discharge cycle to warn again.
		rm -f "$STATE"

		# Restore the firmware's own value only if it has been zeroed - the
		# same number, never a threshold of our choosing.
		if [ "$(read_int "$BAT/alarm")" -le 0 ]; then
			if echo "$FIRMWARE_ALARM_UWH" >"$BAT/alarm" 2>/dev/null; then
				log "ac: restored firmware alarm $FIRMWARE_ALARM_UWH"
			else
				log "ac: FAILED to restore firmware alarm"
			fi
		fi
	else
		# Unplugged while already below the trip point: no crossing can occur,
		# so the trip point will never fire. Warn now instead.
		energy=$(read_int "$BAT/energy_now")
		alarm=$(read_int "$BAT/alarm")
		if [ "$alarm" -gt 0 ] && [ "$energy" -le "$alarm" ] && [ ! -e "$STATE" ]; then
			warn_low
		fi
	fi
	;;

test)
	log 'test: forcing a notification'
	notify 'Battery notification test' 'battery-notify is wired up correctly'
	;;

*)
	echo "usage: ${0##*/} {bat|ac|test}" >&2
	exit 2
	;;
esac
