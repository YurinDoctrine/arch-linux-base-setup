#!/usr/bin/env bash
# Before hop in
sudo pacman -Syy &&
    sudo pacman -S --needed --noconfirm 9base curl git pacman-contrib
sudo pacman -S --needed --noconfirm reflector
sudo pacman -S --needed --noconfirm yay

# ------------------------------------------------------------------------

# Setting up locales
echo -e "LANG=en_GB.UTF8" | sudo tee -a /etc/locale.conf
echo -e "LANG=en_GB.UTF8" | sudo tee -a /etc/environment
echo -e "LC_ALL=en_GB.UTF8" | sudo tee -a /etc/environment
sudo sed -i -e 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen en_GB.UTF-8
localectl set-locale LANG=en_GB.UTF-8 LC_TIME=en_GB.UTF-8

# ------------------------------------------------------------------------

# Ranking mirrors
sudo cp -R /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
echo -e "Setting up mirrors for optimal download ..."
reflector --latest 3 --sort rate --save $HOME/mirrorlist
sudo mv $HOME/mirrorlist /etc/pacman.d/mirrorlist

# ------------------------------------------------------------------------

# Install yay if its still not
which yay >/dev/null 2>&1
if [ $? != 0 ]; then
    cd /tmp
    sudo pacman -S --needed --noconfirm base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si
    cd /tmp
fi

# ------------------------------------------------------------------------

# Colorful progress bar
echo -e "Make pacman and yay colorful and adds eye candy on the progress bar"
grep -q "^Color" /etc/pacman.conf || sudo sed -i -e "s/^#Color$/Color/" /etc/pacman.conf
grep -q "ILoveCandy" /etc/pacman.conf || sudo sed -i -e "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf

# ------------------------------------------------------------------------

# All cores for compilation
echo -e "Use all cores for compilation"
sudo sed -i -e "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf

# ------------------------------------------------------------------------

# This may take time
echo -e "Installing Base System"

PKGS=(
    # --- Importants

    'mksh' # MirBSD Korn Shell

    # GENERAL UTILITIES ---------------------------------------------------

    'nocache'  # Minimize caching effects
    'preload'  # Makes applications run faster by prefetching binaries and shared objects

    # DEVELOPMENT ---------------------------------------------------------

    'ccache' # Compiler cacher

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
sudo sed -i -e 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers

# ------------------------------------------------------------------------

echo -e "Display asterisks when sudo"
echo -e "Defaults        pwfeedback" | sudo tee -a /etc/sudoers

# ------------------------------------------------------------------------

echo -e "Configuring vconsole.conf to set a larger font for login shell"
echo -e "FONT=ter-v32b" | sudo tee /etc/vconsole.conf

# ------------------------------------------------------------------------

echo -e "Disabling buggy cursor inheritance"
# When you boot with multiple monitors the cursor can look huge. This fixes that...
echo -e "[Icon Theme]
#Inherits=Theme
" | sudo tee /usr/share/icons/default/index.theme

# ------------------------------------------------------------------------

echo -e "Disabling Pulse .esd_auth module"
sudo killall -9 pulseaudio
# Pulse audio loads the `esound-protocol` module, which best I can tell is rarely needed.
# That module creates a file called `.esd_auth` in the home directory which I'd prefer to not be there. So...
sudo sed -i -e 's|load-module module-esound-protocol-unix|#load-module module-esound-protocol-unix|g' /etc/pulse/default.pa
# Restart PulseAudio.
sudo killall -HUP pulseaudio

# ------------------------------------------------------------------------

# Prevent stupid error beeps*
sudo rmmod pcspkr
echo -e "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf

# ------------------------------------------------------------------------

# btrfs tweaks if disk is
sudo btrfs balance start -musage=50 -dusage=50 /

# ------------------------------------------------------------------------

echo -e "Apply disk tweaks"
sudo sed -i -e 's| defaults | defaults,noatime,commit=60 |g' /etc/fstab
sudo sed -i -e 's| errors=remount-ro 0 | noatime,commit=60,errors=remount-ro 0 |g' /etc/fstab

# ------------------------------------------------------------------------

# Tune swappiness value
echo -e "vm.swappiness=10" | sudo tee /etc/sysctl.d/99-swappiness.conf

# ------------------------------------------------------------------------

extra() {
    cd /tmp
    curl -fsSL https://raw.githubusercontent.com/YurinDoctrine/ultra-gaming-setup-wizard/main/ultra-gaming-setup-wizard.sh >ultra-gaming-setup-wizard.sh &&
        chmod 0755 ultra-gaming-setup-wizard.sh &&
        ./ultra-gaming-setup-wizard.sh
}

extra2() {
    cd /tmp
    curl -fsSL https://raw.githubusercontent.com/YurinDoctrine/secure-linux/master/secure.sh >secure.sh &&
        chmod 0755 secure.sh &&
        ./secure.sh
}

final() {

    clear
    echo -e "
###############################################################################
# All Done! Would you also mind to run the author's ultra-gaming-setup-wizard?
###############################################################################
"

    read -p $'yes/no >_: ' ans
    if [[ "$ans" == "yes" ]]; then
        echo -e "RUNNING ..."
        sudo ln -sfT mksh /usr/bin/sh # Link mksh to /usr/bin/sh
        extra
    elif [[ "$ans" == "no" ]]; then
        echo -e "LEAVING ..."
        echo -e ""
        echo -e "FINAL: DO YOU ALSO WANT TO RUN THE AUTHOR'S secure-linux?"
        read -p $'yes/no >_: ' noc
        if [[ "$noc" == "yes" ]]; then
            echo -e "RUNNING ..."
            sudo ln -sfT mksh /usr/bin/sh # Link mksh to /usr/bin/sh
            extra2
        elif [[ "$noc" == "no" ]]; then
            echo -e "LEAVING ..."
            sudo ln -sfT mksh /usr/bin/sh # Link mksh to /usr/bin/sh
            return 0
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

# ------------------------------------------------------------------------

# Don't reserve space man-pages, locales, licenses.
echo -e "Remove useless companies"
find /usr/share/doc/ -depth -type f ! -name copyright | xargs sudo rm -f || true
find /usr/share/doc/ | egrep '\.gz' | xargs sudo rm -f
find /usr/share/doc/ | egrep '\.pdf' | xargs sudo rm -f
find /usr/share/doc/ | egrep '\.tex' | xargs sudo rm -f
find /usr/share/doc/ -empty | xargs sudo rmdir || true
sudo rm -rfd /usr/share/groff/* /usr/share/info/* /usr/share/lintian/* \
    /usr/share/linda/* /var/cache/man/* /usr/share/man/*

# ------------------------------------------------------------------------

echo -e "Clear the patches"
rm -rfd /tmp/*
sudo rm -rfd $HOME/.cache/thumbnails
sudo pacman -Qtdq &&
    sudo pacman -Rns --noconfirm $(/bin/pacman -Qtdq)
sudo pacman -Sc --noconfirm
sudo pacman -Scc --noconfirm

# ------------------------------------------------------------------------

echo -e "Clean archived journal"
sudo journalctl --rotate --vacuum-size=1M
sync

