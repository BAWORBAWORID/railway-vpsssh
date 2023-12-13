FROM debian:10.11
RUN apt-get update && apt-get install -y openssh-server
RUN useradd -rm -d /home/user -s /bin/bash -g root -G sudo -u 1000 user
RUN echo 'user:user' | chpasswd
EXPOSE 22
CMD /usr/sbin/sshd -D

