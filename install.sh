#!/usr/bin/env bash

echo "WARNING!!!"
echo "this actions can remove and broke your rootfs data, do you want to continue?"
read -p "y/n: " sel
if [[ "$sel" == "n" ]]; then
    exit 1
fi

if [[ ! -d "${PREFIX}/opt" ]]; then
    command mkdir -p "${PREFIX}/opt"
fi

if [[ -d "${PREFIX}/opt/metasploit-for-termux" ]]; then
    command rm -rf "${PREFIX}/opt/metasploit"
fi

command mkdir -p "${PREFIX}/opt/metasploit-for-termux"
command touch "${PREFIX}/opt/metasploit-for-termux/placeholder.txt"

if [[ -x "${PREFIX}/bin/msfconsole" ]]; then
    command rm -f "${PREFIX}/bin/msfconsole"
fi

if [[ -x "${PREFIX}/bin/msfvenom" ]]; then
    command rm -f "${PREFIX}/bin/msfvenom"
fi

function install_metasploit() {
    command cat > \
        "${PREFIX}/var/lib/proot-distro/installed-rootfs/metasploit/root/msfinstall.sh" \
        << 'EOF'
#!/usr/bin/env bash
command apt update -y
export DEBIAN_FRONTEND=noninteractive
command apt \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    full-upgrade -y

command apt install -y \
    curl \
    gnupg

command curl -fsSL \
    "https://archive.kali.org/archive-key.asc" | \
    command gpg --dearmor -o "/etc/apt/trusted.gpg.d/kali.gpg"

echo 'deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware' \
    > "/etc/apt/sources.list"

command mkdir -pv "/etc/apt/preferences.d"
echo 'Package: *\nPin: release o=Kali\nPin-Priority: 1001' \
    > "/etc/apt/preferences.d/kali"

command apt update -y
export DEBIAN_FRONTEND=noninteractive
command apt \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    full-upgrade \
    --allow-downgrades -y

command apt install metasploit-framework -y
EOF
    command chmod +x "${PREFIX}/var/lib/proot-distro/installed-rootfs/metasploit/root/msfinstall.sh"
    command proot-distro login metasploit -- bash '/root/msfinstall.sh'
    command rm -f "${PREFIX}/var/lib/proot-distro/installed-rootfs/metasploit/root/msfinstall.sh"

    command cat > \
        "${PREFIX}/bin/msfconsole" \
        << 'EOF'
#!/usr/bin/env bash
exec proot-distro login metasploit -- msfconsole "${@}"
EOF
    command chmod +x "${PREFIX}/bin/msfconsole"

    command cat > \
        "${PREFIX}/bin/msfvenom" \
        << 'EOF'
#!/usr/bin/env bash
exec proot-distro login metasploit -- msfvenom "${@}"
EOF
    command chmod +x "${PREFIX}/bin/msfvenom"

    command cat > \
        "${PREFIX}/bin/metasploit-for-termux" \
        << 'EOF'
#!/usr/bin/env bash
exec proot-distro login metasploit -- msfconsole "${@}"
EOF
    command chmod +x "${PREFIX}/bin/metasploit-for-termux"
}

if [[ -d "${PREFIX}/var/lib/proot-distro/installed-rootfs/debian" ]]; then
    command proot-distro remove debian
fi

command proot-distro install debian

if [[ ! -d "${PREFIX}/var/lib/proot-distro/installed-rootfs/metasploit" ]]; then
    command proot-distro renmae debian metasploit
    install_metasploit
else
    command proot-distro remove metasploit
    command proot-distro rename debian metasploit
    install_metasploit
fi