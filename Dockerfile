FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt update -y && apt upgrade -y && \
    apt install -y ssh wget curl sudo iproute2 && \
    apt clean

# Download & install frp (frpc + frps)
RUN wget -q https://github.com/fatedier/frp/releases/download/v0.61.0/frp_0.61.0_linux_amd64.tar.gz && \
    tar -xzf frp_0.61.0_linux_amd64.tar.gz && \
    mv frp_0.61.0_linux_amd64/frpc /usr/local/bin/frpc && \
    mv frp_0.61.0_linux_amd64/frps /usr/local/bin/frps && \
    rm -rf frp_0.61.0_linux_amd64*

# SSH config
RUN mkdir -p /run/sshd && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'Port 22' >> /etc/ssh/sshd_config && \
    echo root:admin | chpasswd

# Start script
RUN cat <<'EOF' > /start.sh
#!/bin/bash

# Auto detect public IP
echo "[*] Detecting public IP..."
PUBLIC_IP=""
for url in \
    "https://api.ipify.org" \
    "https://ifconfig.me" \
    "https://icanhazip.com" \
    "https://checkip.amazonaws.com" \
    "https://ipecho.net/plain"; do
    PUBLIC_IP=$(curl -s --max-time 5 "$url" 2>/dev/null | tr -d '[:space:]')
    if [[ $PUBLIC_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "[*] Public IP: $PUBLIC_IP"
        break
    fi
done

# Fallback ke gateway
if [[ -z "$PUBLIC_IP" ]]; then
    PUBLIC_IP=$(ip route | awk '/default/ {print $3}' | head -1)
    echo "[!] Fallback IP: $PUBLIC_IP"
fi

FRP_PORT="${FRP_PORT:-7000}"
REMOTE_PORT="${REMOTE_PORT:-6022}"

mkdir -p /etc/frp

# Generate frps config
cat > /etc/frp/frps.toml <<CONF
bindPort = $FRP_PORT
CONF

# Generate frpc config
cat > /etc/frp/frpc.toml <<CONF
serverAddr = "127.0.0.1"
serverPort = $FRP_PORT

[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = $REMOTE_PORT
CONF

# Start frps dulu
echo "[*] Starting frps..."
frps -c /etc/frp/frps.toml &
sleep 2

# Start SSH
echo "[*] Starting SSH..."
/usr/sbin/sshd

# Start frpc
echo "[*] Starting frpc..."
frpc -c /etc/frp/frpc.toml &

echo ""
echo "================================"
echo " SSH Login Info"
echo " Host : $PUBLIC_IP"
echo " Port : $REMOTE_PORT"
echo " User : root"
echo " Pass : admin"
echo "================================"

tail -f /dev/null
EOF

RUN chmod +x /start.sh

EXPOSE 22 7000 6022

CMD ["/start.sh"]
