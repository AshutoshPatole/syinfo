#!/bin/bash

############################################################
# Author: Ashutosh Patole
# Version: 1.0
# Description: Comprehensive system information and diagnostics script
# Collects detailed system configuration, performance, and security information
############################################################

# shell check options
set -euo pipefail

# ANSI color codes for better readability
readonly COLOR_RED='\033[0;31m'
readonly COLOR_GREEN='\033[0;32m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_RESET='\033[0m'

# Global variables
readonly SCRIPT_NAME=$(basename "$0")
readonly TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S %Z")
readonly IS_ROOT="$([ "$(id -u)" -eq 0 ] && echo "true" || echo "false")"

# Check if sudo is available
command -v sudo >/dev/null 2>&1 && HAS_SUDO=true || HAS_SUDO=false

# Helper functions
print_header() {
    echo -e "\n${COLOR_BLUE}####################################################################${COLOR_RESET}"
    echo -e "${COLOR_BLUE}# $1${COLOR_RESET}"
    echo -e "${COLOR_BLUE}####################################################################${COLOR_RESET}\n"
}

print_subsection() {
    echo -e "\n${COLOR_BLUE}--- $1 ---${COLOR_RESET}"
}

print_warning() {
    echo -e "${COLOR_YELLOW}[WARNING] $1${COLOR_RESET}" >&2
}

print_error() {
    echo -e "${COLOR_RED}[ERROR] $1${COLOR_RESET}" >&2
}

# Function to run commands with sudo if needed
run_command() {
    local cmd="$1"
    local require_sudo="${2:-false}"
    local description="${3:-$cmd}"
    
    echo -e "\n${COLOR_GREEN}$description${COLOR_RESET}"
    echo -e "${COLOR_GREEN}Command: $cmd${COLOR_RESET}"
    echo -e "${COLOR_GREEN}----------------------------------------${COLOR_RESET}"
    
    if [ "$require_sudo" = true ] && [ "$IS_ROOT" = false ] && [ "$HAS_SUDO" = true ]; then
        sudo bash -c "$cmd" 2>/dev/null || echo "Command failed or requires elevated privileges"
    else
        eval "$cmd" 2>/dev/null || echo "Command failed"
    fi
    echo -e "${COLOR_GREEN}----------------------------------------${COLOR_RESET}"
}

# Function to safely get file contents
get_file_content() {
    local file_path="$1"
    if [ -f "$file_path" ] && [ -r "$file_path" ]; then
        echo -e "\nContents of $file_path:"
        echo "----------------------------------------"
        cat "$file_path"
        echo "----------------------------------------"
    else
        echo "File not found or not readable: $file_path"
    fi
}

# Main execution starts here
main() {
    echo -e "${COLOR_BLUE}=== System Diagnostics Report ===${COLOR_RESET}"
    echo -e "Generated on: $TIMESTAMP"
    echo -e "Running as: $(whoami)"
    echo -e "Hostname: $(hostname -f 2>/dev/null || hostname 2>/dev/null || echo 'Unknown')"
    echo -e "Kernel: $(uname -srmp)"
    echo -e "----------------------------------------\n"

    # Section 1: General System & Hardware Overview
    print_header "1. GENERAL SYSTEM & HARDWARE OVERVIEW"
    
    # 1.1 System Information
    print_subsection "1.1 System Information"
    run_command "uname -a" false "System information (uname -a)"
    run_command "hostnamectl status" false "Hostname and system information"
    
    # 1.2 OS Release Information
    print_subsection "1.2 OS Release Information"
    [ -f /etc/os-release ] && run_command "cat /etc/os-release" false "OS Release Information"
    [ -f /etc/redhat-release ] && run_command "cat /etc/redhat-release" false "RedHat Release Information"
    [ -f /etc/lsb-release ] && run_command "cat /etc/lsb-release" false "LSB Release Information"
    
    # 1.3 Uptime and Load Average
    print_subsection "1.3 Uptime and Load Average"
    run_command "uptime" false "System uptime and load average"
    run_command "w" false "Logged-in users and system load"
    
    # 1.4 CPU Information
    print_subsection "1.4 CPU Information"
    run_command "lscpu" false "CPU Architecture Information"
    run_command "cat /proc/cpuinfo | grep -E '^processor|model name|cpu MHz|cache size' | sort -u" false "CPU Details"
    run_command "nproc --all" false "Number of processing units available"
    
    # 1.5 Memory Information
    print_subsection "1.5 Memory Information"
    run_command "free -h" false "Memory Usage (human-readable)"
    run_command "cat /proc/meminfo | grep -E 'MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapCached|SwapTotal|SwapFree'" false "Detailed Memory Information"
    
    # 1.6 Hardware Information
    print_subsection "1.6 Hardware Information"
    run_command "lshw -short 2>/dev/null" true "Hardware List (requires root)" || echo "lshw not available or requires root privileges"
    run_command "lspci -v" true "PCI Devices (detailed)" || run_command "lspci" false "PCI Devices (basic)"
    run_command "lsusb -v 2>/dev/null" true "USB Devices (detailed)" || run_command "lsusb" false "USB Devices (basic)"
    
    # 1.7 System DMI Information
    print_subsection "1.7 DMI Information"
    if [ -x "$(command -v dmidecode)" ]; then
        run_command "dmidecode -t system" true "System DMI Information"
        run_command "dmidecode -t baseboard" true "Baseboard/Motherboard Information"
        run_command "dmidecode -t bios" true "BIOS Information"
    else
        echo "dmidecode not available (requires root)"
    fi
    
    # 1.8 Kernel Modules
    print_subsection "1.8 Kernel Modules"
    run_command "lsmod | sort" false "Loaded Kernel Modules"
    
    # 1.9 Kernel Parameters
    print_subsection "1.9 Kernel Parameters"
    run_command "cat /proc/cmdline" false "Kernel Command Line Parameters"
    
    # 1.10 System Clock and Timezone
    print_subsection "1.10 System Clock and Timezone"
    run_command "date" false "Current System Date and Time"
    run_command "timedatectl status" false "System Clock and Timezone Information"
    
    # 1.11 Last System Boot
    print_subsection "1.11 Last System Boot"
    run_command "who -b" false "Last System Boot Time"
    
    # 1.12 System Temperature (if sensors are available)
    print_subsection "1.12 System Temperature"
    if command -v sensors &> /dev/null; then
        run_command "sensors" false "System Temperature Sensors"
    else
        echo "lm-sensors package not installed. Install with 'apt install lm-sensors' or 'yum install lm_sensors'"
    fi
    
    # Section 2: Disk & Filesystem Information
    print_header "2. DISK & FILESYSTEM INFORMATION"
    
    # 2.1 Disk Usage
    print_subsection "2.1 Disk Usage"
    run_command "df -hT -x tmpfs -x devtmpfs" false "Filesystem Disk Space Usage (human-readable)"
    run_command "df -i -x tmpfs -x devtmpfs" false "Filesystem Inode Usage"
    
    # 2.2 Block Devices and Partitions
    print_subsection "2.2 Block Devices and Partitions"
    if command -v lsblk &> /dev/null; then
        run_command "lsblk -o NAME,FSTYPE,SIZE,TYPE,MOUNTPOINT,UUID,PARTUUID,MODEL,SERIAL" false "Block Devices and Partitions"
        run_command "lsblk -t" false "Block Devices Topology"
    else
        run_command "fdisk -l 2>/dev/null" true "Disk Partition Table (requires root)" || \
            echo "fdisk not available or requires root privileges"
    fi
    
    # 2.3 Mounted Filesystems
    print_subsection "2.3 Mounted Filesystems"
    run_command "mount | sort" false "Currently Mounted Filesystems"
    run_command "cat /proc/mounts | sort" false "Mounted Filesystems (from /proc/mounts)"
    
    # 2.4 Filesystem Details
    print_subsection "2.4 Filesystem Details"
    if [ -f "/etc/fstab" ]; then
        get_file_content "/etc/fstab"
    else
        echo "/etc/fstab not found"
    fi
    
    # 2.5 LVM Information (if LVM is used)
    print_subsection "2.5 LVM Information"
    if command -v pvs &> /dev/null; then
        run_command "pvs" true "Physical Volumes"
        run_command "vgs" true "Volume Groups"
        run_command "lvs" true "Logical Volumes"
        run_command "pvdisplay" true "Physical Volume Details"
        run_command "vgdisplay" true "Volume Group Details"
        run_command "lvdisplay" true "Logical Volume Details"
    else
        echo "LVM tools not found. Install with 'apt install lvm2' or 'yum install lvm2'"
    fi
    
    # 2.6 Disk I/O Statistics
    print_subsection "2.6 Disk I/O Statistics"
    if command -v iostat &> /dev/null; then
        run_command "iostat -x 1 3" false "Extended I/O Statistics (3 samples)"
    else
        echo "iostat not available. Install with 'apt install sysstat' or 'yum install sysstat'"
    fi
    
    # 2.7 Disk S.M.A.R.T. Status (if available)
    print_subsection "2.7 Disk S.M.A.R.T. Status"
    if command -v smartctl &> /dev/null; then
        echo "Checking S.M.A.R.T. status for all disks (this may take a while)..."
        for disk in $(lsblk -d -o NAME -n); do
            if [ -e "/dev/${disk}" ] && [ "$(smartctl -i /dev/${disk} 2>&1 | grep -c 'Device supports SMART')" -gt 0 ]; then
                run_command "smartctl -H /dev/${disk}" true "S.M.A.R.T. Health for /dev/${disk}"
                run_command "smartctl -A /dev/${disk}" true "S.M.A.R.T. Attributes for /dev/${disk}"
            fi
        done
    else
        echo "smartmontools not installed. Install with 'apt install smartmontools' or 'yum install smartmontools'"
    fi
    
    # 2.8 Disk Space Usage by Directory
    print_subsection "2.8 Disk Space Usage by Directory"
    run_command "du -h --max-depth=1 / 2>/dev/null | sort -hr" true "Disk Usage in / (top level directories)" || \
        echo "Could not calculate disk usage (requires root for some directories)"
    
    # Section 3: Network Information
    print_header "3. NETWORK INFORMATION"
    
    # 3.1 Network Interfaces
    print_subsection "3.1 Network Interfaces"
    if command -v ip &> /dev/null; then
        run_command "ip -4 -o addr" false "IPv4 Addresses"
        run_command "ip -6 -o addr" false "IPv6 Addresses"
        run_command "ip -s link" false "Network Interface Statistics"
    else
        run_command "ifconfig -a" false "Network Interfaces (ifconfig)"
    fi
    
    # 3.2 Routing Information
    print_subsection "3.2 Routing Information"
    if command -v ip &> /dev/null; then
        run_command "ip route" false "IP Routing Table"
        run_command "ip -6 route" false "IPv6 Routing Table"
    else
        run_command "route -n" false "Routing Table (route -n)"
        run_command "route -6 -n" false "IPv6 Routing Table"
    fi
    run_command "netstat -rn" false "Routing Table (netstat -rn)"
    
    # 3.3 Network Connections
    print_subsection "3.3 Network Connections"
    if command -v ss &> /dev/null; then
        run_command "ss -tulnp" false "Listening Sockets (ss)"
        run_command "ss -tan" false "All TCP Connections (ss)"
        run_command "ss -uan" false "All UDP Connections (ss)"
        run_command "ss -s" false "Socket Statistics (ss)"
    else
        run_command "netstat -tulnp" false "Listening Sockets (netstat)"
        run_command "netstat -tan" false "All TCP Connections (netstat)"
        run_command "netstat -uan" false "All UDP Connections (netstat)"
        run_command "netstat -s" false "Network Statistics (netstat)"
    fi
    
    # 3.4 DNS Configuration
    print_subsection "3.4 DNS Configuration"
    if [ -f "/etc/resolv.conf" ]; then
        get_file_content "/etc/resolv.conf"
    else
        echo "/etc/resolv.conf not found"
    fi
    
    if [ -f "/etc/hosts" ]; then
        get_file_content "/etc/hosts"
    else
        echo "/etc/hosts not found"
    fi
    
    if [ -f "/etc/nsswitch.conf" ]; then
        get_file_content "/etc/nsswitch.conf"
    fi
    
    run_command "cat /etc/hostname 2>/dev/null || hostname" false "Hostname Configuration"
    
    # 3.5 Network Time Synchronization
    print_subsection "3.5 Network Time Synchronization"
    if command -v timedatectl &> /dev/null; then
        run_command "timedatectl status" false "Time and Date Status"
    fi
    
    if systemctl is-active --quiet chronyd || systemctl is-active --quiet ntpd; then
        run_command "chronyc tracking 2>/dev/null || ntpq -p 2>/dev/null || ntpstat" false "NTP Status"
    else
        echo "No active NTP service detected"
    fi
    
    # 3.6 Network Manager Configuration
    print_subsection "3.6 Network Manager Configuration"
    if command -v nmcli &> /dev/null; then
        run_command "nmcli general status" false "NetworkManager General Status"
        run_command "nmcli connection show" false "NetworkManager Connections"
        run_command "nmcli device status" false "NetworkManager Devices"
    fi
    
    # 3.7 Firewall Status
    print_subsection "3.7 Firewall Status"
    if command -v ufw &> /dev/null; then
        run_command "ufw status verbose" true "UFW Firewall Status"
    elif command -v firewall-cmd &> /dev/null; then
        run_command "firewall-cmd --state" true "Firewalld State"
        run_command "firewall-cmd --list-all" true "Firewalld Configuration"
    fi
    
    # 3.8 IPTables Rules (if available)
    print_subsection "3.8 IPTables Rules"
    if command -v iptables &> /dev/null; then
        run_command "iptables -L -n -v --line-numbers" true "IPv4 Firewall Rules"
        run_command "iptables -t nat -L -n -v --line-numbers" true "IPv4 NAT Rules"
        run_command "iptables -t mangle -L -n -v --line-numbers" true "IPv4 Mangle Table"
        
        if command -v ip6tables &> /dev/null; then
            run_command "ip6tables -L -n -v --line-numbers" true "IPv6 Firewall Rules"
        fi
    else
        echo "iptables not available"
    fi
    
    # 3.9 Network Interface Bonding (if configured)
    print_subsection "3.9 Network Bonding"
    if [ -d "/proc/net/bonding" ]; then
        for bond in /proc/net/bonding/bond*; do
            if [ -f "$bond" ]; then
                run_command "cat $bond" false "Bond Interface: $(basename $bond)"
            fi
        done
    else
        echo "No bonding interfaces detected"
    fi
    
    # 3.10 Network Bridge Configuration
    print_subsection "3.10 Network Bridge Configuration"
    if command -v brctl &> /dev/null; then
        run_command "brctl show" false "Bridge Information"
    fi
    
    # 3.11 Network Tuning Parameters
    print_subsection "3.11 Network Tuning Parameters"
    run_command "sysctl -a 2>/dev/null | grep -E 'net\.ipv4\.|net\.ipv6\.|net\.core\.|net\.filter\.' | sort" false "Network Kernel Parameters"
    
    # 3.12 Network Statistics
    print_subsection "3.12 Network Statistics"
    run_command "netstat -i" false "Network Interface Table"
    run_command "netstat -s" false "Network Statistics"
    
    if [ -f "/proc/net/dev" ]; then
        run_command "cat /proc/net/dev" false "Network Device Statistics"
    fi
    
    if [ -f "/proc/net/snmp" ]; then
        run_command "cat /proc/net/snmp" false "IP, ICMP, TCP, and UDP Statistics"
    fi
    
    # Section 4: System Performance & Resource Usage
    print_header "4. SYSTEM PERFORMANCE & RESOURCE USAGE"
    
    # 4.1 System Load and CPU Usage
    print_subsection "4.1 System Load and CPU Usage"
    run_command "uptime" false "System Load Averages"
    run_command "mpstat -P ALL 1 3" false "CPU Usage Statistics (3 samples)" || \
        echo "sysstat package not installed. Install with 'apt install sysstat' or 'yum install sysstat'"
    run_command "sar -u 1 3" false "CPU Utilization (3 samples)" || \
        echo "sar command not available (part of sysstat package)"
    run_command "top -b -n 1 | head -n 20" false "Top Processes by CPU Usage"
    
    # 4.2 Memory Usage and Analysis
    print_subsection "4.2 Memory Usage and Analysis"
    run_command "free -m" false "Memory Usage in MB"
    run_command "vmstat 1 3" false "Virtual Memory Statistics (3 samples)"
    run_command "slabtop -o -s c | head -n 20" true "Kernel SLAB/SLUB Info (top 20)" || \
        echo "slabtop not available. Install with 'apt install procps' or 'yum install procps-ng'"
    run_command "ps aux --sort=-%mem | head -n 10" false "Top 10 Processes by Memory Usage"
    
    # 4.3 Disk I/O Performance
    print_subsection "4.3 Disk I/O Performance"
    run_command "iostat -x 1 3" false "Extended I/O Statistics (3 samples)" || \
        echo "iostat not available (part of sysstat package)"
    run_command "iotop -o -b -n 1 | head -n 15" true "Top I/O Processes" || \
        echo "iotop not installed. Install with 'apt install iotop' or 'yum install iotop'"
    run_command "dmesg | grep -i 'error\|warn\|fail\|timeout\|dropped\|reject' | tail -n 20" true "Recent Kernel Errors/Warnings"
    
    # 4.4 Process and Resource Limits
    print_subsection "4.4 Process and Resource Limits"
    run_command "ulimit -a" false "Current User Process Limits"
    run_command "ps -eo pid,ppid,user,%cpu,%mem,cmd --sort=-%cpu | head -n 15" false "Top CPU-consuming Processes"
    run_command "ps -eo pid,ppid,user,%cpu,%mem,cmd --sort=-%mem | head -n 15" false "Top Memory-consuming Processes"
    
    # 4.5 System Logs and Messages
    print_subsection "4.5 System Logs and Messages"
    if [ -f "/var/log/syslog" ]; then
        run_command "tail -n 50 /var/log/syslog" true "Recent System Logs"
    elif [ -f "/var/log/messages" ]; then
        run_command "tail -n 50 /var/log/messages" true "Recent System Messages"
    fi
    
    if [ -f "/var/log/dmesg" ]; then
        run_command "tail -n 30 /var/log/dmesg" true "Recent Kernel Messages"
    else
        run_command "dmesg | tail -n 30" true "Recent Kernel Messages (from dmesg)"
    fi
    
    # 4.6 System Resource Usage Summary
    print_subsection "4.6 System Resource Usage Summary"
    run_command "ps -eo pcpu,pmem,pid,user,args | sort -k 1 -r | head -n 10" false "Top 10 Processes by CPU and Memory"
    run_command "df -h" false "Filesystem Disk Space Usage"
    run_command "du -sh /var/log/ 2>/dev/null || echo 'Could not calculate /var/log/ size'" true "/var/log/ Directory Size"
    
    # Section 5: Process & Performance Information
    print_header "5. PROCESS & PERFORMANCE INFORMATION"
    
    # 5.1 Process List and Statistics
    print_subsection "5.1 Process List and Statistics"
    run_command "ps auxf" false "Detailed Process List"
    run_command "pstree -p -n" false "Process Tree"
    run_command "ps -eo pid,ppid,user,pcpu,pmem,cmd --sort=-pcpu | head -n 15" false "Top CPU-consuming Processes"
    run_command "ps -eo pid,ppid,user,pcpu,pmem,cmd --sort=-pmem | head -n 15" false "Top Memory-consuming Processes"
    run_command "ps -eo pid,ppid,user,stat,start,cmd | head -n 15" false "Process Status and Start Time"
    
    # 5.2 Process Resource Usage
    print_subsection "5.2 Process Resource Usage"
    if command -v pidstat &> /dev/null; then
        run_command "pidstat -dlrsu 1 3" false "Process Statistics (3 samples)"
    else
        echo "pidstat not available (part of sysstat package)"
    fi
    
    run_command "lsof -i -P -n | head -n 20" true "Open Network Connections and Files (top 20)" || \
        echo "lsof not available or requires elevated privileges"
    
    # 5.3 System Call Statistics
    print_subsection "5.3 System Call Statistics"
    if command -v strace &> /dev/null; then
        run_command "strace -c -f -S name -p 1 2>&1 | head -n 20" true "System Calls by PID 1 (requires root)" || \
            echo "strace not available or requires root privileges"
    else
        echo "strace not installed. Install with 'apt install strace' or 'yum install strace'"
    fi
    
    # 5.4 Process Limits and Capabilities
    print_subsection "5.4 Process Limits and Capabilities"
    run_command "ulimit -a" false "Current User Process Limits"
    
    if command -v getcap &> /dev/null; then
        run_command "getcap -r / 2>/dev/null | head -n 20" true "Files with Capabilities (top 20, requires root)" || \
            echo "Could not list file capabilities (requires root)"
    else
        echo "getcap not available. Install with 'apt install libcap2-bin' or 'yum install libcap-ng-utils'"
    fi
    
    # 5.5 System Performance Metrics
    print_subsection "5.5 System Performance Metrics"
    run_command "vmstat 1 3" false "Virtual Memory Statistics"
    run_command "mpstat -P ALL 1 3" false "CPU Statistics (3 samples)" || \
        echo "mpstat not available (part of sysstat package)"
    run_command "iostat -xz 1 3" false "Extended I/O Statistics (3 samples)" || \
        echo "iostat not available (part of sysstat package)"
    
    # 5.6 System Logs for Performance Issues
    print_subsection "5.6 Performance-related System Logs"
    if [ -f "/var/log/kern.log" ]; then
        run_command "grep -i -E 'error|warn|fail|oom|throttl|latency|timeout' /var/log/kern.log | tail -n 20" true "Recent Kernel Log Entries"
    elif [ -f "/var/log/messages" ]; then
        run_command "grep -i -E 'error|warn|fail|oom|throttl|latency|timeout' /var/log/messages | tail -n 20" true "Recent System Messages"
    fi
    
    # 5.7 Systemd Service Status
    print_subsection "5.7 Systemd Service Status"
    if command -v systemctl &> /dev/null; then
        run_command "systemctl list-units --type=service --state=failed" false "Failed System Services"
        run_command "systemctl list-timers --all" false "Systemd Timers"
        run_command "systemd-analyze blame | head -n 10" true "Slowest Starting Services"
        run_command "systemd-analyze critical-chain" true "Critical Startup Chain"
    fi
    
    # 5.8 Process Environment
    print_subsection "5.8 Process Environment"
    run_command "env | sort" false "Current Environment Variables"
    
    # 5.9 System Resource Usage Summary
    print_subsection "5.9 System Resource Usage Summary"
    run_command "top -b -n 1 | head -n 20" false "System Resource Usage (top)"
    
    if command -v htop &> /dev/null; then
        run_command "htop -n 1 | head -n 20" false "Interactive Process Viewer (htop)"
    else
        echo "htop not installed. Install with 'apt install htop' or 'yum install htop'"
    fi
}

# Execute main function
main "$@"

echo -e "\n${COLOR_GREEN}=== System information collection completed ===${COLOR_RESET}"
