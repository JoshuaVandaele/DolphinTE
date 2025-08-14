#!/bin/bash
set -e

REMOTE="$1"
BRANCH="$2"

if [ -z "$REMOTE" ] || [ -z "$BRANCH" ]; then
    echo "Usage: $0 <remote> <branch>"
    exit 1
fi

./ssh.sh <<EOF
git fetch "$REMOTE"
git checkout "$REMOTE/$BRANCH"
rmdir /s /q build
mkdir build
cd build
cmake .. -GNinja
ninja
EOF
