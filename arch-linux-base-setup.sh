#!/usr/bin/bash
# ------------------------------------------------------------------------

echo "Setting up mirrors for optimal download - GLOBAL"
sudo pacman -S --noconfirm pacman-contrib curl
sudo mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
curl -s "https://www.archlinux.org/mirrorlist/all/https/" | sed -e 's/^#Server/Server/' -e '/^#/d' | rankmirrors -n 5 - >/etc/pacman.d/mirrorlist
read -p "[PRESS ANY KEY TO CONTINUE] "

# ------------------------------------------------------------------------

echo "Uncomment makeflags"
sudo sed -i 's/#MAKEFLAGS/MAKEFLAGS/g' /etc/makepkg.conf

# ------------------------------------------------------------------------

echo "Setup language to en_GB and set locale"
sudo sed -i 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
timedatectl --no-ask-password set-ntp 1
localectl --no-ask-password set-locale LANG="en_GB.UTF-8" LC_COLLATE="" LC_TIME="en_GB.UTF-8"

# ------------------------------------------------------------------------

echo "Add sudo rights"
sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
echo "Add sudo no password rights"
sudo sed -i 's/^# %wheel ALL=(ALL) NOPASSWD: ALL/%wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers

# ------------------------------------------------------------------------

echo -e "\nInstalling Base System\n"

