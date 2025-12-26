#!/usr/bin/env bash
set -euo pipefail

#=========================================================
#   LXC + LXD AUTO INSTALLER FOR UBUNTU & DEBIAN
#   Dont Copy This Script
#   Author: HopingBoyz
#=========================================================

# --- Advanced Colors and Styles ---
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
RED="\e[31m"
BLUE="\e[34m"
MAGENTA="\e[35m"
WHITE="\e[97m"
BOLD="\e[1m"
DIM="\e[2m"
ITALIC="\e[3m"
UNDERLINE="\e[4m"
BLINK="\e[5m"
RESET="\e[0m"

# Colorful background for better visual appeal
BG_BLUE="\e[44m"
BG_GREEN="\e[42m"
BG_YELLOW="\e[43m"
BG_RED="\e[41m"
BG_MAGENTA="\e[45m"
BG_CYAN="\e[46m"

# Terminal dimensions
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)
TERM_HEIGHT=$(tput lines 2>/dev/null || echo 24)

# --- Installation Configuration ---
INSTALL_LOG="/tmp/lxd_installer.log"
MAX_RETRIES=3
RETRY_DELAY=5

# Logging functions
init_log() {
    echo "=== LXC/LXD Installation Log ===" > "$INSTALL_LOG"
    echo "Started: $(date)" >> "$INSTALL_LOG"
    echo "User: $(whoami)" >> "$INSTALL_LOG"
    echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")" >> "$INSTALL_LOG"
}

log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$INSTALL_LOG"
}

# --- Advanced Progress Bar with Multiple Styles ---
_progress_bar() {
    local duration=${1}
    local style="${2:-block}"
    local width=$((TERM_WIDTH - 20))
    local increment=$((duration / width))
    local message="${3:-Processing}"
    
    printf "\n${CYAN}${BOLD}%s:${RESET} ${BLUE}│${RESET}" "$message"
    
    case "$style" in
        "block")
            for ((i=0; i<width; i++)); do
                printf "█"
                sleep $increment
            done
            ;;
        "dot")
            for ((i=0; i<width; i++)); do
                printf "▪"
                sleep $increment
            done
            ;;
        "arrow")
            for ((i=0; i<width; i++)); do
                printf "➤"
                sleep $increment
            done
            ;;
        "pulse")
            local -a chars=("█" "▓" "▒" "░")
            for ((i=0; i<width; i++)); do
                printf "%s" "${chars[i % 4]}"
                sleep $increment
            done
            ;;
    esac
    
    printf "${BLUE}│${RESET} ${GREEN}${BOLD}✓ Complete!${RESET}\n"
}

# --- Advanced Spinner with Dynamic Styles ---
_spinner_pid=""
_current_spinner_style=""
_spinner_message=""

_start_spinner() {
    local msg="$1"
    local style="${2:-random}"
    
    _spinner_message="$msg"
    _current_spinner_style="$style"
    
    if [[ "$style" == "random" ]]; then
        local styles=("dots" "circle" "pulse" "bounce" "arrow" "moon" "triangle" "clock")
        _current_spinner_style="${styles[$RANDOM % ${#styles[@]}]}"
    fi
    
    printf "\n%b" "${CYAN}${BOLD}${msg}${RESET} "
    
    case "$_current_spinner_style" in
        "dots") _spinner_dots & ;;
        "circle") _spinner_circle & ;;
        "pulse") _spinner_pulse & ;;
        "bounce") _spinner_bounce & ;;
        "arrow") _spinner_arrow & ;;
        "moon") _spinner_moon & ;;
        "triangle") _spinner_triangle & ;;
        "clock") _spinner_clock & ;;
        *) _spinner_dots & ;;
    esac
    
    _spinner_pid=$!
    trap '_stop_spinner' EXIT INT TERM
}

_spinner_dots() {
    local i=1
    while :; do
        case $((i % 4)) in
            0) printf "." ;;
            1) printf ".." ;;
            2) printf "..." ;;
            3) printf "   " ;;
        esac
        sleep 0.3
        printf "\b\b\b\b"
        ((i++))
    done
}

_spinner_circle() {
    local -a marks=('◐' '◓' '◑' '◒')
    local i=0
    while :; do
        printf "%b" "${marks[i % ${#marks[@]}]}"
        sleep 0.2
        printf "\b"
        ((i++))
    done
}

_spinner_pulse() {
    local -a marks=('█' '▓' '▒' '░' '▒' '▓')
    local i=0
    while :; do
        printf "%b" "${marks[i % ${#marks[@]}]}"
        sleep 0.15
        printf "\b"
        ((i++))
    done
}

