FROM debian:12

LABEL maintainer="alwayscodex"

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Jakarta

RUN apt update -y && apt upgrade -y && apt install locales -y \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

RUN apt install ssh curl sudo wget -y

# Setup password root
RUN echo "root:codex" | chpasswd

# Setup SSH config
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config 
RUN echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config
RUN echo 'Port 22' >> /etc/ssh/sshd_config
RUN echo 'ClientAliveInterval 60' >> /etc/ssh/sshd_config
RUN echo 'ClientAliveCountMax 3' >> /etc/ssh/sshd_config

# Install cloudflared
RUN mkdir -p --mode=0755 /usr/share/keyrings
RUN curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | tee /usr/share/keyrings/cloudflare-public-v2.gpg >/dev/null
RUN echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' | tee /etc/apt/sources.list.d/cloudflared.list
RUN apt update -y && apt install -y cloudflared

# Buat script untuk SSH via cloudflared
RUN echo '#!/bin/bash' > /start
RUN echo 'mkdir -p /run/sshd' >> /start
RUN echo '' >> /start
RUN echo '# Start SSH daemon' >> /start
RUN echo '/usr/sbin/sshd' >> /start
RUN echo '' >> /start
RUN echo 'sleep 3' >> /start
RUN echo '' >> /start
RUN echo '# Run cloudflare tunnel with SSH support' >> /start
RUN echo 'echo "Starting Cloudflare Tunnel..."' >> /start
RUN echo 'cloudflared tunnel --no-autoupdate run --token eyJhIjoiZWE1NjQ5MjNiMWJhYmZlODk1NmY1Y2UxOTNjNjRjYTkiLCJ0IjoiMDA3MGRmZGMtZjU3ZS00MTRiLTlmMjUtN2E2NjhiMWEwNGM4IiwicyI6IlpqVXlNekV3T0RRdFkyRmtOUzAwWkRCa0xUbGlOR0V0TVdSaU1HVmtNbUUwTXpKaSJ9 &' >> /start
RUN echo '' >> /start
RUN echo '# Keep container alive' >> /start
RUN echo 'tail -f /dev/null' >> /start

RUN chmod 755 /start

EXPOSE 22

CMD ["/start"]