PKGS=(

    # --- XORG Display Rendering
    \
    'xorg'         # Base Package
    'xorg-drivers' # Display Drivers
    'xterm'        # Terminal for TTY
    'xorg-server'  # XOrg server
    'xorg-apps'    # XOrg apps group
    'xorg-xinit'   # XOrg init
    'xorg-xinput'  # Xorg xinput
    'mesa'         # Open source version of OpenGL

    # --- Setup Desktop
    \
    'awesome'             # Awesome Desktop
    'xfce4-power-manager' # Power Manager
    'rofi'                # Menu System
    'picom'               # Translucent Windows
    'xclip'               # System Clipboard
    'gnome-polkit'        # Elevate Applications
    'lxappearance'        # Set System Themes

    # --- Login Display Manager
    \
    'lightdm'                 # Base Login Manager
    'lightdm-webkit2-greeter' # Framework for Awesome Login Themes

    # --- Networking Setup
    \
    'wpa_supplicant'         # Key negotiation for WPA wireless networks
    'dialog'                 # Enables shell scripts to trigger dialog boxex
    'openvpn'                # Open VPN support
    'networkmanager-openvpn' # Open VPN plugin for NM
    'network-manager-applet' # System tray icon/utility for network connectivity
    'libsecret'              # Library for storing passwords

    # --- Audio
    \
    'alsa-utils'      # Advanced Linux Sound Architecture (ALSA) Components https://alsa.opensrc.org/
    'alsa-plugins'    # ALSA plugins
    'pulseaudio'      # Pulse Audio sound components
    'pulseaudio-alsa' # ALSA configuration for pulse audio
    'pavucontrol'     # Pulse Audio volume control
    'pnmixer'         # System tray volume control

    # --- Bluetooth
    \
    'bluez'                # Daemons for the bluetooth protocol stack
    'bluez-utils'          # Bluetooth development and debugging utilities
    'bluez-firmware'       # Firmwares for Broadcom BCM203x and STLC2300 Bluetooth chips
    'blueberry'            # Bluetooth configuration tool
    'pulseaudio-bluetooth' # Bluetooth support for PulseAudio

    # --- PostScript
    \
    'ghostscript' # PostScript interpreter

    # TERMINAL UTILITIES --------------------------------------------------
    \
    'bash-completion' # Tab completion for Bash
    'bleachbit'       # File deletion utility
    'cronie'          # cron jobs
    'curl'            # Remote content retrieval
    'file-roller'     # Archive utility
    'gtop'            # System monitoring via terminal
    'gufw'            # Firewall manager
    'hardinfo'        # Hardware info app
    'htop'            # Process viewer
    'neofetch'        # Shows system info when you launch terminal
    'ntp'             # Network Time Protocol to set time via network.
    'numlockx'        # Turns on numlock in X11
    'openssh'         # SSH connectivity tools
    'p7zip'           # 7z compression program
    'rsync'           # Remote file sync utility
    'speedtest-cli'   # Internet speed via terminal
    'terminus-font'   # Font package with some bigger fonts for login terminal
    'tlp'             # Advanced laptop power management
    'unrar'           # RAR compression program
    'unzip'           # Zip compression program
    'wget'            # Remote content retrieval
    'terminator'      # Terminal emulator
    'vim'             # Terminal Editor
    'zenity'          # Display graphical dialog boxes via shell scripts
    'zip'             # Zip compression program
    'zsh'             # ZSH shell
    'zsh-completions' # Tab completion for ZSH

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
    'nautilus-share'        # File Sharing in Nautilus
    'ntfs-3g'               # Open source implementation of NTFS file system
    'parted'                # Disk utility
    'samba'                 # Samba File Sharing
    'smartmontools'         # Disk Monitoring
    'smbclient'             # SMB Connection
    'xfsprogs'              # XFS Support

    # GENERAL UTILITIES ---------------------------------------------------
    \
    'flameshot'    # Screenshots
    'freerdp'      # RDP Connections
    'libvncserver' # VNC Connections
    'nautilus'     # Filesystem browser
    'remmina'      # Remote Connection
    'veracrypt'    # Disc encryption utility
    'variety'      # Wallpaper changer

    # DEVELOPMENT ---------------------------------------------------------
    \
    'gedit'    # Text editor
    'clang'    # C Lang compiler
    'cmake'    # Cross-platform open-source make system
    'code'     # Visual Studio Code
    'electron' # Cross-platform development using Javascript
    'git'      # Version control system
    'gcc'      # C/C++ compiler
    'glibc'    # C libraries
    'meld'     # File/directory comparison
    'nodejs'   # Javascript runtime environment
    'npm'      # Node package manager
    'python'   # Scripting language
    'yarn'     # Dependency management (Hyper needs this)

    # MEDIA ---------------------------------------------------------------
    \
    'kdenlive'   # Movie Render
    'obs-studio' # Record your screen
    'celluloid'  # Video player

    # GRAPHICS AND DESIGN -------------------------------------------------
    \
    'gcolor2'   # Colorpicker
    'gimp'      # GNU Image Manipulation Program
    'ristretto' # Multi image viewer

    # PRODUCTIVITY --------------------------------------------------------
    \
    'xpdf' # PDF viewer

)

for PKG in "${PKGS[@]}"; do
    echo "INSTALLING: ${PKG}"
    sudo pacman -S "$PKG" --noconfirm --needed
done

echo -e "\nDone!\n"

# ------------------------------------------------------------------------

echo -e "\nINSTALLING AUR SOFTWARE\n"

YAYPKGS=(

    # UTILITIES -----------------------------------------------------------
    \
    'i3lock-fancy'   # Screen locker
    'synology-drive' # Synology Drive
    'freeoffice'     # Office Alternative

    # MEDIA ---------------------------------------------------------------
    \
    'screenkey'    # Screencast your keypresses
    'lbry-app-bin' # LBRY Linux Application

    # THEMES --------------------------------------------------------------
    \
    'lightdm-webkit-theme-aether' # Lightdm Login Theme
    'materia-gtk-theme'           # Desktop Theme
    'papirus-icon-theme'          # Desktop Icons
    'capitaine-cursors'           # Cursor Themes
)

for YAYPKG in "${YAYPKGS[@]}"; do
    yay -S --noconfirm --needed $YAYPKG
done

echo -e "\nDone!\n"

# ------------------------------------------------------------------------

echo -e "\nFINAL SETUP AND CONFIGURATION"

echo -e "\nGenaerating .xinitrc file"

