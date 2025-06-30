#!/bin/bash

############################################################
# Author: Ashutosh Patole
# Version: 0.1
# Description: Get all your system information in one place
############################################################


# shell check options
set -euo pipefail


print_header(){
echo "####################################################################"
echo "# $1"
echo "####################################################################"
}


print_header "General System Information"
echo 

cat /etc/os-release

echo 

print_header "Security"
