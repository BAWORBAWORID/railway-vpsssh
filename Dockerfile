FROM debian:10.11
RUN apt-get update && apt-get install -y openssh-server wget unzip

RUN wget -q https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip -O /ngrok-stable-linux-amd64.zip \
    && unzip /ngrok-stable-linux-amd64.zip -d / \
    && chmod +x /ngrok
COPY * ./
RUN useradd -rm -d /home/user -s /bin/bash -g root -G sudo -u 1000 user
RUN echo 'user:user' | chpasswd
RUN ./ngrok start --all --config=ngrok.yml
EXPOSE 22
CMD /usr/sbin/sshd -D

