#!/usr/bin/env bash
# Before hop in
sudo pacman -Syy &&
    sudo pacman -S --needed --noconfirm 9base arch-install-scripts binutils curl fonts-terminus git gnupg haveged kmod pacman-contrib pkgconf psmisc ufw zstd wget xdg-utils
sudo pacman -S --needed --noconfirm reflector
sudo pacman -S --needed --noconfirm yay

# ------------------------------------------------------------------------

# Setting up locales & timezones
echo -e "LANG=en_GB.UTF8" | sudo tee -a /etc/environment
echo -e "LANGUAGE=en_GB.UTF8" | sudo tee -a /etc/environment
echo -e "LC_ALL=en_GB.UTF8" | sudo tee -a /etc/environment
sudo sed -i -e 's/^#en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
sudo locale-gen en_GB.UTF-8
sudo timedatectl set-timezone Europe/Moscow

# ------------------------------------------------------------------------

# Ranking mirrors
sudo pacman-mirrors --api --protocol https --country all
sudo cp -R /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak
echo -e "Setting up mirrors for optimal download ..."
reflector --protocol https --latest 3 --age 48 --sort rate --save $HOME/mirrorlist
sudo mv $HOME/mirrorlist /etc/pacman.d/mirrorlist

# ------------------------------------------------------------------------

# Install yay if its still not
which yay >/dev/null 2>&1
if [ $? != 0 ]; then
    cd /tmp
    sudo pacman -S --needed --noconfirm base-devel
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si
    cd /tmp
fi

# ------------------------------------------------------------------------

# Remove GUI repository
sudo sed -i -e "/alg_repo/,+2d" /etc/pacman.conf
# Colorful progress bar
egrep -q "^Color" /etc/pacman.conf || sudo sed -i -e "s/^#Color$/Color/" /etc/pacman.conf
egrep -q "ILoveCandy" /etc/pacman.conf || sudo sed -i -e "/#VerbosePkgLists/a ILoveCandy" /etc/pacman.conf
# Increase from the default 1 package download at a time to 3.
sudo sed -i -e s"/\#ParallelDownloads.*/ParallelDownloads=3/"g /etc/pacman.conf
# Makepkg config
echo -e "Set arch"
sudo sed -i -e "s/-march=x86-64 -mtune=generic -O2/-march=native -mtune=native -O3/g" /etc/makepkg.conf
echo -e "Set BUILDDIR"
sudo sed -i -e "s|#BUILDDIR.*|BUILDDIR=/tmp/makepkg|g" /etc/makepkg.conf
echo -e "Use all cores for compilation"
sudo sed -i -e "s/-j2/-j$(nproc)/;s/^#MAKEFLAGS/MAKEFLAGS/" /etc/makepkg.conf
echo -e "Use all cores for compression"
sudo sed -i -e "s/xz -c/xz -c -z -q --threads=$(nproc)/;s/^#COMPRESSXZ/COMPRESSXZ/;s/xz -c/zstd -c -z -q --threads=$(nproc)/;s/^#COMPRESSZST/COMPRESSZST/" /etc/makepkg.conf
echo -e "Use different compression algorithm"
sudo sed -i -e "s/PKGEXT.*/PKGEXT='.pkg.tar.lz4'/g" /etc/makepkg.conf

# ------------------------------------------------------------------------

# GNOME settings
sudo rm -rfd /etc/gdm{3}/custom.conf
sudo rm -rfd /etc/dconf/db/gdm{3}.d/01-logo

# Privacy
gsettings set org.gnome.system.location enabled false
gsettings set org.gnome.desktop.privacy disable-camera true
gsettings set org.gnome.desktop.privacy disable-microphone true
gsettings set org.gnome.desktop.privacy remember-recent-files false

# Security
gsettings set org.gnome.login-screen allowed-failures 100
gsettings set org.gnome.desktop.screensaver user-switch-enabled false

# Media
gsettings set org.gnome.desktop.sound event-sounds false
gsettings set org.gnome.settings-daemon.plugins.media-keys max-screencast-length 0

