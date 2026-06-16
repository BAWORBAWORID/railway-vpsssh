 FROM debian:13

#ARG NGROK_TOKEN=2hpd7vLD4dsHkneSyXph7oQ74gf_4uBMWmAJw17Tk3Ytq71gw
ENV REGION=us
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
    openssh-server \
    curl \
    wget \
    unzip \
    python3 && \
    rm -rf /var/lib/apt/lists/*

RUN wget -q https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip -O /tmp/ngrok.zip && \
    unzip /tmp/ngrok.zip -d /usr/local/bin && \
    chmod +x /usr/local/bin/ngrok && \
    rm -f /tmp/ngrok.zip

RUN mkdir -p /run/sshd

RUN echo "root:root" | chpasswd

RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config || true && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config

RUN cat > /start.sh << 'EOF'
#!/bin/bash

echo "Starting Ngrok..."

ngrok tcp \
  --authtoken "2hpd7vLD4dsHkneSyXph7oQ74gf_4uBMWmAJw17Tk3Ytq71gw" \
  #--region "${REGION}" \
  22 > /dev/null 2>&1 &

sleep 8

echo ""
echo "=============================="

curl -s http://127.0.0.1:4040/api/tunnels | python3 -c '
import json,sys

try:
    data=json.load(sys.stdin)
    url=data["tunnels"][0]["public_url"]

    host=url.replace("tcp://","").split(":")[0]
    port=url.split(":")[-1]

    print("SSH INFORMATION")
    print("----------------")
    print(f"Host     : {host}")
    print(f"Port     : {port}")
    print("Username : root")
    print("Password : root")
    print("")
    print(f"ssh root@{host} -p {port}")

except Exception as e:
    print("Failed to get Ngrok tunnel")
'
echo "=============================="
echo ""

exec /usr/sbin/sshd -D
EOF

RUN chmod +x /start.sh

EXPOSE 80 443 3306 4040 5432 5700 5701 5010 6800 6900 8080 8888 9000


CMD ["/start.sh"]
