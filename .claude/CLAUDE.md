# Environment

- **Python** — Use the project venv if it exists; else ask: new project venv, or global `/home/chavi/.venv/bin/{python,pip}`.
- **Node** — `npm install -g` needs no sudo (user-level prefix).
- **sudo** — `SUDO_ASKPASS` is set (GUI dialog via zenity). Use `sudo -A <cmd>`. Never run `claude-askpass` directly — it prints the password to stdout, which lands in the transcript.
