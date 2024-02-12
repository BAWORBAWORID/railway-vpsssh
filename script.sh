#!/bin/bash

# Mengatur variabel lingkungan


# Menginstal paket yang diperlukan
apt update && apt upgrade -y && apt install -y \
    ssh wget unzip vim curl python3

# Mengunduh dan menyiapkan ngrok
wget -q https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -O /ngrok-stable-linux-amd64.zip \
    && cd / && unzip ngrok-stable-linux-amd64.zip \
    && chmod +x ngrok

# Mengatur konfigurasi SSH dan ngrok
mkdir /run/sshd
echo "/ngrok tcp --authtoken 2c0C6nS4nKZDFeY6k3vnbWELIEc_7pV42vmS3DQA8fGrU9yyd --region ap 22 &" >> /openssh.sh
echo "sleep 5" >> /openssh.sh
echo "curl -s http://localhost:4040/api/tunnels | python3 -c \"import sys, json; print(\\\"ssh info:\\\n\\\",\\\"ssh\\\",\\\"root@\\\"+json.load(sys.stdin)['tunnels'][0]['public_url'][6:].replace(':', ' -p '),\\\"\\\nROOT Password:craxid\\\")\" || echo \"\nError：NGROK_TOKEN，Ngrok Token\n\"" >> /openssh.sh
echo '/usr/sbin/sshd -D' >> /openssh.sh
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
echo root:craxid | chpasswd
chmod 755 /openssh.sh

# Mengekspos port yang dibutuhkan
EXPOSE 80 443 3306 4040 5432 5700 5701 5010 6800 6900 8080 8888 9000

# Menjalankan skrip bash
/openssh.sh
