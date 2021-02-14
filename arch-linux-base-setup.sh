#!/bin/bash
# Before hop in
sudo pacman -Sy &&
    sudo pacman -S --needed --noconfirm base-devel pacman-contrib git &&
    sudo pacman -S --needed --noconfirm yay

# ------------------------------------------------------------------------

# Setting up locales
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
    \
    'xscreensaver'            # A screen saver and locker for the X
    'xfce4-power-manager'     # Power Manager
    'xfce4-notifyd'           # Notification indicator
    'xfce4-pulseaudio-plugin' # Xfce4 panel plugin icon to control Pulseaudio
    'xbacklight'              # RandR-based backlight control application
    'dmenu'                   # Generic menu for X
    'gmrun'                   # A lightweight application launcher
    'ibus'                    # An input method framework
    'compton'                 # A compositor for X11
    'conky'                   # A system monitor software for the X Window System
    'nitrogen'                # A fast and lightweight desktop background browser and setter for X Window
    'openbox'                 # A lightweight, powerful, and highly configurable stacking window manager
    'tint2'                   # A simple, unobtrusive and light panel for Xorg
    'lxsession'               # A toolkit for defining and handling authorizations
    'lxappearance'            # Set System Themes
    'qt5-styleplugins'        # Additional style plugins for Qt5

    # DEVELOPMENT ---------------------------------------------------------
    \
    'ccache'  # Compiler cacher
    'clang'   # C Lang compiler
    'cmake'   # Cross-platform open-source make system
    'gcc'     # C/C++ compiler
    'glibc'   # C libraries
    'glslang' # OpenGL and OpenGL ES shader front end and validator
    'meld'    # File/directory comparison
    'mariadb' # Commercially supported fork of the MySQL
    'meson'   # Build system that use python as a front-end language and Ninja as a building backend
    'nodejs'  # Javascript runtime environment
    'npm'     # Node package manager
    'php'     # Scripting language

    # --- Networking Setup
    \
    'wpa_supplicant'         # Key negotiation for WPA wireless networks
    'dialog'                 # Enables shell scripts to trigger dialog boxes
    'openvpn'                # Open VPN support
    'networkmanager-openvpn' # Open VPN plugin for NM
    'network-manager-applet' # System tray icon/utility for network connectivity
    'libsecret'              # Library for storing passwords
    'dhclient'               # DHCP client

    # --- Audio
    \
    'alsa-utils'      # Advanced Linux Sound Architecture (ALSA) Components https://alsa.opensrc.org/
    'alsa-plugins'    # ALSA plugins
    'pulseaudio'      # Pulse Audio sound components
    'pulseaudio-alsa' # ALSA configuration for pulse audio
    'pavucontrol'     # Pulse Audio volume control
    'pasystray'       # PulseAudio system tray

    # --- Bluetooth
    \
    'bluez'                 # Daemons for the bluetooth protocol stack
    'bluez-libs'            # Daemons for the bluetooth libraries
    'bluez-utils'           # Bluetooth development and debugging utilities
    'bluez-firmware'        # Firmwares for Broadcom BCM203x and STLC2300 Bluetooth chips
    'blueberry'             # Bluetooth configuration tool
    'pulseaudio-bluetooth'  # Bluetooth support for PulseAudio
    'pulseaudio-modules-bt' # Bluetooth support for PulseAudio

    # TERMINAL UTILITIES --------------------------------------------------
    \
    'cronie'        # Cron jobs
    'fish'          # The friendly interactive shell
    'vsftpd'        # File transfer protocol
    'hardinfo'      # Hardware info app
    'htop'          # Process viewer
    'neofetch'      # Shows system info when you launch terminal
    'openssh'       # SSH connectivity tools
    'irssi'         # Terminal based IRC
    'p7zip'         # 7z compression program
    'rsync'         # Remote file sync utility
    'ttf-roboto'    # Font package
    'speedtest-cli' # Internet speed via terminal
    'terminator'    # A terminal emulator
    'terminus-font' # Font package with some bigger fonts for login terminal
    'unrar'         # RAR compression program
    'unzip'         # Zip compression program
    'wget'          # Remote content retrieval
    'vim'           # Terminal Editor
    'zenity'        # Display graphical dialog boxes via shell scripts
    'zip'           # Zip compression program

    # DISK UTILITIES ------------------------------------------------------
    \
    'android-tools'         # ADB for Android
    'android-file-transfer' # Android File Transfer
    'autofs'                # Auto-mounter
    'btrfs-progs'           # BTRFS Support
    'dosfstools'            # DOS Support
    'exfat-utils'           # Mount exFat drives
    'gparted'               # Disk utility
    'gvfs-mtp'              # Read MTP Connected Systems
    'gvfs-smb'              # More File System Stuff
    'ntfs-3g'               # Open source implementation of NTFS file system
    'parted'                # Disk utility
    'samba'                 # Samba File Sharing
    'smartmontools'         # Disk Monitoring
    'smbclient'             # SMB Connection
    'xfsprogs'              # XFS Support

    # GENERAL UTILITIES ---------------------------------------------------
    \
    'flameshot'    # Screenshots
    'file-roller'  # Create and modify archives
    'freerdp'      # RDP Connections
    'libvncserver' # VNC Connections
    'filezilla'    # FTP Client
    'apache2'      # HTTP server
    'playerctl'    # Utility to control media players via MPRIS
    'remmina'      # Remote Connection
    'transmission' # BitTorrent client
    'net-tools'    # Network utilities
    'veracrypt'    # Disc encryption utility
    'variety'      # Wallpaper changer
    'gtkhash'      # Checksum verifier

    # GRAPHICS, VIDEO AND DESIGN -------------------------------------------------
    \
    'gcolor2'   # Colorpicker
    'gimp'      # GNU Image Manipulation Program
    'ristretto' # Multi image viewer
    'kdenlive'  # Movie Render

    # PRINTING --------------------------------------------------------
    \
    'xpdf'                  # PDF viewer
    'cups'                  # Open source printer drivers
    'cups-pdf'              # PDF support for cups
    'ghostscript'           # PostScript interpreter
    'gsfonts'               # Adobe Postscript replacement fonts
    'hplip'                 # HP Drivers
    'system-config-printer' # Printer setup  utility

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
sudo sed -i -e 's|[# ]*HandleLidSwitch[ ]*=[ ]*.*|HandleLidSwitch=suspend|g' /etc/systemd/logind.conf

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
# Start/restart PulseAudio.
sudo killall -HUP pulseaudio

