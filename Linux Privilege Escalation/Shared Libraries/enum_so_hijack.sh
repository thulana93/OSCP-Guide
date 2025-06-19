#!/bin/bash

echo "[*] Enumerating SUID binaries..."
suid_bins=$(find / -perm -4000 -type f 2>/dev/null)

for bin in $suid_bins; do
    echo -e "\n[+] Checking binary: $bin"

    echo "[*] 1. Checking shared libraries with ldd..."
    ldd_output=$(ldd "$bin" 2>/dev/null)

    echo "$ldd_output" | grep "=>"

    # Identify suspicious paths
    echo "[*] 2. Searching for non-standard library paths..."
    echo "$ldd_output" | grep "=>" | awk '{print $3}' | grep -Ev '^/lib|^/usr|^/lib64|^/etc|^/snap|^\(0x' | while read libpath; do
        if [ -n "$libpath" ]; then
            echo "  [-] Suspicious lib path: $libpath"
            dirpath=$(dirname "$libpath")

            echo "      [+] Checking if $dirpath is writable..."
            [ -w "$dirpath" ] && echo "      [!!!] Writable! Possible hijack via $libpath" || echo "      [-] Not writable."
        fi
    done

    echo "[*] 3. Checking RUNPATH/RPATH..."
    runpath=$(readelf -d "$bin" 2>/dev/null | grep -E 'RPATH|RUNPATH')

    if [[ -n "$runpath" ]]; then
        echo "$runpath"
        # Extract path and test for writability
        echo "$runpath" | grep -oP '\[.*?\]' | tr -d '[]' | tr ':' '\n' | while read path; do
            echo "  [+] Checking if $path is writable..."
            [ -w "$path" ] && echo "      [!!!] Writable! Vulnerable RUNPATH" || echo "      [-] Not writable."
        done
    else
        echo "  [-] No RUNPATH or RPATH found."
    fi

    echo "[*] 4. Looking for suspicious symbol references..."
    strings "$bin" | grep -E 'connect|query|load|init|auth|db|log|debug' | uniq | head -n 10

    echo "------------------------------------------------------"
done
