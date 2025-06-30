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
    # Use mktemp to create a secure temporary file
    temp_file=$(mktemp 2>/dev/null || mktemp -t 'sysinfo')
    
    if [ -z "$temp_file" ] || [ ! -f "$temp_file" ]; then
        print_message "${COLOR_RED}" "Failed to create temporary file" >&2
        return 1
    fi
    
    # Clean up temp file if the script exits prematurely
    trap 'rm -f "$temp_file"' EXIT
    
    # Redirect this message to stderr
    print_message "${COLOR_BLUE}" "Downloading ${SCRIPT_NAME}..." >&2
    
    local download_success=false
    
    if command_exists curl; then
        if curl -sSL "$REPO_RAW_URL" -o "$temp_file" 2>/dev/null; then
            download_success=true
        fi
    elif command_exists wget; then
        if wget -q "$REPO_RAW_URL" -O "$temp_file" 2>/dev/null; then
            download_success=true
        fi
    else
        print_message "${COLOR_RED}" "Neither curl nor wget is available. Please install one of them and try again." >&2
        return 1
    fi
    
    if [ "$download_success" != true ]; then
        print_message "${COLOR_RED}" "Failed to download ${SCRIPT_NAME}" >&2
        return 1
    fi
    
    # Verify the downloaded script
    if [ ! -s "$temp_file" ]; then
        print_message "${COLOR_RED}" "Downloaded file is empty" >&2
        return 1
    fi
    
    # Check if the file starts with a shebang
    if ! head -n 1 "$temp_file" | grep -q '^#!/bin/bash'; then
        print_message "${COLOR_RED}" "Downloaded file doesn't appear to be a valid shell script" >&2
        return 1
    fi
    
    # Remove the trap as we're returning the temp file path, and install_script will clean it up
    trap - EXIT
    echo "$temp_file"
    return 0
}

# Function to install the script
install_script() {
    local temp_file="$1"
    
    # Verify temp file exists and is readable
    if [ ! -f "$temp_file" ] || [ ! -r "$temp_file" ]; then
        print_message "${COLOR_RED}" "Temporary file not found or not readable"
        return 1
    fi
    
    # Create target directory if it doesn't exist
    mkdir -p "$INSTALL_DIR" 2>/dev/null || {
        print_message "${COLOR_RED}" "Failed to create directory ${INSTALL_DIR}"
        return 1
    }
    
    # Check if we can write to the destination
    if [ ! -w "$INSTALL_DIR" ] && [ "$(id -u)" -ne 0 ]; then
        print_message "${COLOR_RED}" "No write permission to ${INSTALL_DIR}. Run with sudo."
        return 1
    fi
    
    # Create a backup if the file already exists
    if [ -f "$INSTALL_PATH" ]; then
        local backup_path="${INSTALL_PATH}.bak.$(date +%Y%m%d%H%M%S)"
        print_message "${COLOR_YELLOW}" "Backing up existing file to ${backup_path}"
        cp "$INSTALL_PATH" "$backup_path" 2>/dev/null || {
            print_message "${COLOR_YELLOW}" "Warning: Could not create backup of existing file"
        }
    fi
    
    # Install the script
    print_message "${COLOR_BLUE}" "Installing to ${INSTALL_PATH}"
    
    # Use cat instead of install for better error handling
    if ! cat "$temp_file" > "$INSTALL_PATH"; then
        print_message "${COLOR_RED}" "Failed to write to ${INSTALL_PATH}"
        return 1
    fi
    
    # Set executable permissions
    if ! chmod 755 "$INSTALL_PATH"; then
        print_message "${COLOR_RED}" "Failed to set executable permissions on ${INSTALL_PATH}"
        return 1
    fi
    
    # Verify the installed script
    if [ ! -x "$INSTALL_PATH" ]; then
        print_message "${COLOR_RED}" "Installed file is not executable"
        return 1
    fi
    
    # Clean up temp file
    rm -f "$temp_file" 2>/dev/null || true
    
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
