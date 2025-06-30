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
}

# Execute main function
main "$@"

echo -e "\n${COLOR_GREEN}=== System information collection completed ===${COLOR_RESET}"
