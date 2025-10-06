#!/bin/bash
# ======================================================================
#  FULL SYSTEM REPORT SCRIPT
#  Generate a detailed system inventory & health report
#  Compatible with most modern Linux distros
# ======================================================================

if [ "$EUID" -ne 0 ]; then
    echo "❌ This script must be run as root (use: sudo $0)"
    exit 1
fi

OUTPUT="system_report_$(hostname)_$(date +%Y%m%d_%H%M%S).txt"

{
    echo "==================== SYSTEM SUMMARY ===================="
    echo "Hostname           : $(hostname)"
    echo "Date/Time          : $(date)"
    echo "Architecture       : $(uname -m)"
    echo "OS Name & Version  : $(grep PRETTY_NAME /etc/os-release | cut -d= -f2- | tr -d '\"')"
    echo "Kernel Version     : $(uname -r)"
    echo "Firmware Version   : $(
        dmidecode -s bios-version 2>/dev/null \
        || sudo dmidecode -s bios-version 2>/dev/null \
        || cat /sys/class/dmi/id/bios_version 2>/dev/null \
        || echo 'Unknown'
    )"

    echo "Firmware Release   : $(
        dmidecode -s bios-release-date 2>/dev/null \
        || sudo dmidecode -s bios-release-date 2>/dev/null \
        || cat /sys/class/dmi/id/bios_date 2>/dev/null \
        || echo 'Unknown'
    )"

    echo "Serial Number      : $(
        dmidecode -s system-serial-number 2>/dev/null \
        || sudo dmidecode -s system-serial-number 2>/dev/null \
        || cat /sys/class/dmi/id/product_serial 2>/dev/null \
        || echo 'Unknown'
    )"
    echo "Machine Model      : $(
        dmidecode -s system-product-name 2>/dev/null \
        || sudo dmidecode -s system-product-name 2>/dev/null \
        || cat /sys/class/dmi/id/product_name 2>/dev/null \
        || echo 'Unknown'
    )"

    echo

    echo "==================== CPU INFORMATION ===================="
    lscpu | egrep "Model name|Socket|Thread|Core|CPU\(s\)"
    echo
    echo "Total CPU Usage:"
    mpstat 1 1 | awk '/Average/ && $12 ~ /[0-9.]+/ {printf "Used: %.1f%%\n", 100 - $12}'
    echo

    echo "==================== MEMORY INFORMATION ===================="
    free -h
    echo
    echo "Memory Usage (%):"
    awk '/Mem:/ {printf("Used: %.1f%%\n", $3/$2 * 100.0)}' <(free)
    echo

    echo "==================== DISK INFORMATION ======================"
    echo "Disk Model and Capacity:"
    lsblk -o NAME,MODEL,SIZE,TYPE,MOUNTPOINT | grep -E "disk|part"
    echo
    echo "Partition Usage:"
    df -h --total
    echo
    echo "RAID Configuration:"
    if command -v mdadm &>/dev/null; then
        # Scan RAID arrays (tanpa sudo dulu, fallback pakai sudo)
        RAID_SCAN=$(mdadm --detail --scan 2>/dev/null || sudo mdadm --detail --scan 2>/dev/null)
        if [[ -n "$RAID_SCAN" ]]; then
            echo "$RAID_SCAN"
            # Detail semua RAID devices
            for dev in /dev/md*; do
                [[ -e "$dev" ]] || continue
                mdadm --detail "$dev" 2>/dev/null || sudo mdadm --detail "$dev" 2>/dev/null
            done
        else
            echo "No RAID configured or insufficient permissions"
        fi
    else
        echo "mdadm not installed"
    fi
    echo

    echo "==================== NETWORK CONFIGURATION ================="
    echo "Interfaces and IPs:"
    ip -o -4 addr show | awk '{print $2": "$4}'
    echo
    echo "Interface Details:"
    ip link show | grep -E "^[0-9]+:|link/ether"
    echo
    echo "Gateway(s):"
    ip route | grep default
    echo
    
    echo "DNS Servers (from /etc/resolv.conf):"
    if [ -f /etc/resolv.conf ]; then
        grep '^nameserver' /etc/resolv.conf | awk '{print $2}'
    else
        echo "No /etc/resolv.conf found"
    fi
    echo

    echo "DNS Configuration (from network config files):"
    FOUND_DNS_CONF=0

    # Netplan (Ubuntu ≥18.04)
    if ls /etc/netplan/*.yaml &>/dev/null; then
        echo "--- /etc/netplan/ ---"
        # grep -E "nameservers|addresses" /etc/netplan/*.yaml | sed 's/^[ \t]*//'
        cat /etc/netplan/*.yaml
        FOUND_DNS_CONF=1
    fi

    # Debian/Ubuntu lama
    if [ -f /etc/network/interfaces ]; then
        echo "--- /etc/network/interfaces ---"
        # grep dns-nameservers /etc/network/interfaces | sed 's/^[ \t]*//'
        cat /etc/network/interfaces
        FOUND_DNS_CONF=1
    fi

    # RHEL/CentOS family
    if ls /etc/sysconfig/network-scripts/ifcfg-* &>/dev/null; then
        echo "--- /etc/sysconfig/network-scripts/ ---"
        # grep DNS /etc/sysconfig/network-scripts/ifcfg-* | sed 's/^[ \t]*//'
        cat /etc/sysconfig/network-scripts/ifcfg-*
        FOUND_DNS_CONF=1
    fi

    if [ $FOUND_DNS_CONF -eq 0 ]; then
        echo "No DNS configuration found in network config files."
    fi
    echo


    echo "Open Ports:"
    ss -tuln
    echo
    echo "MAC Addresses:"
    ip link | awk '/link\/ether/ {print $2}'
    echo
    echo "Interface Count:"
    ip -o link show | wc -l
    echo

    echo "==================== INSTALLED MAJOR APPLICATIONS ================="
    if command -v dpkg &>/dev/null; then
        echo "Top Installed Applications:"
        dpkg-query -W -f='${Installed-Size}\t${Package}\t${Version}\n' | sort -nr | head -20
    elif command -v rpm &>/dev/null; then
        echo "Top Installed Applications:"
        rpm -qa --queryformat '%{SIZE}\t%{NAME}\t%{VERSION}\n' | sort -nr | head -20
    else
        echo "No supported package manager detected."
    fi
    echo

    echo "==================== RUNNING SERVICES ======================"
    systemctl list-units --type=service --state=running --no-pager
    echo

    echo "==================== OPEN PORTS ======================"
    ss -tulpen
    echo

    echo "==================== ACTIVE PROCESSES (TOP 10) ======================"
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -n 15
    echo

    echo "==================== SYSTEM LOAD & UPTIME ======================"
    uptime
    echo
    echo "Load Average:"
    cat /proc/loadavg
    echo

    echo "==================== USERS & LOGIN INFO ======================"
    who
    echo
    echo "Recent Logins:"
    last -n 5
    echo

    echo "==================== CRON JOBS (root) ======================"
    crontab -l -u root 2>/dev/null || echo "No cron jobs for root"
    echo

    echo "==================== DOCKER INFORMATION ======================"
    if command -v docker &>/dev/null; then
        docker info
        echo
        echo "Running Containers:"
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    else
        echo "Docker not installed."
    fi
    echo

    echo "==================== HARDWARE SENSORS ======================"
    if command -v sensors &>/dev/null; then
        sensors
    else
        echo "sensors not installed. Try: sudo apt install lm-sensors"
    fi
    echo

    echo "==================== SECURITY & VULNERABILITY NOTES ======================"
    echo "Kernel Version : $(uname -r)"
    echo "-> Check CVEs via: https://cve.mitre.org/"
    # Cek paket yang bisa diupgrade (Debian/Ubuntu)
    if command -v apt &>/dev/null; then
        echo "-> Kernel / package updates available:"
        # Coba tanpa sudo dulu, fallback pakai sudo
        UPGRADABLE=$(apt list --upgradable 2>/dev/null || sudo apt list --upgradable 2>/dev/null)
        if [[ -n "$UPGRADABLE" ]]; then
            echo "$UPGRADABLE" | grep -i "linux" || echo "No kernel updates available"
        else
            echo "Unable to check updates or no updates available"
        fi
    else
        echo "-> Package manager 'apt' not found; check updates manually"
    fi
    echo
    echo "OpenSSL Version: $(openssl version 2>/dev/null || echo 'Not Installed')"
    echo "-> Verify with: openssl version -a"
    echo
    echo "Firewall Status:"
    if command -v ufw &>/dev/null; then
        ufw status verbose
    elif command -v firewall-cmd &>/dev/null; then
        firewall-cmd --state
        firewall-cmd --list-all
    else
        echo "No firewall tool (ufw/firewalld) found."
    fi
    echo

} > "$OUTPUT"

echo $OUTPUT
# echo "✅ Full system report saved to: $OUTPUT"