#!/bin/bash

go-grip --port 6419 --no-reload "/tmp/claude-$(id -u)/response.md" >/dev/null 2>&1 &
sleep 2 && pkill go-grip
