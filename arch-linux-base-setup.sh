#!/usr/bin/env bash
# Before hop in
sudo pacman -Syy &&
    sudo pacman -S --needed --noconfirm base-devel pacman-contrib systemd git go &&
    sudo pacman -S --needed --noconfirm yay

# ------------------------------------------------------------------------

# Setting up locales
echo -e "LANG=en_GB.UTF8" | sudo tee -a /etc/locale.conf
echo -e "LANG=en_GB.UTF8" | sudo tee -a /etc/environment
echo -e "LC_ALL=en_GB.UTF8" | sudo tee -a /etc/environment
sudo sed -i 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen en_GB.UTF-8
localectl set-locale LANG=en_GB.UTF-8 LC_TIME=en_GB.UTF-8

# ------------------------------------------------------------------------

# Ranking mirrors
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -e "Setting up mirrors for optimal download ..."
cat /etc/pacman.d/mirrorlist | rankmirrors -n 5 -m 3 - >$HOME/mirrorlist
sudo mv $HOME/mirrorlist /etc/pacman.d/mirrorlist

# ------------------------------------------------------------------------

# Install yay if its still not
which yay >/dev/null 2>&1
if [ $? != 0 ]; then
    cd /tmp
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd
fi

# ------------------------------------------------------------------------

# Colorful progress bar
echo -e "Make pacman and yay colorful and adds eye candy on the progress bar"
grep -q "^Color" /etc/pacman.conf || sudo sed -i "s/^#Color$/Color/" /etc/pacman.conf
grep -q "ILoveCandy" /etc/pacman.conf || sudo sed -i "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf

# ------------------------------------------------------------------------

# All cores for compilation
echo -e "Use all cores for compilation"
sudo sed -i "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf

# ------------------------------------------------------------------------

# This may take time
echo -e "Installing Base System"