# ------------------------------------------------------------------------

echo -e "Disabling bluetooth daemon by comment it"
sudo sed -i 's|AutoEnable|#AutoEnable|g' /etc/bluetooth/main.conf

# ------------------------------------------------------------------------

# Prevent stupid error beeps*
sudo rmmod pcspkr
echo -e "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf

# ------------------------------------------------------------------------

# Same theme for Qt/KDE applications and GTK applications, and fix missing indicators
echo -e "XDG_CURRENT_DESKTOP=Unity
QT_QPA_PLATFORMTHEME=gtk2" | sudo tee -a /etc/environment

# ------------------------------------------------------------------------

sudo rm -rf ~/.cache/thumbnails
echo -e "Clear pacman cache, orphans"
sudo pacman -Sc
sudo pacman -Scc
sudo pacman -Qtdq &&
    sudo pacman -Rns $(pacman -Qtdq)

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

sudo pacman -Rns snapd

sudo rm -rf ~/snap
sudo rm -rf /snap
sudo rm -rf /var/snap
sudo rm -rf /var/lib/snapd
sudo rm -rf /var/cache/snapd
sudo rm -rf /usr/lib/snapd

flatpak uninstall --all

sudo pacman -Rns flatpak
sync

# ------------------------------------------------------------------------

# Implement .config/ files of the openbox
cd /tmp &&
    git clone https://github.com/YurinDoctrine/.config.git &&
    sudo cp -R .config/.conkyrc ~ &&
    sudo cp -R .config/* ~/.config &&
    git clone --branch 10 https://github.com/CBPP/cbpp-icon-theme.git &&
    sudo cp -R cbpp-icon-theme/cbpp-icon-theme/data/usr/share/icons/* /usr/share/icons &&
    git clone --branch 10 https://github.com/CBPP/cbpp-ui-theme.git &&
    sudo cp -R cbpp-ui-theme/cbpp-ui-theme/data/usr/share/themes/* /usr/share/themes &&
    git clone --branch 10 https://github.com/CBPP/cbpp-wallpapers.git &&
    sudo cp -R cbpp-wallpapers/cbpp-wallpapers/data/usr/share/backgrounds/* /usr/share/backgrounds &&
    git clone --branch 10 https://github.com/CBPP/cbpp-slim.git &&
    sudo cp -R cbpp-slim/cbpp-slim/data/usr/bin/* /usr/bin &&
    git clone --branch 10 https://github.com/CBPP/cbpp-exit.git &&
    sudo cp -R cbpp-exit/cbpp-exit/data/usr/bin/* /usr/bin &&
    git clone --branch 10 https://github.com/CBPP/cbpp-pipemenus.git &&
    sudo cp -R cbpp-pipemenus/cbpp-pipemenus/data/usr/bin/* /usr/bin &&
    cd

# ------------------------------------------------------------------------

echo -e "
###############################################################################
# All done! Would you also mind to run the author's ultra-gaming-setup-wizard?
###############################################################################
"

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
    read -p $'yes/no >_: ' ans
    if [[ "$ans" == "yes" ]]; then
        echo -e "RUNNING ..."
        chsh -s /usr/bin/fish # Change default shell before leaving.
        extra
    elif [[ "$ans" == "no" ]]; then
        echo -e "LEAVING ..."
        echo -e ""
        echo -e "FINAL: DO YOU ALSO WANT TO RUN THE AUTHOR'S secure-linux?"
        read -p $'yes/no >_: ' noc
        if [[ "$noc" == "yes" ]]; then
            echo -e "RUNNING ..."
            chsh -s /usr/bin/fish # Change default shell before leaving.
            extra2
        elif [[ "$noc" == "no" ]]; then
            echo -e "LEAVING ..."
            chsh -s /usr/bin/fish # Change default shell before leaving.
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
