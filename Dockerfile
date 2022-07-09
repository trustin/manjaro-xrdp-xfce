FROM manjarolinux/base:latest

ARG MIRROR_URL

ENV LANG=en_US.UTF-8
ENV TZ=America/Los_Angeles
ENV PATH="/usr/bin:${PATH}"
ENV PUSER=user
ENV PUID=1000

# Remove unnecessary files from the base image.
RUN rm -f /.BUILDINFO /.INSTALL /.PKGINFO /.MTREE

# Configure the locale; enable only en_US.UTF-8 and the current locale.
RUN sed -i -e 's~^\([^#]\)~#\1~' '/etc/locale.gen' && \
  echo -e '\nen_US.UTF-8 UTF-8' >> '/etc/locale.gen' && \
  if [[ "${LANG}" != 'en_US.UTF-8' ]]; then \
    echo "${LANG}" >> '/etc/locale.gen'; \
  fi && \
  locale-gen && \
  echo -e "LANG=${LANG}\nLC_ADDRESS=${LANG}\nLC_IDENTIFICATION=${LANG}\nLC_MEASUREMENT=${LANG}\nLC_MONETARY=${LANG}\nLC_NAME=${LANG}\nLC_NUMERIC=${LANG}\nLC_PAPER=${LANG}\nLC_TELEPHONE=${LANG}\nLC_TIME=${LANG}" > '/etc/locale.conf'

# Configure the timezone.
RUN echo "${TZ}" > /etc/timezone && \
  ln -sf "/usr/share/zoneinfo/${TZ}" /etc/localtime

# Populate the mirror list.
RUN pacman-mirrors --country United_States --api --set-branch stable --protocol https && \
  if [[ -n "${MIRROR_URL}" ]]; then \
    mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak && \
    echo "Server = ${MIRROR_URL}/stable/\$repo/\$arch" > /etc/pacman.d/mirrorlist; \
  fi

# Install the keyrings.
RUN pacman-key --init && \
  pacman -Syy --noconfirm --needed archlinux-keyring manjaro-keyring && \
  pacman-key --populate archlinux manjaro

# Install the core packages.
RUN pacman -S --noconfirm --needed \
  diffutils \
  findutils \
  manjaro-release \
  manjaro-system \
  pacman \
  sudo && \
pacman -Scc --noconfirm

# Make sure everything is up-to-date.
RUN sed -i -e 's~^\(\(CheckSpace\|IgnorePkg\|IgnoreGroup\).*\)$~#\1~' /etc/pacman.conf && \
  pacman -Syyu --noconfirm --needed && \
  mv -f /etc/pacman.conf.pacnew /etc/pacman.conf && \
  sed -i -e 's~^\(CheckSpace.*\)$~#\1~' /etc/pacman.conf && \
  pacman -Scc --noconfirm

# Install the common non-GUI packages.
RUN pacman -Sy --noconfirm --needed \
  autoconf \
  automake \
  aws-cli \
  base-devel \
  bash-completion \
  bind \
  bison \
  bandwhich \
  bat \
  bpf \
  bpftrace \
  clang \
  cmake \
  dash \
  difftastic \
  dmidecode \
  docker \
  dog \
  downgrade \
  dust \
  exa \
  fakeroot \
  fasd \
  fd \
  flex \
  fzf \
  gdb \
  git \
  glances \
  hexyl \
  htop \
  httpie \
  iftop \
  inetutils \
  iproute2 \
  iputils \
  jdk11-openjdk \
  jq \
  logrotate \
  lrzip \
  lsof \
  man-db \
  manjaro-aur-support \
  manjaro-base-skel \
  manjaro-browser-settings \
  manjaro-hotfixes \
  manjaro-pipewire \
  manjaro-zsh-config \
  meson \
  mpdecimal \
  net-tools \
  nfs-utils \
  nodejs-lts-fermium \
  openbsd-netcat \
  openresolv \
  openssh \
  p7zip \
  pamac-cli \
  perf \
  pigz \
  pipewire-jack \
  pkgconf \
  procps-ng \
  protobuf \
  psmisc \
  python \
  python-cchardet \
  python-docker \
  python-matplotlib \
  python-netifaces \
  python-pip \
  python-setuptools \
  python2 \
  python2-setuptools \
  rclone \
  ripgrep \
  rsync \
  screen \
  sd \
  squashfs-tools \
  strace \
  sysstat \
  systemd-sysvcompat \
  tcpdump \
  thrift \
  tk \
  tmux \
  traceroute \
  trash-cli \
  tree \
  unace \
  unrar \
  unzip \
  vim \
  wireplumber \
  wget \
  xh \
  xz \
  zip && \
