#!/bin/bash

# ------------------------------------------------------------------------

# Before hop in
sudo pacman -Sy &&
    sudo pacman -S --needed --noconfirm base-devel pacman-contrib git &&
    sudo pacman -S --needed --noconfirm yay

# ------------------------------------------------------------------------

# Ranking mirrors
sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -e "Setting up mirrors for optimal download ..."
cat /etc/pacman.d/mirrorlist | rankmirrors -n 8 -m 6 - >$HOME/mirrorlist
sudo mv $HOME/mirrorlist /etc/pacman.d/mirrorlist

# ------------------------------------------------------------------------

# Install yay if its still not
which yay >/dev/null 2>&1
if [ $? != 0 ]; then
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
    'xfce4-power-manager' # Power Manager
    'rofi'                # Menu System
    'picom'               # Translucent Windows
    'lxappearance'        # Set System Themes

    # --- Networking Setup
    \
    'wpa_supplicant'         # Key negotiation for WPA wireless networks
    'dialog'                 # Enables shell scripts to trigger dialog boxes
    'openvpn'                # Open VPN support
    'networkmanager-openvpn' # Open VPN plugin for NM
    'network-manager-applet' # System tray icon/utility for network connectivity
    'libsecret'              # Library for storing passwords
    'networkmanager-vpnc'    # Open VPN plugin for NM. Probably not needed if networkmanager-openvpn is installed.
    'network-manager-applet' # System tray icon/utility for network connectivity
    'dhclient'               # DHCP client

    # --- Audio
    \
    'alsa-utils'      # Advanced Linux Sound Architecture (ALSA) Components https://alsa.opensrc.org/
    'alsa-plugins'    # ALSA plugins
    'pulseaudio'      # Pulse Audio sound components
    'pulseaudio-alsa' # ALSA configuration for pulse audio
    'pavucontrol'     # Pulse Audio volume control
    'pnmixer'         # System tray volume control
    'volumeicon'      # System tray volume control

    # --- Bluetooth
    \
    'bluez'                       # Daemons for the bluetooth protocol stack
    'bluez-libs'                  # Daemons for the bluetooth libraries
    'bluez-utils'                 # Bluetooth development and debugging utilities
    'bluez-firmware'              # Firmwares for Broadcom BCM203x and STLC2300 Bluetooth chips
    'blueberry'                   # Bluetooth configuration tool
    'pulseaudio-bluetooth'        # Bluetooth support for PulseAudio
    'pulseaudio-modules-bt' # Bluetooth support for PulseAudio

    # TERMINAL UTILITIES --------------------------------------------------
    \
    'cronie'        # Cron jobs
    'fish'          # The friendly interactive shell
    'ftp'           # File transfer protocol
    'hardinfo'      # Hardware info app
    'htop'          # Process viewer
    'neofetch'      # Shows system info when you launch terminal
    'ntp'           # Network Time Protocol to set time via network.
    'openssh'       # SSH connectivity tools
    'irssi'         # Terminal based IRC
    'p7zip'         # 7z compression program
    'rsync'         # Remote file sync utility
    'speedtest-cli' # Internet speed via terminal
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
    'net-tools'    # Network utilities
    'veracrypt'    # Disc encryption utility
    'variety'      # Wallpaper changer
    'gtkhash'      # Checksum verifier

    # DEVELOPMENT ---------------------------------------------------------
    \
    'ccache'  # Compiler cacher
    'clang'   # C Lang compiler
    'cmake'   # Cross-platform open-source make system
    'meson'   # Build system that use python as a front-end language and Ninja as a building backend
    'gcc'     # C/C++ compiler
    'glibc'   # C libraries
    'glslang' # OpenGL and OpenGL ES shader front end and validator
    'meld'    # File/directory comparison
    'mariadb' # Commercially supported fork of the MySQL
    'nodejs'  # Javascript runtime environment
    'npm'     # Node package manager
    'php'     # Scripting language

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

# Setting up locales
echo -e "Setup language to en_GB and set locale"
sudo sed -i 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen
sudo timedatectl set-ntp 1
sudo localectl set-locale LANG="en_GB.UTF-8" LC_TIME="en_GB.UTF-8"

# ------------------------------------------------------------------------

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
sudo echo -e "[Icon Theme]
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

sudo pacman -Rs snapd -y

sudo rm -rf ~/snap
sudo rm -rf /snap
sudo rm -rf /var/snap
sudo rm -rf /var/lib/snapd
sudo rm -rf /var/cache/snapd
sudo rm -rf /usr/lib/snapd

flatpak uninstall --all

sudo pacman -Rs flatpak -y
sync

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
            echo -e "RUNNING ...\n"
            chsh -s /usr/bin/fish # Change default shell before leaving.
            extra2
        elif [[ "$noc" == "no" ]]; then
            echo -e "LEAVING ...\n"
            chsh -s /usr/bin/fish # Change default shell before leaving.
            exit 0
        else
            echo -e "INVALID VALUE!\n"
            final
        fi
    else
        echo -e "INVALID VALUE!"
        final
    fi
}
final
