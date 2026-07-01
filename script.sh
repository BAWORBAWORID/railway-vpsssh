#!/bin/bash

if [ -z "$SSH_PASSWORD" ]; then
    SSH_PASSWORD="root"
fi

echo "railway:$SSH_PASSWORD" | chpasswd
echo "root:$SSH_PASSWORD" | chpasswd

echo "SSH server is running..."
echo "User: root / Pass: $SSH_PASSWORD"
exec /usr/sbin/sshd -D
