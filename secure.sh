#!/bin/bash
#--Check if user infected or neither
cd
touch testfile
echo “ASDFZXCV:hf:testfile” >/dev/zero && ls
echo "if this above returns a missing testfile file, that means you're infected(Press ANY KEY)."
read -p '>: '
rm -rf testfile
clear

#--Check for unsigned kernel modules
for mod in $(lsmod | tail -n +2 | cut -d' ' -f1); do modinfo ${mod} | grep -q "signature" || echo "no signature for module: ${mod}"; done

#--Required Packages: ufw fail2ban net-tools
sudo apt install --install-recommends ufw fail2ban mini-httpd certbot net-tools apt-transport-https -y

#--Setup UFW rules
sudo ufw limit 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable

#--Harden /etc/sysctl.conf
printf "kernel.dmesg_restrict = 1
kernel.modules_disabled=1
kernel.kptr_restrict = 1
net.core.bpf_jit_harden=2
kernel.yama.ptrace_scope=3
kernel.kexec_load_disabled = 1
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.rp_filter=1
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_rfc1337 = 1
net.ipv4.conf.default.log_martians = 1
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.icmp_echo_ignore_all = 1
net.ipv6.icmp.echo_ignore_all = 1
vm.dirty_background_bytes = 4194304
vm.dirty_bytes = 4194304" >/etc/sysconf.conf

#--PREVENT IP SPOOFS
cat <<EOF >/etc/host.conf
order bind,hosts
multi on
EOF

#--Enable fail2ban
sudo cp fail2ban.local /etc/fail2ban/
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

#--Pacify apport
sudo sed -i 's/enabled=1/enabled=0/g' /etc/default/apport

#--Renew certificates
sudo systemctl stop mini-httpd.service
sudo certbot renew
sudo systemctl start mini-httpd.service

#--Listen current traffic
echo "listening ports"
sudo netstat -tunlp
