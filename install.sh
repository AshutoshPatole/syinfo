#!/bin/bash

############################################################
# Install Script for sysinfo.sh
# Description: Downloads and installs sysinfo.sh to /usr/local/bin
# Usage: sudo ./install.sh
############################################################

# ANSI color codes for better readability
COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_BLUE='\033[0;34m'
COLOR_RESET='\033[0m'

# Script information
SCRIPT_NAME="sysinfo.sh"
INSTALL_DIR="/usr/local/bin"
INSTALL_PATH="${INSTALL_DIR}/${SCRIPT_NAME}"
REPO_RAW_URL="https://raw.githubusercontent.com/AshutoshPatole/syinfo/main/sysinfo.sh"

# Function to print colored messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${COLOR_RESET}"
}

# Function to check if running with root privileges
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        print_message "${COLOR_RED}" "Error: This script must be run as root. Use 'sudo $0'"
        exit 1
    fi
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install dependencies
install_dependencies() {
    print_message "${COLOR_BLUE}" "Checking for required dependencies..."
    
    # Check for curl or wget
    if ! command_exists curl && ! command_exists wget; then
        print_message "${COLOR_YELLOW}" "Neither curl nor wget found. Installing curl..."
        if command_exists apt-get; then
            apt-get update && apt-get install -y curl
        elif command_exists yum; then
            yum install -y curl
        elif command_exists dnf; then
            dnf install -y curl
        else
            print_message "${COLOR_RED}" "Could not install curl. Please install curl or wget manually and try again."
            exit 1
        fi
    fi
    
    # Check for other common dependencies
    local missing_deps=()
    for dep in lscpu lshw lspci lsusb dmidecode; do
        if ! command_exists "$dep"; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        print_message "${COLOR_YELLOW}" "The following recommended tools are not installed: ${missing_deps[*]}"
        read -p "Do you want to install them? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            if command_exists apt-get; then
                apt-get update && apt-get install -y "${missing_deps[@]}"
            elif command_exists yum; then
                yum install -y "${missing_deps[@]}"
            elif command_exists dnf; then
                dnf install -y "${missing_deps[@]}"
            else
                print_message "${COLOR_YELLOW}" "Could not determine package manager. Please install the following packages manually: ${missing_deps[*]}"
            fi
        fi
    fi
}

# Function to download the script
download_script() {
    local temp_file
    temp_file=$(mktemp)
    
    print_message "${COLOR_BLUE}" "Downloading ${SCRIPT_NAME}..."
    
    if command_exists curl; then
        if ! curl -sSL "$REPO_RAW_URL" -o "$temp_file"; then
            print_message "${COLOR_RED}" "Failed to download ${SCRIPT_NAME} using curl"
            return 1
        fi
    elif command_exists wget; then
        if ! wget -q "$REPO_RAW_URL" -O "$temp_file"; then
            print_message "${COLOR_RED}" "Failed to download ${SCRIPT_NAME} using wget"
            return 1
        fi
    else
        print_message "${COLOR_RED}" "Neither curl nor wget is available. Please install one of them and try again."
        return 1
    fi
    
    # Verify the downloaded script
    if [ ! -s "$temp_file" ]; then
        print_message "${COLOR_RED}" "Downloaded file is empty"
        return 1
    fi
    
    # Check if the file starts with a shebang
    if ! head -n 1 "$temp_file" | grep -q '^#!/bin/bash'; then
        print_message "${COLOR_RED}" "Downloaded file doesn't appear to be a valid shell script"
        return 1
    fi
    
    echo "$temp_file"
    return 0
}

# Function to install the script
install_script() {
    local temp_file=$1
    
    # Create target directory if it doesn't exist
    mkdir -p "$INSTALL_DIR"
    
    # Install the script
    if ! install -m 755 "$temp_file" "$INSTALL_PATH"; then
        print_message "${COLOR_RED}" "Failed to install ${SCRIPT_NAME} to ${INSTALL_PATH}"
        return 1
    fi
    
    # Clean up
    rm -f "$temp_file"
    
    return 0
}

# Main function
main() {
    print_message "${COLOR_BLUE}" "=== ${SCRIPT_NAME} Installation ==="
    
    # Check if running as root
    check_root
    
    # Install dependencies
    install_dependencies
    
    # Download the script
    local temp_file
    temp_file=$(download_script) || exit 1
    
    # Install the script
    if install_script "$temp_file"; then
        print_message "${COLOR_GREEN}" "\n${SCRIPT_NAME} has been successfully installed to ${INSTALL_PATH}"
        print_message "${COLOR_GREEN}" "You can now run it by typing '${SCRIPT_NAME}' in your terminal"
        
        # Check if /usr/local/bin is in the PATH
        if ! echo "$PATH" | grep -q ":${INSTALL_DIR}:" && ! echo "$PATH" | grep -q "^${INSTALL_DIR}:" && ! echo "$PATH" | grep -q ":${INSTALL_DIR}$"; then
            print_message "${COLOR_YELLOW}" "\nNote: ${INSTALL_DIR} is not in your PATH. You may need to add it to your PATH environment variable or use the full path to run the script."
        fi
    else
        print_message "${COLOR_RED}" "\nInstallation failed"
        exit 1
    fi
}

# Execute main function
main "$@"

exit 0
