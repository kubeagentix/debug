#!/bin/bash
# KubeAgentiX Debug Container - Shell Configuration
# This file is loaded when bash starts interactively

# -----------------------------------------------------------------------------
# Colors
# -----------------------------------------------------------------------------
CYAN='\033[0;36m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
WHITE='\033[1;37m'
DIM='\033[2m'
RESET='\033[0m'

# -----------------------------------------------------------------------------
# ASCII Art Banner
# -----------------------------------------------------------------------------
show_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'

  _  __      _           _                    _   _  __  __
 | |/ /     | |         / \   __ _  ___ _ __ | |_(_) \ \/ /
 | ' / _   _| |__   ___/ _ \ / _` |/ _ \ '_ \| __| |  \  /
 | . \| | | | '_ \ / _ / ___ \ (_| |  __/ | | | |_| |  /  \
 |_|\_\_,_,_|_.__/\___/_/   \_\__, |\___|_| |_|\__|_| /_/\_\
                              |___/
EOF
    echo -e "${RESET}"

    # Debug Mode indicator
    echo -e "${WHITE}  ===========================================${RESET}"
    echo -e "${GREEN}             DEBUG MODE ACTIVE${RESET}"
    echo -e "${WHITE}  ===========================================${RESET}"
    echo ""

    # System info
    echo -e "  ${DIM}Container:${RESET}  ${YELLOW}KubeAgentiX Debug v${KUBEAGENTIX_VERSION:-1.0}${RESET}"
    echo -e "  ${DIM}User:${RESET}       ${CYAN}$(whoami)${RESET}"
    echo -e "  ${DIM}Shell:${RESET}      ${CYAN}${SHELL}${RESET}"
    echo -e "  ${DIM}Hostname:${RESET}   ${CYAN}$(hostname 2>/dev/null || echo 'unknown')${RESET}"
    echo ""

    # Available tools
    echo -e "  ${WHITE}Available Tools:${RESET}"
    echo -e "  ${DIM}Network:${RESET}    curl, wget, dig, nslookup, nc, mtr, traceroute"
    echo -e "  ${DIM}Process:${RESET}    ps, htop, top"
    echo -e "  ${DIM}Files:${RESET}      find, tree, less, file"
    echo -e "  ${DIM}Data:${RESET}       jq, yq"
    echo -e "  ${DIM}TLS:${RESET}        openssl"
    echo ""
    echo -e "  ${DIM}Type 'help-debug' for common debugging commands${RESET}"
    echo -e "${WHITE}  ===========================================${RESET}"
    echo ""
}

# -----------------------------------------------------------------------------
# Help function for common debug commands
# -----------------------------------------------------------------------------
help-debug() {
    echo -e "${CYAN}KubeAgentiX Debug - Quick Reference${RESET}"
    echo ""
    echo -e "${WHITE}Network Diagnostics:${RESET}"
    echo "  curl -v <url>              # HTTP request with verbose output"
    echo "  dig <domain>               # DNS lookup"
    echo "  nslookup <domain>          # DNS resolution"
    echo "  nc -zv <host> <port>       # Test TCP connectivity"
    echo "  mtr <host>                 # Network path analysis"
    echo ""
    echo -e "${WHITE}Kubernetes Service Discovery:${RESET}"
    echo "  dig kubernetes.default.svc.cluster.local"
    echo "  curl -k https://kubernetes.default.svc/api"
    echo "  cat /etc/resolv.conf       # Check DNS config"
    echo ""
    echo -e "${WHITE}Process Inspection:${RESET}"
    echo "  ps aux                     # List all processes"
    echo "  htop                       # Interactive process viewer"
    echo "  cat /proc/<pid>/environ    # Process environment"
    echo ""
    echo -e "${WHITE}File System:${RESET}"
    echo "  tree -L 2 /                # Directory structure"
    echo "  find / -name '*.conf'      # Find config files"
    echo "  df -h                      # Disk usage"
    echo ""
    echo -e "${WHITE}JSON/YAML Processing:${RESET}"
    echo "  curl ... | jq '.'          # Pretty print JSON"
    echo "  cat file.yaml | yq '.'     # Parse YAML"
    echo ""
}

# -----------------------------------------------------------------------------
# Custom prompt
# -----------------------------------------------------------------------------
export PS1='\[\033[0;36m\]kubeagentix\[\033[0m\]:\[\033[0;33m\]\w\[\033[0m\]\$ '

# -----------------------------------------------------------------------------
# Bash settings
# -----------------------------------------------------------------------------
# Enable bash completion if available
if [ -f /etc/bash/bash_completion ]; then
    . /etc/bash/bash_completion
elif [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi

# Useful aliases
alias ll='ls -la'
alias la='ls -A'
alias l='ls -CF'
alias ..='cd ..'
alias ...='cd ../..'

# Make less more friendly for non-text input files
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# -----------------------------------------------------------------------------
# Show banner on login (only for interactive shells)
# -----------------------------------------------------------------------------
if [[ $- == *i* ]]; then
    show_banner
fi