# Generate the .xinitrc file so we can launch Awesome from the
# terminal using the "startx" command
cat <<EOF >${HOME}/.xinitrc
#!/bin/bash
# Disable bell
xset -b

# Disable all Power Saving Stuff
xset -dpms
xset s off

# X Root window color
xsetroot -solid darkgrey

# Merge resources (optional)
#xrdb -merge $HOME/.Xresources

if [ -d /etc/X11/xinit/xinitrc.d ] ; then
    for f in /etc/X11/xinit/xinitrc.d/?*.sh ; do
        [ -x "\$f" ] && . "\$f"
    done
    unset f
fi

exit 0
EOF

# ------------------------------------------------------------------------

echo -e "\nUpdating /bin/startx to use the correct path"

# By default, startx incorrectly looks for the .serverauth file in our HOME folder.
sudo sed -i 's|xserverauthfile=\$HOME/.serverauth.\$\$|xserverauthfile=\$XAUTHORITY|g' /bin/startx

# ------------------------------------------------------------------------

echo -e "\nConfiguring vconsole.conf to set a larger font for login shell"

sudo cat <<EOF >/etc/vconsole.conf
FONT=ter-v32b
EOF

# ------------------------------------------------------------------------

echo -e "\nIncreasing file watcher count"

# This prevents a "too many files" error in Visual Studio Code
echo fs.inotify.max_user_watches=524288 | sudo tee /etc/sysctl.d/40-max-user-watches.conf && sudo sysctl --system

# ------------------------------------------------------------------------

echo -e "\nDisabling Pulse .esd_auth module"

# Pulse audio loads the `esound-protocol` module, which best I can tell is rarely needed.
# That module creates a file called `.esd_auth` in the home directory which I'd prefer to not be there. So...
sudo sed -i 's|load-module module-esound-protocol-unix|#load-module module-esound-protocol-unix|g' /etc/pulse/default.pa

# ------------------------------------------------------------------------

echo -e "\nEnabling Login Display Manager"

sudo systemctl enable --now lightdm.service

# ------------------------------------------------------------------------

echo -e "\nDisabling bluetooth daemon by comment it"

sudo sed -i 's|AutoEnable|#AutoEnable|g' /etc/bluetooth/main.conf

# ------------------------------------------------------------------------

echo "
###############################################################################
# Cleaning
###############################################################################
"

echo "Remove no password sudo rights"
sudo sed -i 's/^%wheel ALL=(ALL) NOPASSWD: ALL/# %wheel ALL=(ALL) NOPASSWD: ALL/' /etc/sudoers
echo "Clean orphans pkg"
if [[ ! -n $(pacman -Qdt) ]]; then
    echo "No orphans to remove."
else
    sudo pacman -Rns $(pacman -Qdtq)
fi

# ------------------------------------------------------------------------

git clone https://github.com/ChrisTitusTech/material-awesome.git ~/.config/awesome
echo -e 'XDG_CURRENT_DESKTOP=Unity\nQT_QPA_PLATFORMTHEME=gtk2' | sudo tee /etc/environment

# ------------------------------------------------------------------------

echo "
###############################################################################
# All Done! Would you like to also run the author's ultra-gaming-setup-wizard? 
###############################################################################
"

extra() {
    curl https://raw.githubusercontent.com/YurinDoctrine/ultra-gaming-setup-wizard/main/ultra-gaming-setup-wizard.sh >ultra-gaming-setup-wizard.sh &&
        chmod 755 ultra-gaming-setup-wizard.sh &&
        ./ultra-gaming-setup-wizard.sh
}

final() {
    read -p ">: " ans
    if [[ "$ans" == "yes" ]]; then
        printf 'RUNNING...\n' && clear
        extra
    elif [[ "$ans" == "no" ]]; then
        printf 'LEAVING...\n'
        exit
    else
        printf 'INVALID VALUE!(yes or no?)\n'
        final
    fi
}
final
