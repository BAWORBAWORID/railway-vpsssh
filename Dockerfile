FROM ubuntu:latest

RUN apt update -y > /dev/null 2>&1 && apt upgrade -y > /dev/null 2>&1
RUN apt install -y ssh wget curl > /dev/null 2>&1

# Download frpc
RUN wget -q https://github.com/fatedier/frp/releases/download/v0.61.0/frp_0.61.0_linux_amd64.tar.gz && \
    tar -xzf frp_0.61.0_linux_amd64.tar.gz && \
    mv frp_0.61.0_linux_amd64/frpc /usr/local/bin/frpc && \
    rm -rf frp_0.61.0_linux_amd64*

RUN mkdir -p /etc/frp

# SSH config
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo root:admin | chpasswd

# Start script - auto detect public IP
RUN cat <<'EOF' > /start
#!/bin/bash

# Auto get public IP
PUBLIC_IP=$(curl -s https://api.ipify.org || \
            curl -s https://ifconfig.me || \
            curl -s https://icanhazip.com)

echo "[*] Public IP: $PUBLIC_IP"

# Generate frpc.toml dynamically
cat > /etc/frp/frpc.toml <<FRPCONF
serverAddr = "$PUBLIC_IP"
serverPort = 7000

[[proxies]]
name = "ssh-docker"
type = "tcp"
localIP = "127.0.0.1"
localPort = 22
remotePort = 6022
FRPCONF

echo "[*] frpc.toml generated:"
cat /etc/frp/frpc.toml

echo "[*] Starting frpc..."
frpc -c /etc/frp/frpc.toml &

sleep 2

echo "[*] SSH Info:"
echo "    Host : $PUBLIC_IP"
echo "    Port : 6022"
echo "    User : root"
echo "    Pass : admin"

echo "[*] Starting sshd..."
/usr/sbin/sshd -D
EOF

RUN chmod +x /start

EXPOSE 22 80 443 8080 8888 3306 5130 5131 5132 5133 5134 5135

CMD ["/start"]
