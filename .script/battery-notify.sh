#!/bin/sh
# battery-notify - low battery notification driven entirely by the ACPI _BTP
# battery trip point. No daemon, no timer, no polling, no loop.
#
# This kernel emits no uevent on battery capacity change (measured: 100s across
# 90%->92% and 13min across 96%->95%, both completely silent), which is why
# upowerd polls. It does emit uevents on *status* change and on AC plug/unplug.
#
# So instead of watching capacity, we listen for the trip point already armed at
# /sys/class/power_supply/BAT0/alarm: the EC raises an interrupt when the battery
# crosses it, the driver turns that into a uevent, and udev runs this script
# once. Nothing runs until the battery is actually low.
#
# The kernel re-arms that trip point at every boot, deriving it from the pack's
# *measured* full capacity - exactly energy_full/20, confirmed on three separate
# boots (55400000->2770000, 55380000->2769000, 55360000->2768000). So it drifts
# down as the battery wears, which is what we want: the warning stays at a true
# 5% of real capacity rather than a number that slowly becomes optimistic.
#
# We deliberately never set a threshold of our own, and never hardcode one -
# there is nothing here to maintain and no boot-time dependency. (A 20% variant
# was tried and rejected for exactly that reason.)
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
ALARM_CACHE=/run/battery-notify.alarm
ID_FILE=/run/battery-notify.id


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

# Sets $user and $bus for the logged-in session, or returns 1. The session bus
# is at a random /tmp path (dbus-run-session niri --session), and
# /run/user/1000/bus does not exist here, so the only reliable source for it is
# the compositor's own environment. Both notify() and close_notification() need
# this, so it lives in one place.
find_session() {
	pid=$(pgrep -x niri | head -n1)
	if [ -z "$pid" ]; then
		log "session: no niri process"
		return 1
	fi

	# WAYLAND_DISPLAY is deliberately not forwarded: niri creates the display
	# rather than inheriting it, so its own environ does not carry the variable,
	# and mako picks it up from the D-Bus activation environment that
	# `niri --session` exports. notify-send and gdbus are pure D-Bus clients, so
	# the bus address is all we need.
	user=$(stat -c %U "/proc/$pid" 2>/dev/null)
	bus=$(tr '\0' '\n' <"/proc/$pid/environ" 2>/dev/null |
		sed -n 's/^DBUS_SESSION_BUS_ADDRESS=//p' | head -n1)

	if [ -z "$user" ] || [ -z "$bus" ]; then
		log "session: could not read env from pid $pid"
		return 1
	fi
}

notify() {
	summary=$1
	body=$2

	find_session || return 1

	# udev waits for RUN+= to return, so never block indefinitely. notify-send
	# returns as soon as dbus replies. mako is not running most of the time; it
	# is D-Bus activated on demand via fr.emersion.mako.service, and because
	# dbus-daemon spawns it rather than us, it survives udev reaping this
	# event's processes.
	#
	# -p prints the notification id, which we keep so that plugging in can close
	# this exact notification: it is urgency critical, which never expires.
	id=$(timeout 10 runuser -u "$user" -- \
		env DBUS_SESSION_BUS_ADDRESS="$bus" \
		notify-send -p -u critical -a Battery -i battery-caution "$summary" "$body")
	log "notify: '$summary' -> $user rc=$? id=$id"

	case "$id" in
	'' | *[!0-9]*) ;;
	*) echo "$id" >"$ID_FILE" 2>/dev/null ;;
	esac
}

# Close the warning we sent, so plugging in clears the red box by itself.
#
# Notification ids are handed out by whichever daemon is running and restart
# from 1 if mako restarts. If mako restarted between the warning and the
# plug-in, a stale id could close some other application's notification. We use
# each id at most once and /run is tmpfs (wiped every boot), which narrows the
# window but does not close it. Checking ownership first would mean parsing
# `makoctl list -j`, which would tie this to mako specifically; CloseNotification
# is the freedesktop standard method and works with any notifier.
close_notification() {
	id=$(read_int "$ID_FILE")
	rm -f "$ID_FILE"		# consumed, whatever it held
	[ "$id" -gt 0 ] || return 0

	find_session || return 1

	# If no daemon owns the name there is nothing to close, and asking anyway
	# would D-Bus-activate mako purely to dismiss a notification that cannot
	# exist. Staying quiet keeps the "nothing runs unnecessarily" property.
	owner=$(timeout 10 runuser -u "$user" -- \
		env DBUS_SESSION_BUS_ADDRESS="$bus" \
		gdbus call --session --dest org.freedesktop.DBus \
		--object-path /org/freedesktop/DBus \
		--method org.freedesktop.DBus.NameHasOwner \
		org.freedesktop.Notifications 2>/dev/null)
	case "$owner" in
	*true*) ;;
	*)
		log "close: no notification daemon running; nothing to close"
		return 0
		;;
	esac

	timeout 10 runuser -u "$user" -- \
		env DBUS_SESSION_BUS_ADDRESS="$bus" \
		gdbus call --session --dest org.freedesktop.Notifications \
		--object-path /org/freedesktop/Notifications \
		--method org.freedesktop.Notifications.CloseNotification \
		"$id" >/dev/null 2>&1
	log "close: dismissed notification $id rc=$?"
}

# The kernel re-arms BAT0/alarm at every boot, deriving it from the battery's
# *measured* full capacity - so it drifts down as the pack wears. Observed here:
# energy_full 55400000 -> 55380000 uWh across one day moved alarm 2770000 ->
# 2769000, exactly energy_full/20 both times. A hardcoded constant would go
# stale, so we remember whatever the kernel last armed instead. This is used
# only to put the value back if the firmware ever zeroes it after firing; we
# never pick a threshold ourselves. /run is tmpfs, so the cache is repopulated
# by the coldplug event at every boot.
remember_alarm() {
	a=$(read_int "$BAT/alarm")
	[ "$a" -gt 0 ] || return 0
	[ "$(cat "$ALARM_CACHE" 2>/dev/null)" = "$a" ] && return 0
	echo "$a" >"$ALARM_CACHE" 2>/dev/null
	log "alarm: remembered $a"
}

warn_low() {
	# Atomic. On unplug the bat and ac events fire in the same second and udev
	# runs them concurrently, so a plain test-then-create would let both pass
	# and notify twice. Only the process that wins the create notifies.
	(set -C; : >"$STATE") 2>/dev/null || return 0
	notify 'Battery critically low' "$(capacity)% remaining - plug in now"
}

remember_alarm

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
		# Plugged in: allow the next discharge cycle to warn again, and clear
		# the warning still on screen - it is critical, so it never expires.
		rm -f "$STATE"
		close_notification

		# Restore the kernel's own value only if it has been zeroed - the
		# same number it armed, never a threshold of our choosing.
		if [ "$(read_int "$BAT/alarm")" -le 0 ]; then
			# read_int, not cat: this is the only place we write to /sys, so
			# insist on a positive integer rather than trusting the cache.
			known=$(read_int "$ALARM_CACHE")
			if [ "$known" -gt 0 ] && echo "$known" >"$BAT/alarm" 2>/dev/null; then
				log "ac: restored alarm $known"
			else
				log "ac: FAILED to restore alarm (remembered='$known')"
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