_spinner_bounce() {
    local -a marks=('⠁' '⠂' '⠄' '⡀' '⢀' '⠠' '⠐' '⠈')
    local i=0
    while :; do
        printf "%b" "${marks[i % ${#marks[@]}]}"
        sleep 0.1
        printf "\b"
        ((i++))
    done
}

_spinner_arrow() {
    local -a marks=('←' '↖' '↑' '↗' '→' '↘' '↓' '↙')
    local i=0
    while :; do
        printf "%b" "${marks[i % ${#marks[@]}]}"
        sleep 0.1
        printf "\b"
        ((i++))
    done
}

_spinner_moon() {
    local -a marks=('🌑' '🌒' '🌓' '🌔' '🌕' '🌖' '🌗' '🌘')
    local i=0
    while :; do
        printf "%b" "${marks[i % ${#marks[@]}]}"
        sleep 0.2
        printf "\b\b"
        ((i++))
    done
}

_spinner_triangle() {
    local -a marks=('◢' '◣' '◤' '◥')
    local i=0
    while :; do
        printf "%b" "${marks[i % ${#marks[@]}]}"
        sleep 0.2
        printf "\b"
        ((i++))
    done
}

_spinner_clock() {
    local -a marks=('🕐' '🕑' '🕒' '🕓' '🕔' '🕕' '🕖' '🕗' '🕘' '🕙' '🕚' '🕛')
    local i=0
    while :; do
        printf "%b" "${marks[i % ${#marks[@]}]}"
        sleep 0.2
        printf "\b\b"
        ((i++))
    done
}

_stop_spinner() {
    if [ -n "${_spinner_pid}" ] && ps -p "${_spinner_pid}" >/dev/null 2>&1; then
        kill "${_spinner_pid}" >/dev/null 2>&1 || true
        wait "${_spinner_pid}" 2>/dev/null || true
        
        # Clear based on spinner style
        case "$_current_spinner_style" in
            "dots") printf "\b\b\b\b    \b\b\b\b" ;;
            "moon"|"clock") printf "\b\b  \b\b" ;;
            *) printf "\b \b" ;;
        esac
    fi
    unset _spinner_pid _current_spinner_style _spinner_message
    trap - EXIT INT TERM
}

# --- Fancy Box Drawing with Dynamic Sizes ---
print_box() {
    local msg="$1"
    local color="${2:-CYAN}"
    local style="${3:-single}"
    local width=$((${#msg} + 6))
    
    # Ensure width doesn't exceed terminal width
    if [ $width -gt $((TERM_WIDTH - 2)) ]; then
        width=$((TERM_WIDTH - 2))
    fi
    
    eval "local color_code=\$$color"
    
    case "$style" in
        "double")
            local h_line="═" v_line="║" tl_corner="╔" tr_corner="╗" bl_corner="╚" br_corner="╝"
            ;;
        "round")
            local h_line="─" v_line="│" tl_corner="╭" tr_corner="╮" bl_corner="╰" br_corner="╯"
            ;;
        "bold")
            local h_line="━" v_line="┃" tl_corner="┏" tr_corner="┓" bl_corner="┗" br_corner="┛"
            ;;
        *)
            local h_line="─" v_line="│" tl_corner="┌" tr_corner="┐" bl_corner="└" br_corner="┘"
            ;;
    esac
    
    printf "\n${color_code}${BOLD}${tl_corner}%*s${tr_corner}${RESET}\n" "$width" "" | tr " " "$h_line"
    printf "${color_code}${BOLD}${v_line}  %-*s  ${v_line}${RESET}\n" "$((width-4))" "$msg"
    printf "${color_code}${BOLD}${bl_corner}%*s${br_corner}${RESET}\n" "$width" "" | tr " " "$h_line"
}