PKGS=(

    # --- Importants

    'xscreensaver'        # A screen saver and locker for the X
    'xfce4-goodies'       # Enhancements for the Xfce4
    'xfce4-power-manager' # Power Manager
    'dmenu'               # Generic menu for X
    'gmrun'               # A lightweight application launcher
    'gsimplecal'          # A simple, lightweight calendar
    'ibus'                # An input method framework
    'compton'             # A compositor for X11
    'conky'               # A system monitor software for the X Window System
    'nitrogen'            # A fast and lightweight desktop background browser and setter for X Window
    'openbox'             # A lightweight, powerful, and highly configurable stacking window manager
    'udiskie'             # An udisks2 front-end written in python
    'tint2'               # A simple, unobtrusive and light panel for Xorg
    'lxappearance'        # Set System Themes
    'lxsession'           # LXDE PolicyKit authentication agent
    'xfce4-notifyd'       # Notification Daemon

    # DEVELOPMENT ---------------------------------------------------------

    'ccache'      # Compiler cacher
    'cmake'       # Cross-platform open-source make system
    'gcc'         # C/C++ compiler
    'glibc'       # C libraries
    'glslang'     # OpenGL and OpenGL ES shader front end and validator
    'meson'       # Build system that use python as a front-end language and Ninja as a building backend
    'nodejs'      # Javascript runtime environment
    'npm'         # Node package manager
    'php'         # Scripting language
    'python3-pip' # The official package installer for Python

    # --- Audio

    'alsa-utils'      # Advanced Linux Sound Architecture (ALSA) Components https://alsa.opensrc.org/
    'alsa-plugins'    # ALSA plugins
    'pulseaudio-alsa' # ALSA configuration for pulse audio
    'pavucontrol-qt'  # Pulse Audio volume control Qt port
    'pasystray'       # PulseAudio system tray

    # --- Bluetooth

    'bluez'                # Daemons for the bluetooth protocol stack
    'bluez-firmware'       # Firmwares for Broadcom BCM203x and STLC2300 Bluetooth chips
    'blueman'              # GTK+ Bluetooth Manager
    'pulseaudio-bluetooth' # Bluetooth support for PulseAudio

    # TERMINAL UTILITIES --------------------------------------------------

    'cronie'        # Cron jobs
    'dash'          # A POSIX-compliant shell derived from ash
    'dashbinsh'     # Relink /bin/sh to dash
    'fish'          # The friendly interactive shell
    'vsftpd'        # File transfer protocol
    'htop'          # Process viewer
    'neofetch'      # Shows system info when you launch terminal
    'openssh'       # SSH connectivity tools
    'irssi'         # Terminal based IRC
    'p7zip'         # 7z compression program
    'speedtest-cli' # Internet speed via terminal
    'terminator'    # A terminal emulator
    'terminus-font' # Font package with some bigger fonts for login terminal
    'unrar'         # RAR compression program
    'unzip'         # Zip compression program
    'wget'          # Remote content retrieval
    'nano'          # A simple console based text editor
    'zenity'        # Display graphical dialog boxes via shell scripts
    'zip'           # Zip compression program

    # DISK UTILITIES ------------------------------------------------------

    'gparted' # Disk utility

    # GENERAL UTILITIES ---------------------------------------------------

    'catfish'              # Versatile file searching tool
    'dialog'               # A tool to display dialog boxes from shell scripts
    'earlyoom'             # Early OOM Daemon for Linux
    'flameshot'            # Screenshots
    'file-roller'          # Create and modify archives
    'filezilla'            # FTP Client
    'apache2'              # HTTP server
    'arandr'               # Provide a simple visual front end for XRandR
    'playerctl'            # Utility to control media players via MPRIS
    'putty'                # A port of the popular GUI SSH, Telnet, Rlogin and serial port connection client
    'transmission-qt'      # BitTorrent client
    'net-tools'            # Network utilities
    'galculator'           # A simple, elegant calculator
    'gnupg'                # Complete and free implementation of the OpenPGP standard
    'preload'              # Makes applications run faster by prefetching binaries and shared objects
    'simplescreenrecorder' # A feature-rich screen recorder that supports X11 and OpenGL

    # GRAPHICS, VIDEO AND DESIGN -------------------------------------------------

    'pinta'    # A simplified alternative to GIMP
    'viewnior' # A simple, fast and elegant image viewer
    'vlc'      # A free and open source cross-platform multimedia player and framework

    # PRINTING --------------------------------------------------------

    'abiword'     # Fully-featured word processor
    'atril'       # PDF viewer
    'ghostscript' # PostScript interpreter
    'gsfonts'     # Adobe Postscript replacement fonts
    'gnumeric'    # A powerful spreadsheet application

)

for PKG in "${PKGS[@]}"; do
    echo -e "INSTALLING: ${PKG}"
    yay -S --noconfirm --needed "$PKG"
done

echo -e "Done!"

# ------------------------------------------------------------------------

echo -e "FINAL SETUP AND CONFIGURATION"

# Sudo rights
echo -e "Add sudo rights"
sudo sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
echo -e "Remove no password sudo rights"
sudo sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

# ------------------------------------------------------------------------

echo -e "Configuring vconsole.conf to set a larger font for login shell"
echo -e "FONT=ter-v32b" | sudo tee /etc/vconsole.conf

# ------------------------------------------------------------------------

echo -e "Setting laptop lid close to suspend"
sudo sed -i -e 's|#HandleLidSwitch=suspend|HandleLidSwitch=suspend|g' /etc/systemd/logind.conf

# ------------------------------------------------------------------------

echo "Disabling buggy cursor inheritance"
# When you boot with multiple monitors the cursor can look huge. This fixes this...
echo -e "[Icon Theme]
#Inherits=Theme
" | sudo tee /usr/share/icons/default/index.theme

# ------------------------------------------------------------------------

echo -e "Increasing file watcher count"
# This prevents a "too many files" error in Visual Studio Code
echo -e "fs.inotify.max_user_watches=524288" | sudo tee /etc/sysctl.d/40-max-user-watches.conf &&
    sudo sysctl --system

# ------------------------------------------------------------------------

echo -e "Disabling Pulse .esd_auth module"
sudo killall -9 pulseaudio
# Pulse audio loads the `esound-protocol` module, which best I can tell is rarely needed.
# That module creates a file called `.esd_auth` in the home directory which I'd prefer to not be there. So...
sudo sed -i 's|load-module module-esound-protocol-unix|#load-module module-esound-protocol-unix|g' /etc/pulse/default.pa
# Restart PulseAudio.
sudo killall -HUP pulseaudio

