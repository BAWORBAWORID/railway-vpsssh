FROM debian:10.11
RUN apt-get update && apt-get install -y openssh-server wget unzip

RUN wget -q https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -O /ngrok-stable-linux-amd64.zip \
    && unzip /ngrok-stable-linux-amd64.zip -d / \
    && chmod +x /ngrok
COPY * ./
RUN useradd -rm -d /home/user -s /bin/bash -g root -G sudo -u 1000 user
RUN echo 'PermitRootLogin yes' >>  /etc/ssh/sshd_config
RUN echo 'user:user' | chpasswd
RUN /ngrok tcp --authtoken 2ZGmzuQl8aUVhWE5r1PJZpmNuFR_2bF88nBdkLD65FvXHZwYF --region ap 22 &
EXPOSE 22
CMD /usr/sbin/sshd -D

