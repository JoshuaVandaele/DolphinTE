#!/bin/bash
set -e

REMOTE_NAME="$1"
REMOTE_URL="$2"

if [ -z "$REMOTE_NAME" ] || [ -z "$REMOTE_URL" ]; then
    echo "Usage: $0 <remote-name> <remote-url>"
    exit 1
fi

./ssh.sh <<EOF
git remote remove "$REMOTE_NAME" 2>nul
git remote add "$REMOTE_NAME" "$REMOTE_URL"
git remote -v
EOF