# ------------------------------------------------------------------------

echo -e "Disabling bluetooth daemon by comment it"
sudo sed -i 's|AutoEnable=true|AutoEnable=false|g' /etc/bluetooth/main.conf

# ------------------------------------------------------------------------

# Prevent stupid error beeps*
sudo rmmod pcspkr
echo -e "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf

# ------------------------------------------------------------------------

sudo rm -rf /home/*/.cache/thumbnails
echo -e "Clear pacman cache, orphans"
sudo pacman -Sc --noconfirm
sudo pacman -Scc --noconfirm
sudo pacman -Qtdq &&
    sudo pacman -Rns --noconfirm $(pacman -Qtdq)
echo -e "Remove snapd and flatpak garbages"
sudo snap remove snap-store
sudo systemctl disable --now snapd
sudo umount /run/snap/ns
sudo systemctl disable snapd.service
sudo systemctl disable snapd.socket
sudo systemctl disable snapd.seeded.service
sudo systemctl disable snapd.autoimport.service
sudo systemctl disable snapd.apparmor.service
sudo rm -rf /etc/apparmor.d/usr.lib.snapd.snap-confine.real
sudo systemctl start apparmor.service

sudo pacman -Rns --noconfirm snapd

sudo rm -rf /home/*/snap
sudo rm -rf /snap
sudo rm -rf /var/snap
sudo rm -rf /var/lib/snapd
sudo rm -rf /var/cache/snapd
sudo rm -rf /usr/lib/snapd

flatpak uninstall --all

sudo pacman -Rns --noconfirm flatpak
sync

# ------------------------------------------------------------------------

