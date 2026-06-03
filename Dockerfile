FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Base system + Desktop + SSH
RUN apt update -y && apt upgrade -y && \
    apt install --no-install-recommends -y \
    xfce4 xfce4-goodies \
    tigervnc-standalone-server novnc websockify \
    openssh-server sudo curl wget git vim \
    net-tools iproute2 unzip tzdata ca-certificates \
    dbus-x11 x11-utils x11-xserver-utils \
    fonts-noto fonts-noto-color-emoji \
    gtk2-engines-murrine gtk2-engines-pixbuf \
    gnome-themes-extra papirus-icon-theme \
    software-properties-common && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Firefox
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    printf 'Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' \
    > /etc/apt/preferences.d/mozilla-firefox && \
    apt update -y && apt install -y firefox xubuntu-icon-theme && \
    apt clean && rm -rf /var/lib/apt/lists/*

# Windows 10 GTK Theme
RUN curl -L "https://github.com/B00merang-Project/Windows-10/archive/refs/heads/master.zip" \
    -o /tmp/win10-theme.zip && \
    unzip /tmp/win10-theme.zip -d /tmp/ && \
    mv /tmp/Windows-10-master /usr/share/themes/Windows-10 && \
    rm /tmp/win10-theme.zip

# Windows 10 Icon Theme
RUN curl -L "https://github.com/B00merang-Artwork/Windows-10/archive/refs/heads/master.zip" \
    -o /tmp/win10-icons.zip && \
    unzip /tmp/win10-icons.zip -d /tmp/ && \
    mv /tmp/Windows-10-master /usr/share/icons/Windows-10 && \
    rm /tmp/win10-icons.zip

# XFCE config dirs
RUN mkdir -p /root/.config/xfce4/xfconf/xfce-perchannel-xml

# Apply Windows 10 theme
RUN cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Windows-10"/>
    <property name="IconThemeName" type="string" value="Windows-10"/>
  </property>
  <property name="Xft" type="empty">
    <property name="Antialias" type="int" value="1"/>
    <property name="Hinting" type="int" value="1"/>
    <property name="HintStyle" type="string" value="hintslight"/>
    <property name="RGBA" type="string" value="rgb"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Segoe UI 9"/>
    <property name="MonospaceFontName" type="string" value="Consolas 10"/>
  </property>
</channel>
EOF

# Taskbar bawah ala Windows 10
RUN cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
  </property>
  <property name="panel-1" type="empty">
    <property name="position" type="string" value="p=8;x=0;y=0"/>
    <property name="length" type="uint" value="100"/>
    <property name="position-locked" type="bool" value="true"/>
    <property name="size" type="uint" value="40"/>
    <property name="plugin-ids" type="array">
      <value type="int" value="1"/>
      <value type="int" value="2"/>
      <value type="int" value="3"/>
      <value type="int" value="4"/>
      <value type="int" value="5"/>
    </property>
    <property name="background-style" type="uint" value="1"/>
    <property name="background-rgba" type="array">
      <value type="double" value="0.121"/>
      <value type="double" value="0.133"/>
      <value type="double" value="0.160"/>
      <value type="double" value="0.95"/>
    </property>
  </property>
  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="applicationsmenu">
      <property name="button-title" type="string" value=""/>
      <property name="show-button-title" type="bool" value="false"/>
    </property>
    <property name="plugin-2" type="string" value="tasklist">
      <property name="flat-buttons" type="bool" value="true"/>
      <property name="show-labels" type="bool" value="true"/>
    </property>
    <property name="plugin-3" type="string" value="separator">
      <property name="expand" type="bool" value="true"/>
      <property name="style" type="uint" value="0"/>
    </property>
    <property name="plugin-4" type="string" value="systray"/>
    <property name="plugin-5" type="string" value="clock">
      <property name="digital-format" type="string" value="%H:%M&#10;%d/%m/%Y"/>
    </property>
  </property>
</channel>
EOF

# Desktop background biru Windows 10
RUN cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-desktop" version="1.0">
  <property name="backdrop" type="empty">
    <property name="screen0" type="empty">
      <property name="monitorVNC-0" type="empty">
        <property name="workspace0" type="empty">
          <property name="color-style" type="int" value="0"/>
          <property name="rgba1" type="array">
            <value type="double" value="0.0"/>
            <value type="double" value="0.47"/>
            <value type="double" value="0.84"/>
            <value type="double" value="1.0"/>
          </property>
          <property name="image-style" type="int" value="0"/>
        </property>
      </property>
    </property>
  </property>
</channel>
EOF

# Window manager tema Windows 10
RUN cat > /root/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="theme" type="string" value="Windows-10"/>
    <property name="title-font" type="string" value="Segoe UI Bold 9"/>
    <property name="button-layout" type="string" value="O|HMC"/>
  </property>
</channel>
EOF

# FRP install
RUN wget -q https://github.com/fatedier/frp/releases/download/v0.61.0/frp_0.61.0_linux_amd64.tar.gz && \
    tar -xzf frp_0.61.0_linux_amd64.tar.gz && \
    mv frp_0.61.0_linux_amd64/frpc /usr/local/bin/frpc && \
    mv frp_0.61.0_linux_amd64/frps /usr/local/bin/frps && \
    rm -rf frp_0.61.0_linux_amd64*

# SSH config
RUN mkdir -p /run/sshd && \
    echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    echo root:Codex | chpasswd

RUN touch /root/.Xauthority

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 22 5901 6080 7000 6022

CMD ["/start.sh"]
