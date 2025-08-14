#!/bin/bash

until ssh -i Data/unsecurekey_rsa runner@localhost -p10022 \
    -o "UserKnownHostsFile=/dev/null" \
    -o StrictHostKeyChecking=no \
    -o PasswordAuthentication=no \
    -o ConnectTimeout=2 \
    -T exit 2>/dev/null
do
    echo "Waiting for SSH to become available..."
    sleep 2
done

ssh -i Data/unsecurekey_rsa runner@localhost -p10022 \
    -o "UserKnownHostsFile=/dev/null" \
    -o StrictHostKeyChecking=no \
    -o PasswordAuthentication=no \
    -T "$@"