# Power
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'interactive'

# ------------------------------------------------------------------------

# This may take time
echo -e "Installing Base System"

PKGS=(
    # --- Importants

    'chrony'      # Versatile implementation of the Network Time Protocol
    'dbus-broker' # Linux D-Bus Message Broker
    'mksh'        # MirBSD Korn Shell
    'preload'     # Makes applications run faster by prefetching binaries and shared objects
    'tumbler'     # D-Bus service for applications to request thumbnails

    # GENERAL UTILITIES ---------------------------------------------------

    'irqbalance'  # IRQ balancing daemon for SMP systems
    'wireplumber' # Modular session / policy manager for PipeWire

    # DEVELOPMENT ---------------------------------------------------------

    'ccache' # Compiler Cacher
    'distcc' # Distributed Compilation Service

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
echo -e "FONT=ter-v22b
FONT_MAP=8859-2" | sudo tee /etc/vconsole.conf

# ------------------------------------------------------------------------

echo -e "Disabling Pulse .esd_auth module"
sudo killall -9 pulseaudio
# Pulse audio loads the `esound-protocol` module, which best I can tell is rarely needed.
# That module creates a file called `.esd_auth` in the home directory which I'd prefer to not be there. So...
sudo sed -i -e 's|load-module module-esound-protocol-unix|#load-module module-esound-protocol-unix|g' /etc/pulse/default.pa
# Disable Pulse bluetooth switch
sudo sed -i -e 's|load-module module-switch-on-connect|#load-module module-switch-on-connect|g' /etc/pulse/default.pa
# Restart PulseAudio.
sudo killall -HUP pulseaudio

# ------------------------------------------------------------------------

# Prevent stupid error beeps*
sudo rmmod pcspkr
echo -e "blacklist pcspkr" | sudo tee /etc/modprobe.d/nobeep.conf

# ------------------------------------------------------------------------

# btrfs tweaks if disk is
sudo btrfs balance start -musage=0 -dusage=50 /

# ------------------------------------------------------------------------

echo -e "Apply disk tweaks"
sudo sed -i -e 's| defaults | defaults,relatime,commit=60 |g' /etc/fstab
sudo sed -i -e 's| errors=remount-ro 0 | defaults,relatime,commit=60,errors=remount-ro 0 |g' /etc/fstab

# ------------------------------------------------------------------------

# Optimize sysctl
sudo sed -i -e '/^\/\/swappiness/d' /etc/sysctl.conf
echo -e "vm.swappiness=1
vm.vfs_cache_pressure=50
vm.overcommit_memory = 1
vm.overcommit_ratio = 50
vm.dirty_background_ratio = 5
vm.dirty_ratio = 20
vm.stat_interval = 10
vm.page-cluster = 0
vm.dirty_expire_centisecs = 1000
vm.oom_kill_allocating_task = 1
kernel.sysrq = 0
kernel.watchdog_thresh = 30
kernel.nmi_watchdog = 0
kernel.timer_migration = 0
kernel.core_uses_pid = 1
kernel.hung_task_timeout_secs = 0
kernel.sched_rt_runtime_us = -1
kernel.sched_rt_period_us = 1
kernel.sched_autogroup_enabled = 1
kernel.sched_child_runs_first = 1
kernel.sched_tunable_scaling = 0
kernel.sched_schedstats = 0
kernel.numa_balancing = 1
kernel.panic = 0
kernel.panic_on_oops = 0
fs.lease-break-time = 10
net.ipv4.tcp_frto=1
net.ipv4.tcp_frto_response=2
net.ipv4.tcp_low_latency=1
net.ipv4.tcp_slow_start_after_idle=0
net.ipv4.tcp_window_scaling=1
net.ipv4.tcp_keepalive_time=300
net.ipv4.tcp_keepalive_probes=5
net.ipv4.tcp_keepalive_intvl=15
net.ipv4.tcp_ecn=1
net.ipv4.tcp_fastopen=3" | sudo tee /etc/sysctl.d/99-swappiness.conf
echo -e "Drop caches"
sudo sysctl -w vm.drop_caches=3
sudo sysctl -w vm.drop_caches=2
echo -e "Restart swap"
sudo swapoff -av && sudo swapon -av

# ------------------------------------------------------------------------

# Enable trim
sudo systemctl start fstrim.timer
echo -e "Run fstrim"
sudo fstrim -Av

# ------------------------------------------------------------------------

## Remove floppy cdrom
sudo sed -i -e '/^\/\/floppy/d' /etc/fstab
sudo sed -i -e '/^\/\/sr/d' /etc/fstab

# ------------------------------------------------------------------------

## Set some ulimits to unlimited
echo -e "* soft memlock unlimited
* hard memlock unlimited
root soft memlock unlimited
root hard memlock unlimited
* soft nproc unlimited
* hard nproc unlimited
root soft nproc unlimited
root hard nproc unlimited
* soft core unlimited
* hard core unlimited
root soft core unlimited
root hard core unlimited
* soft sigpending unlimited
* hard sigpending unlimited
root soft sigpending unlimited
root hard sigpending unlimited" | sudo tee /etc/security/limits.conf

# ------------------------------------------------------------------------

echo -e "Disable wait online services"
sudo systemctl mask NetworkManager-wait-online.service >/dev/null 2>&1

# ------------------------------------------------------------------------

## Disable SELINUX
sudo sed -i -e 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config

# ------------------------------------------------------------------------

## Don't autostart .desktop
sudo sed -i -e 's/NoDisplay=true/NoDisplay=false/g' /etc/xdg/autostart/*.desktop

# ------------------------------------------------------------------------

echo -e "Enable tmpfs ramdisk"
sudo sed -i -e '/^\/\/tmpfs/d' /etc/fstab
echo -e "tmpfs /tmp tmpfs nodiratime,nosuid,size=100m 0 0
tmpfs /var/tmp tmpfs nodiratime,noexec,nosuid 0 0
tmpfs /var/run tmpfs nodiratime,nosuid,size=2m 0 0
tmpfs /var/log tmpfs nodiratime,nosuid,size=20m 0 0" | sudo tee -a /etc/fstab

# ------------------------------------------------------------------------

## Disable resume from hibernate
echo -e "#" | sudo tee /etc/initramfs-tools/conf.d/resume

# ------------------------------------------------------------------------

echo -e "Enable dbus-broker"
sudo systemctl enable dbus-broker.service
sudo systemctl --global enable dbus-broker.service

# ------------------------------------------------------------------------

echo -e "Disable systemd-timesync daemon"
sudo systemctl disable systemd-timesyncd.service
sudo systemctl --global disable systemd-timesyncd.service

# ------------------------------------------------------------------------

echo -e "Optimize writes to the disk"
sudo sed -i -e s"/\#Storage.*/Storage=volatile/"g /etc/systemd/journald.conf
sudo sed -i -e s"/\#Seal.*/Seal=no/"g /etc/systemd/journald.conf

# ------------------------------------------------------------------------

## Enable ALPM
if [[ -e /etc/pm/config.d ]]; then
    echo -e "SATA_ALPM_ENABLE=true
SATA_LINKPWR_ON_BAT=min_power" | sudo tee /etc/pm/config.d/sata_alpm
else
    sudo mkdir /etc/pm/config.d
    echo -e "SATA_ALPM_ENABLE=true
SATA_LINKPWR_ON_BAT=min_power" | sudo tee /etc/pm/config.d/sata_alpm
fi

# ------------------------------------------------------------------------

echo -e "Enable NetworkManager powersave on"
echo -e "[connection]
wifi.powersave = 1" | sudo tee /etc/NetworkManager/conf.d/default-wifi-powersave-on.conf

# ------------------------------------------------------------------------

# Suspend when lid is closed
sudo sed -i -e 's/#HandleLidSwitch=.*/HandleLidSwitch=suspend/' /etc/systemd/logind.conf

# ------------------------------------------------------------------------

echo -e "Disable bluetooth autostart"
sudo sed -i -e 's/AutoEnable.*/AutoEnable=false/' /etc/bluetooth/main.conf
sudo sed -i -e 's/#FastConnectable.*/FastConnectable = false/' /etc/bluetooth/main.conf

# ------------------------------------------------------------------------

echo -e "Disable systemd radio service/socket"
sudo systemctl disable systemd-rfkill.service
sudo systemctl --global disable systemd-rfkill.service
sudo systemctl disable systemd-rfkill.socket
sudo systemctl --global disable systemd-rfkill.socket

# ------------------------------------------------------------------------

## GRUB timeout
sudo sed -i -e 's/GRUB_TIMEOUT=.*/GRUB_TIMEOUT=1/' /etc/default/grub
## Change GRUB defaults
sudo sed -i -e 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet i915.fastboot=1 i915.enable_fbc=1 i915.enable_guc=2 i915.lvds_downclock=1 i915.semaphores=1 pcie_aspm=force drm.vblankoffdelay=1 vt.global_cursor_default=0 scsi_mod.use_blk_mq=1 mitigations=off zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=20 zswap.zpool=z3fold plymouth.ignore-serial-consoles loglevel=0 rd.systemd.show_status=auto rd.udev.log_level=0 udev.log_priority=3 audit=0 no_timer_check cryptomgr.notests intel_iommu=igfx_off kvm-intel.nested=1 iwlmvm_power_scheme=2 noreplace-smp page_alloc.shuffle=1 rcupdate.rcu_expedited=1 tsc=reliable nowatchdog idle=poll noatime"/' /etc/default/grub
echo -e "Enable BFQ scheduler"
echo -e "bfq" | sudo tee /etc/modules-load.d/bfq.conf
echo -e 'ACTION=="add|change", KERNEL=="sd*[!0-9]|sr*", ATTR{queue/rotational}=="1", ATTR{queue/iosched/low_latency}="1", ATTR{queue/scheduler}="bfq"' | sudo tee /etc/udev/rules.d/60-scheduler.rules
sudo update-grub
sudo grub-mkconfig -o /boot/grub/grub.cfg
echo -e "Enable z3fold"
echo -e "z3fold" | sudo tee -a /etc/initramfs-tools/modules
sudo update-initramfs -u

# ------------------------------------------------------------------------

extra() {
    cd /tmp
    curl --tlsv1.2 -fsSL https://raw.githubusercontent.com/YurinDoctrine/ultra-gaming-setup-wizard/main/ultra-gaming-setup-wizard.sh >ultra-gaming-setup-wizard.sh &&
        chmod 0755 ultra-gaming-setup-wizard.sh &&
        ./ultra-gaming-setup-wizard.sh
}

extra2() {
    cd /tmp
    curl --tlsv1.2 -fsSL https://raw.githubusercontent.com/YurinDoctrine/secure-linux/master/secure.sh >secure.sh &&
        chmod 0755 secure.sh &&
        ./secure.sh
}

final() {
    sleep 1s
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
cd

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
yay -Rcc man-pages

# ------------------------------------------------------------------------

echo -e "Clear the patches"
rm -rfd /{tmp,var/tmp}/{.*,*}
yay -Yc --noconfirm
sudo paccache -rk 0
sudo pacman-optimize
sudo pacman -Qtdq &&
    sudo pacman -Rns --noconfirm $(/bin/pacman -Qttdq)
sudo pacman -Sc --noconfirm
sudo pacman -Scc --noconfirm
sudo pacman-key --populate archlinux
sudo pacman-key --refresh-keys

# ------------------------------------------------------------------------

## Optimize font cache
fc-cache -rfv

# ------------------------------------------------------------------------

echo -e "Clean crash log"
sudo rm -rfd /var/crash/*
echo -e "Clean archived journal"
sudo journalctl --rotate --vacuum-time=0.1
sudo sed -i -e 's/^#ForwardToSyslog=yes/ForwardToSyslog=no/' /etc/systemd/journald.conf
sync