# Implement .config/ files of the openbox
cd /tmp &&
    git clone https://github.com/YurinDoctrine/.config.git &&
    sudo cp -R .config/.conkyrc /home/* &&
    sudo cp -R .config/.gmrunrc /home/* &&
    sudo cp -R .config/.gtkrc-2.0 /home/* &&
    sudo cp -R .config/.gtkrc-2.0.mine /home/* &&
    sudo cp -R .config/.Xresources /home/* &&
    sudo cp -R .config/.xscreensaver /home/* &&
    sudo cp -R .config/.fonts.conf /home/* &&
    sudo cp -R .config/* /home/*/.config &&
    sudo cp -R .config/.conkyrc /etc/skel &&
    sudo cp -R .config/.gmrunrc /etc/skel &&
    sudo cp -R .config/.gtkrc-2.0 /etc/skel &&
    sudo cp -R .config/.gtkrc-2.0.mine /etc/skel &&
    sudo cp -R .config/.Xresources /etc/skel &&
    sudo cp -R .config/.xscreensaver /etc/skel &&
    sudo cp -R .config/.fonts.conf /etc/skel &&
    sudo cp -R .config/* /etc/skel/.config &&
    sudo mkdir /root/.config
sudo cp -R .config/* /root/.config
sudo chmod 755 /home/*/.config/dmenu/dmenu-bind.sh &&
    sudo chmod 755 /home/*/.config/cbpp-exit &&
    sudo chmod 755 /home/*/.config/cbpp-help-pipemenu &&
    sudo chmod 755 /home/*/.config/cbpp-compositor &&
    sudo chmod 755 /home/*/.config/cbpp-places-pipemenu &&
    sudo chmod 755 /etc/skel/.config/cbpp-exit &&
    sudo chmod 755 /etc/skel/.config/cbpp-help-pipemenu &&
    sudo chmod 755 /etc/skel/.config/cbpp-compositor &&
    sudo chmod 755 /etc/skel/.config/cbpp-places-pipemenu &&
    git clone --branch 11 https://github.com/CBPP/cbpp-icon-theme.git &&
    sudo cp -R cbpp-icon-theme/cbpp-icon-theme/data/usr/share/icons/* /usr/share/icons &&
    git clone --branch 11 https://github.com/CBPP/cbpp-ui-theme.git &&
    sudo cp -R cbpp-ui-theme/cbpp-ui-theme/data/usr/share/themes/* /usr/share/themes &&
    git clone --branch 11 https://github.com/CBPP/cbpp-wallpapers.git &&
    sudo cp -R cbpp-wallpapers/cbpp-wallpapers/data/usr/share/backgrounds/* /usr/share/backgrounds &&
    git clone --branch 11 https://github.com/CBPP/cbpp-pipemenus.git &&
    sudo cp -R cbpp-pipemenus/cbpp-pipemenus/data/usr/bin/* /usr/bin &&
    git clone --branch 11 https://github.com/CBPP/cbpp-configs.git &&
    sudo cp -R cbpp-configs/cbpp-configs/data/usr/bin/* /usr/bin &&
    sudo mv /home/*/.config/cbpp-exit /usr/bin &&
    sudo mv /home/*/.config/cbpp-help-pipemenu /usr/bin &&
    sudo mv /home/*/.config/cbpp-compositor /usr/bin &&
    sudo mv /home/*/.config/cbpp-places-pipemenu /usr/bin &&
    sudo mv /etc/skel/.config/cbpp-exit /usr/bin &&
    sudo mv /etc/skel/.config/cbpp-help-pipemenu /usr/bin &&
    sudo mv /etc/skel/.config/cbpp-compositor /usr/bin &&
    sudo mv /etc/skel/.config/cbpp-places-pipemenu /usr/bin &&
    git clone --branch 11 https://github.com/CBPP/cbpp-lxdm-theme.git &&
    sudo rm -rf /usr/share/lxdm/themes/*
sudo cp -R cbpp-lxdm-theme/cbpp-lxdm-theme/data/etc/lxdm/* /etc/lxdm
sudo cp -R cbpp-lxdm-theme/cbpp-lxdm-theme/data/usr/share/lxdm/themes/* /usr/share/lxdm/themes
cd &&
    echo -e "XDG_CURRENT_DESKTOP=Unity
QT_QPA_PLATFORMTHEME=gtk2" | sudo tee -a /etc/environment

# ------------------------------------------------------------------------

extra() {
    curl -fsSL https://raw.githubusercontent.com/YurinDoctrine/ultra-gaming-setup-wizard/main/ultra-gaming-setup-wizard.sh >ultra-gaming-setup-wizard.sh &&
        chmod 755 ultra-gaming-setup-wizard.sh &&
        ./ultra-gaming-setup-wizard.sh
}
extra2() {
    curl -fsSL https://raw.githubusercontent.com/YurinDoctrine/secure-linux/master/secure.sh >secure.sh &&
        chmod 755 secure.sh &&
        ./secure.sh
}

final() {
    echo -e "
###############################################################################
# All Done! Would you also mind to run the author's ultra-gaming-setup-wizard?
###############################################################################
"

    read -p $'yes/no >_: ' ans
    if [[ "$ans" == "yes" ]]; then
        echo -e "RUNNING ..."
        chsh -s /usr/bin/fish         # Change default shell before leaving.
        sudo ln -sfT dash /usr/bin/sh # Link dash to /usr/bin/sh
        extra
    elif [[ "$ans" == "no" ]]; then
        echo -e "LEAVING ..."
        echo -e ""
        echo -e "FINAL: DO YOU ALSO WANT TO RUN THE AUTHOR'S secure-linux?"
        read -p $'yes/no >_: ' noc
        if [[ "$noc" == "yes" ]]; then
            echo -e "RUNNING ..."
            chsh -s /usr/bin/fish         # Change default shell before leaving.
            sudo ln -sfT dash /usr/bin/sh # Link dash to /usr/bin/sh
            extra2
        elif [[ "$noc" == "no" ]]; then
            echo -e "LEAVING ..."
            chsh -s /usr/bin/fish         # Change default shell before leaving.
            sudo ln -sfT dash /usr/bin/sh # Link dash to /usr/bin/sh
            exit 0
        else
            echo -e "INVALID VALUE!"
            final
        fi
    else
        echo -e "INVALID VALUE!"
        final
    fi
}
final
