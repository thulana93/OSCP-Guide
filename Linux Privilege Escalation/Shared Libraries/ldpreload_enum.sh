#!/bin/bash

# Author: Thulana Abeywardana
# Purpose: Check if LD_PRELOAD can be used for privilege escalation via sudo

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No color

echo -e "${GREEN}[+] Starting LD_PRELOAD exploitability scan...${NC}"

# Step 1: Create test shared library
echo -e "${GREEN}[+] Creating test .so payload...${NC}"
cat <<EOF > /tmp/test_ldpreload.c
#include <stdio.h>
__attribute__((constructor)) void preload() {
    printf("✅ LD_PRELOAD injection successful!\\n");
}
EOF

gcc -fPIC -shared -o /tmp/test_ldpreload.so /tmp/test_ldpreload.c 2>/dev/null

if [ ! -f /tmp/test_ldpreload.so ]; then
    echo -e "${RED}[-] Failed to compile test shared library.${NC}"
    exit 1
fi

# Step 2: List sudo commands
echo -e "${GREEN}[+] Enumerating sudo permissions...${NC}"
SUDO_CMDS=$(sudo -l 2>/dev/null | grep -E 'NOPASSWD|PASSWD' | grep -oP '/[^\s]+')

if [ -z "$SUDO_CMDS" ]; then
    echo -e "${RED}[-] No sudo commands found or insufficient permissions.${NC}"
    exit 1
fi

# Step 3: Check each command
for CMD in $SUDO_CMDS; do
    echo -e "${GREEN}[*] Testing command: $CMD${NC}"

    # Is it dynamically linked?
    file $CMD | grep -q "dynamically linked"
    if [ $? -ne 0 ]; then
        echo -e "${RED}    [-] Not dynamically linked. Skipping.${NC}"
        continue
    else
        echo -e "${GREEN}    [+] Binary is dynamically linked.${NC}"
    fi

    # Is LD_PRELOAD stripped?
    echo -e "${GREEN}    [+] Checking if LD_PRELOAD is preserved...${NC}"
    sudo LD_PRELOAD=/tmp/test_ldpreload.so $CMD </dev/null 2>&1 | grep -q "LD_PRELOAD injection successful"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}    [!!!] LD_PRELOAD injection succeeded! This is potentially exploitable!${NC}"
    else
        echo -e "${RED}    [-] LD_PRELOAD was stripped or injection failed.${NC}"
    fi
done

# Cleanup
rm -f /tmp/test_ldpreload.*

echo -e "${GREEN}[+] Done.${NC}"
