FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt update -y && apt upgrade -y && \
    apt install -y ssh wget curl sudo && \
    apt clean

# Download & install frpc
RUN wget -q https://github.com/fatedier/frp/releases/download/v0.61.0/frp_0.61.0_linux_amd64.tar.gz && \
    tar -xzf frp_0.61.0_linux_amd64.tar.gz && \
    mv frp_0.61.0_linux_amd64/frpc /usr/local/bin/frpc && \
    rm -rf frp_0.61.0_linux_amd64*

# SSH config
RUN mkdir -p /run/sshd && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo 'Port 22' >> /etc/ssh/sshd_config && \
    echo root:admin | chpasswd

# Buat start script
RUN cat <<'EOF' > /start.sh
#!/bin/bash

FRP_SERVER="${FRP_SERVER:-IP_VPS_KAMU}"
FRP_PORT="${FRP_PORT:-7000}"
REMOTE_PORT="${REMOTE_PORT:-6022}"

echo "[*] FRP Server : $FRP_SERVER"
echo "[*] Remote Port: $REMOTE_PORT"

# Generate frpc config
mkdir -p /etc/frp
cat > /etc/frp/frpc.toml <<CONF
serverAddr = "$FRP_SERVER"
serverPort = $FRP_PORT

[[proxies]]
name = "ssh"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = $REMOTE_PORT
CONF

# Start SSH daemon
echo "[*] Starting SSH..."
/usr/sbin/sshd

# Start frpc
echo "[*] Starting frpc..."
frpc -c /etc/frp/frpc.toml &

echo ""
echo "================================"
echo " SSH Login Info"
echo " Host : $FRP_SERVER"
echo " Port : $REMOTE_PORT"
echo " User : root"
echo " Pass : admin"
echo "================================"

# Keep container alive
tail -f /dev/null
EOF

RUN chmod +x /start.sh

EXPOSE 22

CMD ["/start.sh"]
