#!/usr/bin/env bash
# Start JARVIS: backend (https://127.0.0.1:8340) + frontend (http://localhost:5173).
# Ctrl+C stops both.
set -euo pipefail
cd "$(dirname "$0")"

# .env must win over any FISH_API_KEY inherited from the shell or launchctl.
unset FISH_API_KEY

if [ ! -x .venv/bin/python ]; then
  echo "Creating .venv and installing Python dependencies..."
  python3 -m venv .venv
  .venv/bin/pip install -q -r requirements.txt
  .venv/bin/python -m playwright install chromium
fi

if [ ! -d frontend/node_modules ]; then
  echo "Installing frontend dependencies..."
  (cd frontend && npm install)
fi

if [ ! -f cert.pem ] || [ ! -f key.pem ]; then
  echo "Generating self-signed certs..."
  openssl req -x509 -newkey rsa:2048 -keyout key.pem -out cert.pem \
    -days 365 -nodes -subj '/CN=localhost'
fi

trap 'kill 0' EXIT

.venv/bin/python server.py --host 127.0.0.1 &
(cd frontend && npm run dev -- --strictPort) &

echo "JARVIS starting — open http://localhost:5173 in Chrome. Ctrl+C to stop."
wait