pacman -Scc --noconfirm

# Copy the pre-built packages.
COPY packages/ /packages/

# Install the pre-built packages.
RUN pacman -U --noconfirm --needed /packages/*/*.tar.* && \
  rm -fr /packages && \
  pacman -Scc --noconfirm

# Install ncurses5-compat-libs from AUR.
RUN \
  cd /tmp && \
  sudo -u builder gpg --recv-keys CC2AF4472167BE03 && \
  sudo -u builder git clone https://aur.archlinux.org/ncurses5-compat-libs.git && \
  cd ncurses5-compat-libs && \
  sudo -u builder makepkg --noconfirm && \
  pacman -U --noconfirm --needed /tmp/ncurses5-compat-libs/*.pkg.tar* && \
  rm -fr /tmp/ncurses5-compat-libs && \
  pacman -Scc --noconfirm

# Install python38 and python39 from AUR.
RUN \
  cd /tmp && \
  sudo -u builder gpg --recv-keys B26995E310250568 && \
  sudo -u builder git clone https://aur.archlinux.org/python38.git && \
  sudo -u builder git clone https://aur.archlinux.org/python39.git && \
  cd /tmp/python38 && sudo -u builder makepkg --noconfirm && \
  pacman -U --noconfirm --needed /tmp/python38/*.pkg.tar* && \
  cd /tmp/python39 && sudo -u builder makepkg --noconfirm && \
  pacman -U --noconfirm --needed /tmp/python39/*.pkg.tar* && \
  rm -fr /tmp/python38 /tmp/python39 && \
  pacman -Scc --noconfirm

# Install scmpuff from AUR.
RUN \
  cd /tmp && \
  sudo -u builder git clone https://aur.archlinux.org/scmpuff.git && \
  cd /tmp/scmpuff && sudo -u builder makepkg --noconfirm && \
  pacman -U --noconfirm --needed /tmp/scmpuff/*.pkg.tar* && \
  rm -fr /tmp/scmpuff && \
  pacman -Scc --noconfirm

# Install azure-cli-bin from AUR.
RUN \
  cd /tmp && \
  sudo -u builder git clone https://aur.archlinux.org/azure-cli-bin.git && \
  cd /tmp/azure-cli-bin && sudo -u builder makepkg --noconfirm && \
  pacman -U --noconfirm --needed /tmp/azure-cli-bin/*.pkg.tar* && \
  rm -fr /tmp/azure-cli-bin && \
  pacman -Scc --noconfirm

# Install gimme-aws-creds from AUR.
# TODO: Uncomment once python-ctap-keyring-device is fixed.
#RUN pacman -S --noconfirm --needed \
#  python-beautifulsoup4 python-boto3 python-fido2 python-keyring python-pytest \
#  python-pytest-black python-pytest-cov python-pytest-flake8 python-setuptools-scm && \
#  cd /tmp && \
#  sudo -u nobody git clone https://aur.archlinux.org/python-ctap-keyring-device.git && \
#  sudo -u nobody git clone https://aur.archlinux.org/python-okta-legacy.git && \
#  sudo -u nobody git clone https://aur.archlinux.org/gimme-aws-creds.git && \
#  cd /tmp/python-ctap-keyring-device && \
#  sudo -u nobody makepkg --noconfirm && \
#  pacman -U --noconfirm --needed /tmp/python-ctap-keyring-device/*.pkg.tar* && \
#  cd /tmp/python-okta-legacy && \
#  sudo -u nobody makepkg --noconfirm && \
#  pacman -U --noconfirm --needed /tmp/python-okta-legacy/*.pkg.tar* && \
#  cd /tmp/gimme-aws-creds && \
#  sudo -u nobody makepkg --noconfirm && \
#  pacman -U --noconfirm --needed /tmp/gimme-aws-creds/*.pkg.tar* && \
#  rm -fr /tmp/python-ctap-keyring-device /tmp/python-okta-legacy /tmp/gimme-aws-creds && \
#  pacman -Scc --noconfirm

# Install the fonts.
RUN pacman -S --noconfirm --needed \
  noto-fonts \
  noto-fonts-cjk \
  noto-fonts-emoji \
  ttf-fira-code \
  ttf-fira-mono \
  ttf-fira-sans \
  ttf-hack \
  ttf-liberation && \
pacman -Scc --noconfirm

# Install the common GUI packages.
RUN pacman -S --noconfirm --needed \
  dconf-editor \
  evince \
  firefox \
  gnome-keyring \
  gnome-settings-daemon \
  gvfs-google \
  libappindicator-gtk2 \
  libappindicator-gtk3 \
  manjaro-application-utility \
  pamac-gtk \
  poppler-data \
  qgnomeplatform-qt5 \
  qgnomeplatform-qt6 \
  seahorse \
  wireshark-qt \
  wmctrl \
  xapp \
  xdg-desktop-portal \
  xdg-desktop-portal-gtk \
  xdg-user-dirs \
  xdg-user-dirs-gtk \
  xdg-utils \
  xdotool \
  xorg \
  xorg-twm \
  xterm \
  zenity && \
pacman -Scc --noconfirm

# Install the common themes.
RUN pacman -S --noconfirm --needed \
  gnome-backgrounds \
  gnome-themes-extra \
  gnome-wallpapers \
  gtk-engines \
  gtk-engine-murrine \
  matcha-gtk-theme \
  kvantum-manjaro \
  kvantum-theme-matcha \
  papirus-maia-icon-theme \
  xcursor-breeze && \
pacman -Scc --noconfirm

# Install input methods.
RUN pacman -S --noconfirm --needed \
  fcitx5-chinese-addons \
  fcitx5-hangul \
  fcitx5-m17n \
  fcitx5-mozc \
  fcitx5-rime \
  fcitx5-unikey \
  manjaro-asian-input-support-fcitx5 && \
pacman -Scc --noconfirm

# Install xrdp and xorgxrdp from AUR.
# - Remove the generated XRDP RSA key because it will be generated at the first boot.
# - Unlock gnome-keyring automatically for xrdp login.
RUN \
  pacman -S --noconfirm --needed \
    check imlib2 tigervnc libxrandr fuse libfdk-aac ffmpeg nasm xorg-server-devel && \
  cd /tmp && \
  sudo -u builder gpg --recv-keys 61ECEABBF2BB40E3A35DF30A9F72CDBC01BF10EB && \
  sudo -u builder git clone https://aur.archlinux.org/xrdp.git && \
  sudo -u builder git clone https://aur.archlinux.org/xorgxrdp.git && \
  cd /tmp/xrdp && sudo -u builder makepkg --noconfirm && \
  pacman -U --noconfirm --needed /tmp/xrdp/*.pkg.tar* && \
  cd /tmp/xorgxrdp && sudo -u builder makepkg --noconfirm && \
  pacman -U --noconfirm --needed /tmp/xorgxrdp/*.pkg.tar* && \
  rm -fr /tmp/xrdp /tmp/xorgxrdp /etc/xrdp/rsakeys.ini && \
  pacman -Scc --noconfirm && \
  systemctl enable xrdp.service

# Install the workaround for:
# - https://github.com/neutrinolabs/xrdp/issues/1684
# - GNOME Keyring asks for password at login.
RUN \
  cd /tmp && \
  wget 'https://github.com/matt335672/pam_close_systemd_system_dbus/archive/f8e6a9ac7bdbae7a78f09845da4e634b26082a73.zip' && \
  unzip f8e6a9ac7bdbae7a78f09845da4e634b26082a73.zip && \
  cd /tmp/pam_close_systemd_system_dbus-f8e6a9ac7bdbae7a78f09845da4e634b26082a73 && \
  make install && \
  rm -fr /tmp/pam_close_systemd_system_dbus-f8e6a9ac7bdbae7a78f09845da4e634b26082a73

# Install Visual Studio Code from AUR.
RUN cd /tmp && \
  sudo -u nobody git clone https://aur.archlinux.org/visual-studio-code-bin.git && \
  cd visual-studio-code-bin && \
  sudo -u nobody makepkg --noconfirm && \
  pacman -U --noconfirm --needed /tmp/visual-studio-code-bin/*.pkg.tar* && \
  rm -fr /tmp/visual-studio-code-bin && \
  pacman -Scc --noconfirm

# Install Google Chrome from AUR.
RUN cd /tmp && \
  sudo -u nobody git clone https://aur.archlinux.org/google-chrome.git && \
  cd google-chrome && \
  sudo -u nobody makepkg --noconfirm && \
  pacman -U --noconfirm --needed /tmp/google-chrome/*.pkg.tar* && \
  rm -fr /tmp/google-chrome && \
  pacman -Scc --noconfirm

# Configure Pamac.
RUN sed -i -e \
  's~#\(\(RemoveUnrequiredDeps\|SimpleInstall\|EnableAUR\|KeepBuiltPkgs\|CheckAURUpdates\|DownloadUpdates\).*\)~\1~g' \
  /etc/pamac.conf

# Install the desktop environment packages.
RUN pacman -S --noconfirm --needed \
  baobab \
  gnome-system-monitor \
  mousepad \
  manjaro-xfce-settings \
  ristretto \
  speedcrunch \
  terminator \
  thunar-archive-plugin \
  xarchiver \
  xfce4 \
  xfce4-clipman-plugin \
  xfce4-cpufreq-plugin \
  xfce4-cpugraph-plugin \
  xfce4-datetime-plugin \
  xfce4-diskperf-plugin \
  xfce4-fsguard-plugin \
  xfce4-genmon-plugin \
  xfce4-mailwatch-plugin \
  xfce4-mount-plugin \
  xfce4-netload-plugin \
  xfce4-notes-plugin \
  xfce4-notifyd \
  xfce4-smartbookmark-plugin \
  xfce4-systemload-plugin \
  xfce4-time-out-plugin \
  xfce4-timer-plugin \
  xfce4-verve-plugin \
  xfce4-weather-plugin \
  xfce4-whiskermenu-plugin && \
pacman -Runc --noconfirm \
  xfce4-power-manager && \
pacman -Scc --noconfirm

# Remove the cruft.
RUN rm -f /etc/locale.conf.pacnew /etc/locale.gen.pacnew

# Enable/disable the services.
RUN \
  systemctl enable \
    sshd.service && \
  systemctl mask \
    bluetooth.service \
    dev-sda1.device \
    dm-event.service \
    dm-event.socket \
    geoclue.service \
    initrd-udevadm-cleanup-db.service \
    lvm2-lvmpolld.socket \
    lvm2-monitor.service \
    power-profiles-daemon.service \
    systemd-boot-update.service \
    systemd-firstboot.service \
    systemd-modules-load.service \
    systemd-network-generator.service \
    systemd-networkd.service \
    systemd-networkd.socket \
    systemd-networkd-wait-online.service \
    systemd-remount-fs.service \
    systemd-udev-settle.service \
    systemd-udev-trigger.service \
    systemd-udevd.service \
    systemd-udevd-control.socket \
    systemd-udevd-kernel.socket \
    udisks2.service \
    upower.service \
    usb-gadget.target \
    usbmuxd.service && \
  systemctl mask --global \
    gvfs-mtp-volume-monitor.service \
    gvfs-udisks2-volume-monitor.service \
    obex.service \
    pipewire.service \
    pipewire.socket \
    pipewire-media-session.service \
    pipewire-pulse.service \
    pipewire-pulse.socket \
    wireplumber.service

# Copy the configuration files and scripts.
COPY files/ /

# Enable the first boot time script.
RUN systemctl enable first-boot.service

# Workaround for the colord authentication issue.
# See: https://unix.stackexchange.com/a/581353
RUN systemctl enable fix-colord.service

# Delete the 'builder' user from the base image.
RUN userdel --force --remove builder

# Switch to the default mirrors since we finished downloading packages.
RUN \
  if [[ -n "${MIRROR_URL}" ]]; then \
    mv /etc/pacman.d/mirrorlist.bak /etc/pacman.d/mirrorlist; \
  fi

# Customize XFCE.
RUN \
  sed -i -e 's~\("use_compositing".*\)"true"~\1"false"~' /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml && \
  sed -i -e 's~\/usr/share/backgrounds/xfce/illyria-default.jpg~/usr/share/backgrounds/manjaro-gnome/M2020G2.jpg~' /etc/skel/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-desktop.xml

# Expose SSH and RDP ports.
EXPOSE 22
EXPOSE 3389

STOPSIGNAL SIGRTMIN+3
CMD ["/sbin/init"]
