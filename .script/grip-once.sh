#!/usr/bin/env bash

(
  go-grip --no-reload "$@" >/dev/null 2>&1 &
  sleep 3
  kill $! 2>/dev/null
) &>/dev/null &
disown
