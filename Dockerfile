FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install semua packages
RUN apt update -y && apt upgrade -y && \
    apt install -y \
    openssh-server \
    curl wget git vim nano \
    net-tools iproute2 iputils-ping \
    sudo ca-certificates tzdata openssl \
    nginx \
    mysql-server && \
    apt clean && rm -rf /var/lib/apt/lists/*

# SSH config - port 22 & 2022
RUN mkdir -p /run/sshd && \
    echo "Port 22" >> /etc/ssh/sshd_config && \
    echo "Port 2022" >> /etc/ssh/sshd_config && \
    sed -i 's/#PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    echo root:Codex | chpasswd

# SSL self-signed untuk port 443
RUN openssl req -x509 -nodes -days 365 \
    -newkey rsa:2048 \
    -keyout /etc/ssl/self.key \
    -out /etc/ssl/self.crt \
    -subj "/C=ID/ST=Jakarta/L=Jakarta/O=Dev/CN=localhost"

# Nginx config port 8080 & 443
RUN cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 8080 default_server;
    server_name _;
    root /var/www/html;
    index index.html;
    location / {
        try_files $uri $uri/ =404;
    }
}
server {
    listen 443 ssl default_server;
    server_name _;
    ssl_certificate     /etc/ssl/self.crt;
    ssl_certificate_key /etc/ssl/self.key;
    root /var/www/html;
    index index.html;
    location / {
        try_files $uri $uri/ =404;
    }
}
EOF

# MySQL remote access
RUN sed -i 's/bind-address.*/bind-address = 0.0.0.0/' \
    /etc/mysql/mysql.conf.d/mysqld.cnf

# Start script inline
RUN cat > /start.sh << 'EOF'
#!/bin/bash

echo "[*] Starting SSH..."
service ssh start

echo "[*] Starting MySQL..."
service mysql start
sleep 2
mysql -u root << 'SQL'
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'Codex';
CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'Codex';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL

echo "[*] Starting Nginx..."
service nginx start

echo ""
echo "======================================="
echo "  Ubuntu 22 CLI VPS - READY"
echo "======================================="
echo "  [SSH]"
echo "  Port 22   : ssh root@<IP>"
echo "  Port 2022 : ssh root@<IP> -p 2022"
echo "  Password  : Codex"
echo ""
echo "  [Web / Nginx]"
echo "  HTTP  : http://<IP>:8080"
echo "  HTTPS : https://<IP>:443"
echo ""
echo "  [MySQL]"
echo "  Host  : <IP>:3306"
echo "  User  : root"
echo "  Pass  : Codex"
echo "======================================="

tail -f /dev/null
EOF

RUN chmod +x /start.sh

EXPOSE 22 2022 8080 443 3306

CMD ["/bin/bash", "/start.sh"]
