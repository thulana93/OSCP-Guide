#!/bin/bash

echo "========== PYTHON LIBRARY HIJACK SCANNER =========="
echo

# Detect Python3 binary
PYTHON_BIN=$(which python3)
if [[ -z "$PYTHON_BIN" ]]; then
  echo "[!] Python3 not found."
  exit 1
fi
echo "[+] Python binary found: $PYTHON_BIN"

echo
echo "========== [1] Scanning for WRITABLE MODULE FILES =========="

MODULE_PATHS=$(python3 -c "import sys; print('\n'.join(sys.path))")

for path in $MODULE_PATHS; do
  if [[ -d "$path" ]]; then
    echo "[*] Checking: $path"
    find "$path" -type f -name "*.py" -writable 2>/dev/null
  fi
done

echo
echo "========== [2] Scanning for WRITABLE DIRECTORIES in sys.path =========="

for path in $MODULE_PATHS; do
  if [[ -d "$path" ]]; then
    if [[ -w "$path" ]]; then
      echo "[+] Writable sys.path directory found: $path"
    fi
  fi
done

echo
echo "========== [3] Checking for PYTHON3 SUDO SETENV Permission =========="

SUDO_LIST=$(sudo -l 2>/dev/null)
if echo "$SUDO_LIST" | grep -q "SETENV"; then
  if echo "$SUDO_LIST" | grep -q "$PYTHON_BIN"; then
    echo "[+] Sudo permission with SETENV found for Python: $PYTHON_BIN"
    echo
    echo "[*] You can potentially exploit PYTHONPATH variable:"
    echo "    sudo PYTHONPATH=/tmp $PYTHON_BIN your_script.py"
  else
    echo "[-] SETENV present but not for Python specifically."
  fi
else
  echo "[-] No SETENV sudo permission detected for this user."
fi

echo
echo "========== SCAN COMPLETE =========="
