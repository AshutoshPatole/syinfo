# System Information Tool (sysinfo.sh)

A comprehensive system information and diagnostics script for Linux systems. This tool collects detailed system configuration, performance metrics, and security information in an organized, easy-to-read format.

## Features

- **System Overview**: Hardware details, CPU, memory, and kernel information
- **Disk & Filesystem**: Storage devices, partitions, mount points, and usage
- **Network Configuration**: Interfaces, routing, connections, and firewall status
- **Performance Metrics**: CPU, memory, and I/O statistics
- **Process Information**: Running processes, resource usage, and systemd services
- **Log Analysis**: System logs and error messages
- **Security**: User accounts, sudo privileges, and open ports

## Installation

### Quick Install (Recommended)

```bash
# Download and run the installer
curl -sSL https://raw.githubusercontent.com/AshutoshPatole/syinfo/main/install.sh | sudo bash
```

Or using wget:

```bash
wget -qO- https://raw.githubusercontent.com/AshutoshPatole/syinfo/main/install.sh | sudo bash
```

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/AshutoshPatole/syinfo.git
   cd sysinfo
   ```

2. Make the script executable:
   ```bash
   chmod +x sysinfo.sh
   ```

3. Run directly:
   ```bash
   sudo ./sysinfo.sh
   ```

   Or install system-wide:
   ```bash
   sudo cp sysinfo.sh /usr/local/bin/sysinfo
   sudo chmod +x /usr/local/bin/sysinfo
   ```

## Usage

```bash
# Basic usage
sudo sysinfo

# Save output to a file
sudo sysinfo > system_report_$(date +%Y%m%d).log

# View specific section (e.g., network)
sudo sysinfo | grep -A 100 "3. NETWORK INFORMATION" | less
```

## Sections

1. **General System & Hardware Overview**
   - System information and hostname
   - CPU and memory details
   - Hardware information and DMI data
   - Kernel modules and parameters

2. **Disk & Filesystem Information**
   - Disk usage and partitions
   - Mounted filesystems
   - LVM configuration (if used)
   - S.M.A.R.T. status (if available)

3. **Network Information**
   - Network interfaces and IP addresses
   - Routing tables and connections
   - DNS configuration
   - Firewall status and rules

4. **System Performance & Resource Usage**
   - CPU and memory usage
   - Process statistics
   - System load and performance metrics

5. **Process & Performance Information**
   - Running processes
   - Resource limits
   - Systemd service status
   - Performance logs

## Dependencies

The script has minimal dependencies and will work on most Linux distributions. Some features may require additional packages:

```bash
# For full functionality on Debian/Ubuntu
sudo apt update && sudo apt install -y lshw pciutils usbutools dmidecode sysstat lvm2 smartmontools

# For full functionality on RHEL/CentOS
sudo yum install -y lshw pciutils usbutools dmidecode sysstat lvm2 smartmontools
```

## Output Example

```
=== System Diagnostics Report ===
Generated on: 2025-06-30 17:45:00 UTC
Running as: root
Hostname: example-server
Kernel: Linux 5.4.0-135-generic x86_64 GNU/Linux

####################################################################
# 1. GENERAL SYSTEM & HARDWARE OVERVIEW
####################################################################

--- 1.1 System Information ---
...
```

## Security Note

This script requires root privileges to collect all system information. Review the script before running it with elevated privileges.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Author

- **Ashutosh Patole** - [GitHub](https://github.com/AshutoshPatole)

