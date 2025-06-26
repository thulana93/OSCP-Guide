#!/bin/bash

# Manual Linux PrivEsc Enumeration Script
# Author: Thulana Abeywardana
# Safe to run in most environments; no exploit attempts.

output="enum_output.txt"
> "$output"

section() {
  echo -e "\n========== $1 ==========\n" | tee -a "$output"
}

cmd() {
  echo "[*] $1" | tee -a "$output"
  eval "$1" 2>/dev/null | tee -a "$output"
  echo | tee -a "$output"
}

section "USER INFORMATION"
cmd "whoami"
cmd "id"
cmd "groups"
cmd "sudo -l"

section "OS AND KERNEL"
cmd "cat /etc/os-release"
cmd "uname -a"
cmd "cat /proc/version"

section "ENVIRONMENT VARIABLES"
cmd "echo \$PATH"
cmd "env"

section "RUNNING PROCESSES AND SERVICES"
cmd "ps aux"
cmd "ss -tuln"
cmd "netstat -tulnp"

section "INSTALLED SHELLS"
cmd "cat /etc/shells"

section "CPU AND ARCHITECTURE"
cmd "lscpu"

section "SECURITY MECHANISMS"
cmd "sestatus"
cmd "aa-status"
cmd "ufw status"
cmd "iptables -L"

section "FILESYSTEM AND MOUNTS"
cmd "lsblk"
cmd "df -h"
cmd "cat /etc/fstab | column -t | grep -v '^#'"
cmd "mount"

section "NETWORK CONFIGURATION"
cmd "ip a"
cmd "ip route"
cmd "cat /etc/resolv.conf"
cmd "arp -a"

section "USER ENUMERATION"
cmd "cat /etc/passwd"
cmd "grep 'sh$' /etc/passwd"
cmd "cat /etc/group"
cmd "getent group sudo"
cmd "ls /home"

section "SUID/SGID/WRITABLE FILES (May take time)"
cmd "find / -perm -4000 -type f 2>/dev/null"
cmd "find / -perm -2000 -type f 2>/dev/null"
cmd "find / -writable -type d 2>/dev/null"

section "SENSITIVE FILE HUNTING"
cmd "find / -type f -name '.*' 2>/dev/null"
cmd "find / -name '*.conf' -o -name '*.config' 2>/dev/null"
cmd "grep -rEi 'pass|pwd|secret' /home/* 2>/dev/null"

section "TMP AND SHARED MEMORY"
cmd "ls -la /tmp"
cmd "ls -la /var/tmp"
cmd "ls -la /dev/shm"

section "CRON JOBS"
cmd "crontab -l"
cmd "ls -la /etc/cron*"

section "LAST LOGINS AND HISTORY"
cmd "last -a | head"
cmd "cat ~/.bash_history"

echo -e "\n[*] Script completed. Output saved to $output"
