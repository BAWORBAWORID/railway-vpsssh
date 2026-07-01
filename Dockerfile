FROM debian:13
ENV DEBIAN_FRONTEND=noninteractive

RUN apt update -y > /dev/null 2>&1 && apt upgrade -y > /dev/null 2>&1

RUN apt install openssh-server wget unzip -y > /dev/null 2>&1
#RUN wget -O ngrok.zip https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.zip > /dev/null 2>&1
#RUN unzip ngrok.zip
#RUN echo "./ngrok config add-authtoken 3FLS6W6nOkw0bMsNcTFzfRiD3oM_7zLjtXURAiUWTzD4QpZyX &&" >>/1.sh
#RUN echo "./ngrok tcp 22 &>/dev/null &" >>/1.sh
#RUN mkdir "/run/sshd"

RUN mkdir -p /var/run/sshd

RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#PermitEmptyPasswords no/PermitEmptyPasswords no/' /etc/ssh/sshd_config

COPY entrypoint.sh /script.sh
RUN chmod +x /script.sh

#RUN echo root:root|chpasswd
##RUN service ssh start
RUN chmod 755 /1.sh
EXPOSE 2280 8888 8080 443 5130 5131 5132 5133 5134 5135 3306

CMD ["/script.sh"]