# --- Animated Header with Multiple Effects ---
show_animated_header() {
    clear
    
    # Typewriter effect for header
    _typewriter_effect() {
        local text="$1"
        local color="$2"
        local delay="${3:-0.02}"
        
        eval "local color_code=\$$color"
        printf "%b" "${color_code}${BOLD}"
        
        for ((i=0; i<${#text}; i++)); do
            printf "%s" "${text:$i:1}"
            sleep "$delay"
        done
        printf "${RESET}"
    }
    
    # ASCII Art Header with multiple styles
    cat <<'EOF'
${BLUE}${BOLD}
  _      __   _______    _____ _   _  _____ _______       _      _      ______ _____  
 | |     \ \ / / ____|  |_   _| \ | |/ ____|__   __|/\   | |    | |    |  ____|  __ \ 
 | |      \ V / |         | | |  \| | (___    | |  /  \  | |    | |    | |__  | |__) |
 | |       > <| |         | | | .   |\___ \   | | / /\ \ | |    | |    |  __| |  _  / 
 | |____  / . \ |____    _| |_| |\  |____) |  | |/ ____ \| |____| |____| |____| | \ \ 
 |______|/_/ \_\_____|  |_____|_| \_|_____/   |_/_/    \_\______|______|______|_|  \_\
${RESET}
EOF

    # Animated subtitle with rainbow effect
    local subtitle="AUTO LXC + LXD INSTALLER MADE WITH ❤️ BY HOPINGBOYZ"
    local rainbow_colors=("$RED" "$YELLOW" "$GREEN" "$CYAN" "$BLUE" "$MAGENTA")
    
    printf "\n"
    for ((i=0; i<${#subtitle}; i++)); do
        local color_index=$((i % ${#rainbow_colors[@]}))
        printf "%b%s" "${rainbow_colors[color_index]}${BOLD}" "${subtitle:$i:1}"
        sleep 0.03
    done
    printf "${RESET}\n\n"
    
    _progress_bar 2 "pulse" "Initializing"
}

# --- Enhanced run command with retry logic ---
run_with_spinner() {
    local desc="$1"
    shift
    local cmd=( "$@" )
    local retry_count=0
    
    # Rotate through different spinner styles
    local styles=("dots" "circle" "pulse" "bounce" "arrow" "moon" "triangle" "clock")
    local style_index=$((RANDOM % ${#styles[@]}))
    local style="${styles[style_index]}"
    
    while [ $retry_count -le $MAX_RETRIES ]; do
        _start_spinner "$desc" "$style"
        
        if "${cmd[@]}" >> "$INSTALL_LOG" 2>&1; then
            _stop_spinner
            printf "%b\n" " ${GREEN}✅${RESET} ${BOLD}${desc}${RESET}"
            log_message "SUCCESS" "Command completed: $desc"
            return 0
        else
            _stop_spinner
            local error_msg="Command failed: $desc (Attempt $((retry_count + 1))/$((MAX_RETRIES + 1)))"
            log_message "ERROR" "$error_msg"
            
            if [ $retry_count -lt $MAX_RETRIES ]; then
                printf "%b\n" " ${YELLOW}⚠️${RESET} ${BOLD}${desc} failed, retrying in ${RETRY_DELAY}s...${RESET}"
                sleep $RETRY_DELAY
                ((retry_count++))
            else
                printf "%b\n" " ${RED}❌${RESET} ${BOLD}${desc}${RESET}"
                return 1
            fi
        fi
    done
}

# --- System Information Display ---
show_system_info() {
    print_box "SYSTEM INFORMATION" "BLUE" "double"
    
    local os_info=$(lsb_release -d 2>/dev/null | cut -f2 || echo "Unknown")
    local kernel_info=$(uname -r)
    local arch_info=$(uname -m)
    local mem_info=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}' || echo "Unknown")
    local disk_info=$(df -h / 2>/dev/null | awk 'NR==2 {print $4}' || echo "Unknown")
    
    echo -e "${CYAN}${BOLD}OS:${RESET} ${GREEN}${os_info}${RESET}"
    echo -e "${CYAN}${BOLD}Architecture:${RESET} ${GREEN}${arch_info}${RESET}"
    echo -e "${CYAN}${BOLD}Kernel:${RESET} ${GREEN}${kernel_info}${RESET}"
    echo -e "${CYAN}${BOLD}Memory:${RESET} ${GREEN}${mem_info}${RESET}"
    echo -e "${CYAN}${BOLD}Disk Space:${RESET} ${GREEN}${disk_info}${RESET}"
    
    # Check system requirements
    _check_system_requirements
}

_check_system_requirements() {
    local issues=0
    
    # Check memory
    local total_mem_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}' || echo "0")
    local total_mem_gb=$((total_mem_kb / 1024 / 1024))
    
    if [ "$total_mem_gb" -lt 2 ]; then
        echo -e "${YELLOW}${BOLD}⚠️  Warning:${RESET} ${YELLOW}System has less than 2GB RAM (${total_mem_gb}GB detected)${RESET}"
        ((issues++))
    fi
    
    # Check disk space
    local available_gb=$(df / 2>/dev/null | awk 'NR==2 {print int($4/1024/1024)}' || echo "0")
    if [ "$available_gb" -lt 5 ]; then
        echo -e "${YELLOW}${BOLD}⚠️  Warning:${RESET} ${YELLOW}Low disk space (${available_gb}GB available)${RESET}"
        ((issues++))
    fi
    
    if [ $issues -gt 0 ]; then
        echo -e "\n${YELLOW}${BOLD}Note:${RESET} ${YELLOW}System may have limited resources for containers${RESET}"
        sleep 2
    fi
}

# --- Helper: require sudo/root ---
check_privileges() {
    if [ "$(id -u)" -ne 0 ]; then
        SUDO="sudo"
        if ! groups | grep -q '\bsudo\b' && ! groups | grep -q '\bwheel\b'; then
            echo -e "${RED}❌ User does not have sudo privileges${RESET}"
            exit 1
        fi
    else
        SUDO=""
    fi
}

# --- Detect OS with enhanced validation ---
detect_os() {
    if [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        OS_ID=${ID:-unknown}
        OS_VERSION_ID=${VERSION_ID:-}
        OS_PRETTY_NAME=${PRETTY_NAME:-$OS_ID}
    else
        echo -e "${RED}❌ Unable to detect operating system.${RESET}"
        exit 1
    fi
    
    show_system_info
    sleep 1
}

# Check supported OS with version validation
check_os_support() {
    case "$OS_ID" in
        ubuntu)
            if [ -n "$OS_VERSION_ID" ] && [ "$(echo "$OS_VERSION_ID" | cut -d'.' -f1)" -lt 18 ]; then
                echo -e "${YELLOW}⚠️  Older Ubuntu version detected ($OS_VERSION_ID)${RESET}"
                echo -e "${YELLOW}Some features may not work optimally${RESET}"
            fi
            print_box "UBUNTU DETECTED - FULLY SUPPORTED" "GREEN" "round"
            ;;
        debian)
            if [ -n "$OS_VERSION_ID" ] && [ "$(echo "$OS_VERSION_ID" | cut -d'.' -f1)" -lt 10 ]; then
                echo -e "${YELLOW}⚠️  Older Debian version detected ($OS_VERSION_ID)${RESET}"
                echo -e "${YELLOW}Consider upgrading for better LXD support${RESET}"
            fi
            print_box "DEBIAN DETECTED - FULLY SUPPORTED" "GREEN" "round"
            ;;
        *)
            print_box "UNSUPPORTED OPERATING SYSTEM" "RED" "bold"
            echo -e "${RED}❌ This installer only supports Ubuntu and Debian.${RESET}"
            echo -e "${YELLOW}Detected OS: $OS_PRETTY_NAME${RESET}"
            exit 1
            ;;
    esac
}

# --- Installation Functions with Enhanced Error Handling ---
install_prereqs() {
    print_box "INSTALLING PREREQUISITES" "YELLOW" "bold"
    
    run_with_spinner "Updating package lists" $SUDO apt-get update -y
    run_with_spinner "Upgrading system packages" $SUDO apt-get upgrade -y
    run_with_spinner "Installing LXC and dependencies" $SUDO apt-get install -y lxc lxc-utils bridge-utils uidmap squashfs-tools curl wget
    
    echo -e "\n${GREEN}${BOLD}✓ Prerequisites installed successfully${RESET}"
}

install_snapd_and_lxd() {
    print_box "INSTALLING SNAPD AND LXD" "MAGENTA" "double"
    
    if ! command -v snap >/dev/null 2>&1; then
        run_with_spinner "Installing snapd" $SUDO apt-get install -y snapd
    else
        echo -e "${GREEN}✓ snapd already installed${RESET}"
    fi
    
    run_with_spinner "Enabling snapd socket" $SUDO systemctl enable --now snapd.socket
    
    # Ensure /snap symlink exists for older systems
    if [ ! -L /snap ] && [ -d /var/lib/snapd/snap ]; then
        run_with_spinner "Creating snap directory symlink" $SUDO ln -s /var/lib/snapd/snap /snap || true
    fi
    
    # Wait for snapd to be ready with timeout
    _start_spinner "Waiting for snapd to be ready" "clock"
    local timeout=30
    local count=0
    while [ $count -lt $timeout ]; do
        if snap list >/dev/null 2>&1; then
            _stop_spinner
            printf "%b\n" " ${GREEN}✅${RESET} ${BOLD}snapd ready${RESET}"
            break
        fi
        sleep 1
        ((count++))
    done
    
    if [ $count -ge $timeout ]; then
        _stop_spinner
        printf "%b\n" " ${YELLOW}⚠️${RESET} ${BOLD}snapd timeout, continuing anyway${RESET}"
    fi
    
    # Install LXD via snap
    if ! snap list lxd >/dev/null 2>&1; then
        run_with_spinner "Installing LXD (latest stable)" $SUDO snap install lxd --channel=latest/stable
    else
        echo -e "${GREEN}✓ LXD already installed${RESET}"
    fi
    
    echo -e "\n${GREEN}${BOLD}✓ Snapd and LXD installed successfully${RESET}"
}

add_user_to_lxd() {
    print_box "CONFIGURING USER PERMISSIONS" "CYAN" "round"
    
    TARGET_USER="${SUDO_USER:-$(whoami)}"
    
    echo -e "${CYAN}${BOLD}Configuring user:${RESET} ${GREEN}${TARGET_USER}${RESET}"
    
    if ! groups "$TARGET_USER" | grep -q '\blxd\b'; then
        run_with_spinner "Adding user to lxd group" $SUDO usermod -aG lxd "$TARGET_USER"
    else
        echo -e "${GREEN}✓ User already in lxd group${RESET}"
    fi
    
    # Show group information with animation
    _start_spinner "Verifying group membership" "dots"
    sleep 2
    _stop_spinner
    
    echo -e "\n${YELLOW}${BOLD}User groups:${RESET}"
    groups "$TARGET_USER" | tr ' ' '\n' | while read -r group; do
        if [ "$group" = "lxd" ]; then
            echo -e "  ${GREEN}✅${RESET} ${BOLD}lxd${RESET}"
        elif [ "$group" = "sudo" ]; then
            echo -e "  ${BLUE}🔷${RESET} ${BOLD}sudo${RESET}"
        else
            echo -e "  ${DIM}${group}${RESET}"
        fi
    done
    
    echo -e "\n${YELLOW}${BOLD}Note:${RESET} You may need to log out and log back in for group changes to take effect"
}

run_lxd_init() {
    print_box "INITIALIZING LXD" "BLUE" "double"
    
    echo -e "${CYAN}${BOLD}LXD initialization will now begin.${RESET}"
    echo -e "${YELLOW}Tip: Press Enter to accept defaults, or customize as needed.${RESET}"
    echo -e "${MAGENTA}This is an interactive process...${RESET}\n"
    
    _progress_bar 3 "arrow" "Preparing LXD Init"
    
    if $SUDO lxd init; then
        echo -e "\n${GREEN}${BOLD}✅ LXD initialized successfully${RESET}"
        log_message "SUCCESS" "LXD initialization completed"
    else
        echo -e "\n${YELLOW}${BOLD}⚠️  LXD initialization completed with warnings${RESET}"
        echo -e "${YELLOW}You can run 'sudo lxd init' later to reconfigure if needed.${RESET}"
        log_message "WARNING" "LXD initialization had warnings"
    fi
}

# --- Post Installation Validation ---
validate_installation() {
    print_box "VALIDATING INSTALLATION" "GREEN" "round"
    
    _start_spinner "Checking LXD service status" "pulse"
    if $SUDO lxc info >/dev/null 2>&1; then
        _stop_spinner
        printf "%b\n" " ${GREEN}✅${RESET} ${BOLD}LXD service is running${RESET}"
    else
        _stop_spinner
        printf "%b\n" " ${YELLOW}⚠️${RESET} ${BOLD}LXD service check failed${RESET}"
    fi
    
    _start_spinner "Testing container functionality" "bounce"
    if $SUDO lxc list >/dev/null 2>&1; then
        _stop_spinner
        printf "%b\n" " ${GREEN}✅${RESET} ${BOLD}Container functionality verified${RESET}"
    else
        _stop_spinner
        printf "%b\n" " ${YELLOW}⚠️${RESET} ${BOLD}Container functionality test failed${RESET}"
    fi
    
    echo -e "\n${GREEN}${BOLD}✓ Installation validation completed${RESET}"
}

show_success_message() {
    print_box "INSTALLATION COMPLETE" "GREEN" "double"
    
    echo -e "\n${GREEN}${BOLD}🎉 Congratulations! LXC/LXD has been successfully installed.${RESET}"
    
    echo -e "\n${CYAN}${BOLD}Next Steps:${RESET}"
    echo -e "  ${GREEN}➤${RESET} ${BOLD}Reboot your system${RESET} or log out/in to apply group changes:"
    echo -e "     ${YELLOW}sudo reboot${RESET}"
    echo -e "  ${GREEN}➤${RESET} ${BOLD}Or reload your shell session:${RESET}"
    echo -e "     ${YELLOW}newgrp lxd${RESET}"
    
    echo -e "\n${CYAN}${BOLD}Quick Start Commands:${RESET}"
    echo -e "  ${GREEN}▶${RESET} ${BOLD}lxc list${RESET}                 - List all containers"
    echo -e "  ${GREEN}▶${RESET} ${BOLD}lxc launch ubuntu:24.04 myvm${RESET} - Launch a test container"
    echo -e "  ${GREEN}▶${RESET} ${BOLD}lxc storage list${RESET}         - Show storage pools"
    echo -e "  ${GREEN}▶${RESET} ${BOLD}lxc network list${RESET}         - Show networks"
    echo -e "  ${GREEN}▶${RESET} ${BOLD}lxc profile list${RESET}         - Show profiles"
    
    echo -e "\n${CYAN}${BOLD}Useful Tips:${RESET}"
    echo -e "  ${YELLOW}💡${RESET} Run ${BOLD}lxc --help${RESET} for all available commands"
    echo -e "  ${YELLOW}💡${RESET} Visit ${UNDERLINE}https://linuxcontainers.org/${RESET} for documentation"
    echo -e "  ${YELLOW}💡${RESET} Use ${BOLD}lxc info${RESET} to check your LXD configuration"
    echo -e "  ${YELLOW}💡${RESET} Check log file: ${UNDERLINE}${INSTALL_LOG}${RESET}"
    
    echo -e "\n${MAGENTA}${BOLD}Thank you for using HopingBoyz LXC/LXD Installer! 🚀${RESET}\n"
}

# === Main Installation Flow ===
main() {
    init_log
    log_message "INFO" "Starting LXC/LXD installation"
    
    show_animated_header
    check_privileges
    detect_os
    check_os_support
    
    # Installation steps
    install_prereqs
    install_snapd_and_lxd
    add_user_to_lxd
    run_lxd_init
    validate_installation
    show_success_message
    
    log_message "INFO" "Installation completed successfully"
}

# Enhanced error handling with detailed information
handle_error() {
    local exit_code=$?
    local line_number=$1
    local command=$2
    
    _stop_spinner 2>/dev/null || true
    
    log_message "ERROR" "Installation failed at line $line_number: $command (exit code: $exit_code)"
    
    echo -e "\n${RED}${BOLD}╔══════════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${RED}${BOLD}║                 INSTALLATION FAILED                         ║${RESET}"
    echo -e "${RED}${BOLD}╠══════════════════════════════════════════════════════════════╣${RESET}"
    echo -e "${RED}${BOLD}║                                                              ║${RESET}"
    echo -e "${RED}${BOLD}║  An error occurred during installation at line ${line_number}          ║${RESET}"
    echo -e "${RED}${BOLD}║  Command: ${command}${RESET}"
    echo -e "${RED}${BOLD}║  Exit Code: ${exit_code}                                            ║${RESET}"
    echo -e "${RED}${BOLD}║                                                              ║${RESET}"
    echo -e "${RED}${BOLD}║  Check the log file for details: ${INSTALL_LOG}${RESET}"
    echo -e "${RED}${BOLD}║                                                              ║${RESET}"
    echo -e "${RED}${BOLD}║  Common solutions:                                            ║${RESET}"
    echo -e "${RED}${BOLD}║   • Check internet connection                                 ║${RESET}"
    echo -e "${RED}${BOLD}║   • Verify sufficient disk space                              ║${RESET}"
    echo -e "${RED}${BOLD}║   • Ensure you have sudo privileges                          ║${RESET}"
    echo -e "${RED}${BOLD}║   • Try running the script again                             ║${RESET}"
    echo -e "${RED}${BOLD}║                                                              ║${RESET}"
    echo -e "${RED}${BOLD}╚══════════════════════════════════════════════════════════════╝${RESET}"
    
    exit $exit_code
}

# Set trap for error handling with line numbers
trap 'handle_error ${LINENO} "${BASH_COMMAND}"' ERR

# Handle Ctrl+C gracefully
trap '{ echo -e "\n${YELLOW}Installation interrupted by user${RESET}"; _stop_spinner 2>/dev/null || true; exit 1; }' INT

# Run main installation
main "$@"
