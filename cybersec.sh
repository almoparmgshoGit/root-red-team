#!/usr/bin/env bash
#===============================================================================
# Root Red Team — Multi-Distro Cybersecurity Tools Installer
# Author: HackerAI
# Version: 3.1
# GitHub: https://github.com/YOUR_USERNAME/root-red-team
#===============================================================================

set -euo pipefail

# ============================================================================
# COLORS
# ============================================================================
RED='\033[0;31m'
BRED='\033[1;31m'
GREEN='\033[0;32m'
BGREEN='\033[1;32m'
YELLOW='\033[0;33m'
BYELLOW='\033[1;33m'
BLUE='\033[0;34m'
BBLUE='\033[1;34m'
CYAN='\033[0;36m'
BCYAN='\033[1;36m'
MAGENTA='\033[0;35m'
BMAGENTA='\033[1;35m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m'

# ============================================================================
# GLOBALS
# ============================================================================
VERSION="3.1"
REPO="almoparmgshoGit/root-red-team"
UPDATE_CACHE="/tmp/.rrt_update_check"
LOG_FILE="/tmp/rrt-$(date +%Y%m%d-%H%M%S).log"
TERM_WIDTH=$(tput cols 2>/dev/null || echo 80)

# ============================================================================
# LOGGING
# ============================================================================
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"; }

# ============================================================================
# TRAP
# ============================================================================
cleanup() {
    echo -e "\n${YELLOW}[!] Interrupted. Cleaning up...${NC}"
    log "Interrupted by user"
    tput cnorm 2>/dev/null || true
    exit 1
}
trap cleanup SIGINT SIGTERM

# ============================================================================
# UI HELPERS
# ============================================================================
info()   { echo -e "${BGREEN}[+]${NC} $1"; log "[INFO] $1"; }
warn()   { echo -e "${BYELLOW}[!]${NC} $1"; log "[WARN] $1"; }
error()  { echo -e "${BRED}[-]${NC} $1"; log "[ERROR] $1"; }
success(){ echo -e "${BGREEN}[*]${NC} $1"; log "[OK] $1"; }

header() {
    local title="$1"
    local len=${#title}
    local line
    line=$(printf '%*s' "$((TERM_WIDTH - 4))" '' | tr ' ' '═')
    echo ""
    echo -e "${BRED}╔${line}╗${NC}"
    printf "${BRED}║${NC}  ${WHITE}%-*s${NC}${BRED}║${NC}\n" "$((TERM_WIDTH - 5))" "$title"
    echo -e "${BRED}╚${line}╝${NC}"
    echo ""
}

divider() {
    printf "${DIM}%*s${NC}\n" "$TERM_WIDTH" '' | tr ' ' '─'
}

# ============================================================================
# ANIMATIONS
# ============================================================================

# Typing effect
type_text() {
    local text="$1"
    local delay="${2:-0.03}"
    local color="${3:-$NC}"
    echo -ne "${color}"
    for ((i=0; i<${#text}; i++)); do
        echo -ne "${text:$i:1}"
        sleep "$delay"
    done
    echo -e "${NC}"
}

# Progress bar
progress_bar() {
    local current="$1"
    local total="$2"
    local label="${3:-}"
    local bar_width=40
    local filled=$(( current * bar_width / total ))
    local empty=$(( bar_width - filled ))
    local percent=$(( current * 100 / total ))

    local bar=""
    bar+="${BRED}["
    bar+="${BGREEN}$(printf '%*s' "$filled" '' | tr ' ' '#')"
    bar+="${DIM}$(printf '%*s' "$empty" '' | tr ' ' '-')"
    bar+="${BRED}]${NC}"

    printf "\r  %s %3d%% %s" "$bar" "$percent" "$label"
}

# Spinner with message
spinner_msg() {
    local pid="$1"
    local msg="${2:-Working...}"
    local frames=('[ -    ]' '[  -   ]' '[   -  ]' '[    - ]' '[     -]' '[    - ]' '[   -  ]' '[  -   ]' '[ -    ]')
    local i=0
    tput civis 2>/dev/null || true
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r  ${BRED}%s${NC}  ${WHITE}%s${NC}" "${frames[$i]}" "$msg"
        i=$(( (i + 1) % ${#frames[@]} ))
        sleep 0.1
    done
    printf "\r  ${BGREEN}[ done ]${NC}  ${WHITE}%s${NC}\n" "$msg"
    tput cnorm 2>/dev/null || true
}

# Animated dots
animate_dots() {
    local msg="$1"
    local count="${2:-3}"
    for ((i=1; i<=count; i++)); do
        printf "\r  ${BCYAN}%s${NC}" "$msg$(printf '%*s' "$i" '' | tr ' ' '.')"
        sleep 0.4
    done
    echo ""
}

# Loading bar (fake progress for visual feedback)
loading_bar() {
    local msg="${1:-Loading}"
    local duration="${2:-1.5}"
    local steps=40
    local sleep_time
    sleep_time=$(echo "scale=4; $duration / $steps" | bc 2>/dev/null || echo "0.04")

    echo -ne "  ${WHITE}${msg}${NC} "
    echo -ne "${BRED}[${NC}"
    for ((i=0; i<steps; i++)); do
        echo -ne "${BGREEN}#${NC}"
        sleep "$sleep_time"
    done
    echo -e "${BRED}]${NC} ${BGREEN}done${NC}"
}

# Flash effect for banner lines
flash_line() {
    local line="$1"
    local color="${2:-$BRED}"
    for i in 1 2 3; do
        echo -ne "\r${color}${line}${NC}"
        sleep 0.08
        echo -ne "\r${DIM}${line}${NC}"
        sleep 0.08
    done
    echo -e "\r${color}${line}${NC}"
}

# ============================================================================
# BANNER
# ============================================================================
banner() {
    clear
    tput civis 2>/dev/null || true
    sleep 0.1

    echo ""

    local lines=(
"  ██████╗  ██████╗  ██████╗ ████████╗"
"  ██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝"
"  ██████╔╝██║   ██║██║   ██║   ██║   "
"  ██╔══██╗██║   ██║██║   ██║   ██║   "
"  ██║  ██║╚██████╔╝╚██████╔╝   ██║   "
"  ╚═╝  ╚═╝ ╚═════╝  ╚═════╝   ╚═╝   "
    )

    for line in "${lines[@]}"; do
        echo -e "${BRED}${line}${NC}"
        sleep 0.06
    done

    echo ""

    local lines2=(
"  ██████╗ ███████╗██████╗      ████████╗███████╗ █████╗ ███╗   ███╗"
"  ██╔══██╗██╔════╝██╔══██╗        ██║   ██╔════╝██╔══██╗████╗ ████║"
"  ██████╔╝█████╗  ██║  ██║        ██║   █████╗  ███████║██╔████╔██║"
"  ██╔══██╗██╔══╝  ██║  ██║        ██║   ██╔══╝  ██╔══██║██║╚██╔╝██║"
"  ██║  ██║███████╗██████╔╝        ██║   ███████╗██║  ██║██║ ╚═╝ ██║"
"  ╚═╝  ╚═╝╚══════╝╚═════╝         ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝"
    )

    for line in "${lines2[@]}"; do
        echo -e "${RED}${line}${NC}"
        sleep 0.06
    done

    echo ""
    sleep 0.2

    divider
    printf "${BCYAN}%*s${NC}\n" $(( (TERM_WIDTH + 42) / 2 )) "Multi-Distro Cybersecurity Tools Installer"
    printf "${DIM}%*s${NC}\n"   $(( (TERM_WIDTH + 38) / 2 )) "Kali | Arch | Debian | Fedora | openSUSE"
    printf "${BYELLOW}%*s${NC}\n" $(( (TERM_WIDTH + 14) / 2 )) "Version ${VERSION}"
    divider
    echo ""

    tput cnorm 2>/dev/null || true
    sleep 0.3
}

# ============================================================================
# UPDATE SYSTEM
# ============================================================================
check_for_updates() {
    # تخطى لو مر أقل من ساعة من آخر فحص
    if [[ -f "$UPDATE_CACHE" ]]; then
        local last_check
        last_check=$(cat "$UPDATE_CACHE" 2>/dev/null || echo 0)
        local now
        now=$(date +%s)
        local diff=$(( now - last_check ))
        if [[ $diff -lt 3600 ]]; then
            return 0
        fi
    fi

    # تخطى لو بدون إنترنت
    if ! curl -fsSL --connect-timeout 3 "https://api.github.com" &>/dev/null; then
        return 0
    fi

    animate_dots "  Checking for updates" 3

    local latest
    latest=$(curl -fsSL --connect-timeout 5 \
        "https://api.github.com/repos/${REPO}/releases/latest" \
        2>/dev/null | grep '"tag_name"' | cut -d'"' -f4 | tr -d 'v')

    # سجل وقت الفحص
    date +%s > "$UPDATE_CACHE" 2>/dev/null || true

    if [[ -z "$latest" ]]; then
        warn "Could not fetch update info."
        return 0
    fi

    if [[ "$latest" != "$VERSION" ]]; then
        echo ""
        divider
        echo -e "  ${BYELLOW}New version available!${NC}"
        echo -e "  ${DIM}Current :${NC} ${RED}v${VERSION}${NC}"
        echo -e "  ${DIM}Latest  :${NC} ${BGREEN}v${latest}${NC}"
        echo -e "  ${DIM}URL     :${NC} ${BCYAN}https://github.com/${REPO}${NC}"
        divider
        echo ""

        # عرض الـ changelog لو متوفر
        _show_changelog "$latest"

        echo -n -e "  ${BYELLOW}Update now? (y/N):${NC} "
        read -r resp
        if [[ "$resp" == "y" || "$resp" == "Y" ]]; then
            _do_update
        else
            warn "Skipping update. You can update later by re-running the script."
        fi
        echo ""
    else
        success "Script is up to date (v${VERSION})"
        sleep 0.5
    fi
}

_show_changelog() {
    local tag="$1"
    local notes
    notes=$(curl -fsSL --connect-timeout 5 \
        "https://api.github.com/repos/${REPO}/releases/latest" \
        2>/dev/null | grep '"body"' | head -1 | cut -d'"' -f4 | \
        sed 's/\\r\\n/\n/g; s/\\n/\n/g' | head -10)

    if [[ -n "$notes" ]]; then
        echo -e "  ${BCYAN}What's new in v${tag}:${NC}"
        echo "$notes" | while IFS= read -r line; do
            [[ -n "$line" ]] && echo -e "  ${DIM}${line}${NC}"
        done
        echo ""
    fi
}

_do_update() {
    local target
    target=$(realpath "$0" 2>/dev/null || echo "/usr/local/bin/root-red-team")
    local tmp_file="/tmp/rrt_update_$$.sh"

    echo ""
    info "Downloading latest version..."

    if curl -fsSL --connect-timeout 10 \
        "https://raw.githubusercontent.com/${REPO}/main/root-red-team.sh" \
        -o "$tmp_file" 2>/dev/null; then

        # تحقق ان الملف المحمل صحيح
        if bash -n "$tmp_file" 2>/dev/null; then
            chmod +x "$tmp_file"
            mv "$tmp_file" "$target"
            success "Updated successfully to latest version!"
            info "Please restart the script."
            rm -f "$UPDATE_CACHE" 2>/dev/null || true
            exit 0
        else
            error "Downloaded file has syntax errors. Aborting update."
            rm -f "$tmp_file"
        fi
    else
        error "Failed to download update."
        rm -f "$tmp_file" 2>/dev/null || true
    fi
}

# ============================================================================
# ROOT CHECK
# ============================================================================
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo ""
        error "This script must be run as root."
        echo -e "  ${DIM}Try: ${BCYAN}sudo $0${NC}"
        echo ""
        exit 1
    fi
}

# ============================================================================
# DISTRO DETECTION
# ============================================================================
detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        DISTRO_ID="$ID"
        DISTRO_LIKE="${ID_LIKE:-}"
        DISTRO_NAME="$NAME"
    elif [[ -f /etc/arch-release ]]; then
        DISTRO_ID="arch"; DISTRO_LIKE="arch"; DISTRO_NAME="Arch Linux"
    elif [[ -f /etc/debian_version ]]; then
        DISTRO_ID="debian"; DISTRO_LIKE="debian"; DISTRO_NAME="Debian"
    elif [[ -f /etc/fedora-release ]]; then
        DISTRO_ID="fedora"; DISTRO_LIKE="fedora"; DISTRO_NAME="Fedora"
    elif [[ -f /etc/redhat-release ]]; then
        DISTRO_ID="rhel"; DISTRO_LIKE="fedora"; DISTRO_NAME="Red Hat"
    elif [[ -f /etc/SuSE-release ]] || [[ -f /etc/opensuse-release ]]; then
        DISTRO_ID="opensuse"; DISTRO_LIKE="suse"; DISTRO_NAME="openSUSE"
    else
        DISTRO_ID="unknown"; DISTRO_LIKE=""; DISTRO_NAME="Unknown"
    fi
    DISTRO_ID=$(echo "$DISTRO_ID" | tr '[:upper:]' '[:lower:]')
    DISTRO_LIKE=$(echo "$DISTRO_LIKE" | tr '[:upper:]' '[:lower:]')
}

classify_distro() {
    case "$DISTRO_ID" in
        kali)        DISTRO_CLASS="kali" ;;
        arch|blackarch) DISTRO_CLASS="arch" ;;
        debian|ubuntu|linuxmint|pop|elementary|zorin|parrot) DISTRO_CLASS="debian" ;;
        fedora|rhel|centos|rocky|almalinux) DISTRO_CLASS="fedora" ;;
        opensuse*|suse*) DISTRO_CLASS="suse" ;;
        *)
            case "$DISTRO_LIKE" in
                *kali*)   DISTRO_CLASS="kali" ;;
                *arch*)   DISTRO_CLASS="arch" ;;
                *debian*) DISTRO_CLASS="debian" ;;
                *fedora*) DISTRO_CLASS="fedora" ;;
                *suse*)   DISTRO_CLASS="suse" ;;
                *)        DISTRO_CLASS="unknown" ;;
            esac ;;
    esac
}

# ============================================================================
# PACKAGE MANAGER
# ============================================================================
setup_pm() {
    case "$DISTRO_CLASS" in
        kali|debian)
            PKG_MGR="apt"
            PKG_INSTALL="DEBIAN_FRONTEND=noninteractive apt-get install -y"
            PKG_REMOVE="DEBIAN_FRONTEND=noninteractive apt-get remove -y"
            PKG_PURGE="DEBIAN_FRONTEND=noninteractive apt-get purge -y"
            PKG_AUTOREMOVE="apt-get autoremove -y"
            PKG_UPDATE="apt-get update"
            PKG_SEARCH="apt-cache search"
            ;;
        arch)
            PKG_MGR="pacman"
            PKG_INSTALL="pacman -S --noconfirm"
            PKG_REMOVE="pacman -R --noconfirm"
            PKG_PURGE="pacman -Rns --noconfirm"
            PKG_AUTOREMOVE="pacman -Rns --noconfirm \$(pacman -Qdtq 2>/dev/null) 2>/dev/null || true"
            PKG_UPDATE="pacman -Sy"
            PKG_SEARCH="pacman -Ss"
            ;;
        fedora)
            PKG_MGR="dnf"
            PKG_INSTALL="dnf install -y"
            PKG_REMOVE="dnf remove -y"
            PKG_PURGE="dnf remove -y"
            PKG_AUTOREMOVE="dnf autoremove -y"
            PKG_UPDATE="dnf check-update || true"
            PKG_SEARCH="dnf search"
            if ! command -v dnf &>/dev/null; then
                PKG_MGR="yum"
                PKG_INSTALL="yum install -y"
                PKG_REMOVE="yum remove -y"
                PKG_PURGE="yum remove -y"
                PKG_AUTOREMOVE="yum autoremove -y"
                PKG_UPDATE="yum check-update || true"
                PKG_SEARCH="yum search"
            fi
            ;;
        suse)
            PKG_MGR="zypper"
            PKG_INSTALL="zypper install -y"
            PKG_REMOVE="zypper remove -y"
            PKG_PURGE="zypper remove --clean-deps -y"
            PKG_AUTOREMOVE="zypper rm -u"
            PKG_UPDATE="zypper refresh"
            PKG_SEARCH="zypper search"
            ;;
        *)
            error "Unsupported distribution: $DISTRO_NAME"
            exit 1
            ;;
    esac
}

# ============================================================================
# BLACKARCH
# ============================================================================
setup_blackarch() {
    [[ "$DISTRO_CLASS" != "arch" ]] && return
    if pacman -Qg 2>/dev/null | grep -q blackarch; then
        info "BlackArch repository already configured"
        return
    fi
    info "Configuring BlackArch repository..."
    local strap="/tmp/blackarch-strap.sh"
    curl -fsSL "https://blackarch.org/strap.sh" -o "$strap" 2>/dev/null || {
        warn "Failed to download BlackArch strap.sh"; return 1
    }
    chmod +x "$strap"
    sh "$strap" 2>/dev/null || warn "BlackArch setup had issues"
    rm -f "$strap"
    eval "$PKG_UPDATE" || true
}

# ============================================================================
# DISK CHECK
# ============================================================================
check_disk_space() {
    local required_mb="${1:-5000}"
    local available_kb
    available_kb=$(df /opt --output=avail 2>/dev/null | tail -1)
    local available_mb=$((available_kb / 1024))
    if [[ $available_mb -lt $required_mb ]]; then
        warn "Only ${available_mb}MB available. ${required_mb}MB recommended."
        echo -n -e "  ${BYELLOW}Continue anyway? (y/N):${NC} "
        read -r resp
        [[ "$resp" != "y" && "$resp" != "Y" ]] && return 1
    fi
    return 0
}

# ============================================================================
# PACKAGE HELPERS
# ============================================================================
package_installed() {
    local pkg="$1"
    case "$DISTRO_CLASS" in
        kali|debian) dpkg -l "$pkg" 2>/dev/null | grep -q "^ii" || return 1 ;;
        arch)        pacman -Qi "$pkg" &>/dev/null || return 1 ;;
        fedora|suse) rpm -q "$pkg" &>/dev/null || return 1 ;;
    esac
    return 0
}

install_prereqs() {
    header "Installing Prerequisites"
    echo -e "  ${DIM}Distro  :${NC} ${WHITE}$DISTRO_NAME${NC}"
    echo -e "  ${DIM}Class   :${NC} ${WHITE}$DISTRO_CLASS${NC}"
    echo -e "  ${DIM}PM      :${NC} ${WHITE}$PKG_MGR${NC}"
    echo ""

    check_disk_space 2000 || return 1

    info "Updating package repositories..."
    eval "$PKG_UPDATE" &>/dev/null &
    spinner_msg $! "Updating repos..."

    info "Installing base dependencies..."
    case "$DISTRO_CLASS" in
        debian|kali)
            eval "$PKG_INSTALL curl wget git python3 python3-pip python3-venv build-essential cmake libssl-dev libffi-dev libpcap-dev libsqlite3-dev zip unzip p7zip-full" &>/dev/null &
            ;;
        arch)
            eval "$PKG_INSTALL curl wget git python python-pip base-devel cmake openssl libpcap zip unzip p7zip pacman-contrib" &>/dev/null &
            ;;
        fedora)
            eval "$PKG_INSTALL curl wget git python3 python3-pip python3-devel gcc gcc-c++ make cmake openssl-devel libpcap-devel libffi-devel sqlite-devel zip unzip p7zip" &>/dev/null &
            if [[ "$DISTRO_ID" == "rhel" || "$DISTRO_ID" == "centos" || "$DISTRO_ID" == "rocky" || "$DISTRO_ID" == "almalinux" ]]; then
                if ! rpm -q epel-release &>/dev/null; then
                    info "Enabling EPEL..."
                    rpm -Uvh "https://dl.fedoraproject.org/pub/epel/epel-release-latest-$(rpm -E %rhel).noarch.rpm" &>/dev/null
                fi
            fi
            ;;
        suse)
            eval "$PKG_INSTALL curl wget git python3 python3-pip python3-devel gcc gcc-c++ make cmake openssl-devel libpcap-devel libffi-devel sqlite3-devel zip unzip p7zip" &>/dev/null &
            ;;
    esac
    spinner_msg $! "Installing base dependencies..."
    success "Prerequisites ready"
}

# ============================================================================
# GIT TOOL HELPERS
# ============================================================================
install_git_tool() {
    local tool_name="$1"
    local repo_url="$2"
    local target_dir="${3:-/opt/$tool_name}"

    if [[ -d "$target_dir" ]]; then
        info "${tool_name} already installed"
        return 0
    fi

    info "Cloning ${tool_name}..."
    mkdir -p /opt
    git clone --depth 1 "$repo_url" "$target_dir" &>/dev/null || {
        warn "Failed to clone $tool_name"; return 1
    }

    if [[ -f "$target_dir/requirements.txt" ]]; then
        python3 -m venv "$target_dir/.venv" &>/dev/null || true
        # shellcheck disable=SC1091
        source "$target_dir/.venv/bin/activate" &>/dev/null || true
        pip install -r "$target_dir/requirements.txt" &>/dev/null || warn "pip install failed for $tool_name"
        deactivate &>/dev/null || true
    fi

    [[ -f "$target_dir/setup.py" ]] && pip3 install -e "$target_dir" &>/dev/null || true

    if [[ -f "$target_dir/Makefile" ]] || [[ -f "$target_dir/makefile" ]]; then
        make -C "$target_dir" &>/dev/null && make -C "$target_dir" install &>/dev/null || true
    fi

    if [[ -d "$target_dir/bin" ]]; then
        for f in "$target_dir/bin/"*; do
            [[ -f "$f" && -x "$f" ]] && ln -sf "$f" /usr/local/bin/ &>/dev/null || true
        done
    fi

    [[ -f "$target_dir/$tool_name" && -x "$target_dir/$tool_name" ]] && \
        ln -sf "$target_dir/$tool_name" /usr/local/bin/ &>/dev/null || true

    success "${tool_name} installed"
}

remove_git_tool() {
    local tool_name="$1"
    local target_dir="${2:-/opt/$tool_name}"

    if [[ ! -d "$target_dir" ]]; then
        warn "$tool_name not found at $target_dir"
        return 1
    fi

    [[ -f "$target_dir/setup.py" ]] && pip3 uninstall -y "$tool_name" &>/dev/null || true

    if [[ -d "$target_dir/bin" ]]; then
        for f in "$target_dir/bin/"*; do
            local bn; bn=$(basename "$f")
            [[ -L "/usr/local/bin/$bn" ]] && rm -f "/usr/local/bin/$bn"
        done
    fi

    [[ -f "$target_dir/$tool_name" && -L "/usr/local/bin/$tool_name" ]] && \
        rm -f "/usr/local/bin/$tool_name"

    rm -rf "$target_dir"
    success "$tool_name removed"
}

update_git_tool() {
    local tool_name="$1"
    local target_dir="${2:-/opt/$tool_name}"

    if [[ ! -d "$target_dir" ]] || [[ ! -d "$target_dir/.git" ]]; then
        warn "$tool_name not found or not a git repo"
        return 1
    fi

    info "Updating $tool_name..."
    cd "$target_dir" || return 1
    local branch
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
    git stash &>/dev/null || true
    if git pull --ff-only origin "$branch" &>/dev/null; then
        [[ -f "$target_dir/setup.py" ]] && pip3 install -e "$target_dir" &>/dev/null || true
        success "$tool_name updated"
    else
        warn "Failed to update $tool_name"
        git stash pop &>/dev/null || true
    fi
}

update_all_git_tools() {
    header "Updating All Git-Installed Tools"
    local known_tools=(
        dnsrecon Sublist3r massdns dirsearch routersploit
        bettercap Responder BloodHound.py chisel ligolo-ng
        evil-winrm peda ghidra volatility3 autopsy
        spiderfoot gophish sqlninja pacu ScoutSuite
        apktool dex2jar libbtbb ubertooth vulners
        hash-identifier bully wifite
    )
    local total=${#known_tools[@]}
    local i=0
    for tool in "${known_tools[@]}"; do
        ((i++))
        progress_bar "$i" "$total" "$tool"
        update_git_tool "$tool" &>/dev/null || true
    done
    echo ""
    success "All tools updated"
}

remove_all_git_tools() {
    header "Removing ALL Git-Installed Tools"
    [[ ! -d /opt ]] && info "No /opt directory" && return

    echo -e "  ${BYELLOW}WARNING: This removes ALL tool directories under /opt${NC}"
    echo -n -e "  ${BYELLOW}Type 'YES' to confirm:${NC} "
    read -r confirm
    [[ "$confirm" != "YES" ]] && info "Aborted." && return

    local known_tools=(
        dnsrecon Sublist3r massdns dirsearch routersploit
        bettercap Responder BloodHound.py chisel ligolo-ng
        evil-winrm peda ghidra volatility3 autopsy
        spiderfoot gophish sqlninja pacu ScoutSuite
        apktool dex2jar libbtbb ubertooth vulners
        hash-identifier bully wifite webshell
    )
    for tool in "${known_tools[@]}"; do
        remove_git_tool "$tool" || true
    done

    echo -n -e "  ${BYELLOW}Remove ALL remaining items in /opt? (y/N):${NC} "
    read -r resp
    if [[ "$resp" == "y" || "$resp" == "Y" ]]; then
        rm -rf /opt/*/
        success "Removed all directories in /opt"
    fi
}

remove_packages() {
    local description="$1"; shift
    local pkg_list=("$@")
    [[ ${#pkg_list[@]} -eq 0 ]] && return

    for pkg in "${pkg_list[@]}"; do
        if package_installed "$pkg"; then
            eval "$PKG_REMOVE $pkg" &>/dev/null && success "$pkg removed" || warn "Failed: $pkg"
        fi
    done

    if [[ "$DISTRO_CLASS" == "arch" ]]; then
        local orphans
        orphans=$(pacman -Qdtq 2>/dev/null || true)
        [[ -n "$orphans" ]] && pacman -Rns --noconfirm $orphans &>/dev/null || true
    else
        eval "$PKG_AUTOREMOVE" &>/dev/null || true
    fi
}

# ============================================================================
# FIX SECLISTS
# ============================================================================
fix_seclists_kali() {
    [[ "$DISTRO_CLASS" != "kali" ]] && return
    if [[ -d /usr/share/seclists ]]; then
        [[ ! -L /usr/share/wordlists/SecLists ]] && \
            mkdir -p /usr/share/wordlists && \
            ln -sf /usr/share/seclists /usr/share/wordlists/SecLists && \
            info "SecLists symlink created"
    elif [[ ! -d /usr/share/wordlists/SecLists ]]; then
        info "Installing SecLists..."
        git clone --depth 1 https://github.com/danielmiessler/SecLists.git \
            /usr/share/wordlists/SecLists &>/dev/null || warn "Failed to clone SecLists"
    fi
    if [[ -d /usr/share/wordlists/SecLists/.git ]]; then
        cd /usr/share/wordlists/SecLists && git pull --ff-only &>/dev/null || true
    fi
}

# ============================================================================
# EXTRA DEPS
# ============================================================================
check_extra_deps() {
    header "Checking Extra Dependencies"

    local missing=()
    command -v java   &>/dev/null || missing+=("Java")
    command -v node   &>/dev/null || missing+=("Node.js")
    command -v ruby   &>/dev/null || missing+=("Ruby")
    command -v docker &>/dev/null || missing+=("Docker")

    if [[ ${#missing[@]} -eq 0 ]]; then
        success "All extra dependencies are installed"
        return
    fi

    echo -e "  ${BYELLOW}Missing dependencies:${NC} ${missing[*]}"
    echo ""

    for dep in "${missing[@]}"; do
        echo -n -e "  ${BYELLOW}Install ${dep}? (y/N):${NC} "
        read -r resp
        [[ "$resp" != "y" && "$resp" != "Y" ]] && continue
        case "$dep" in
            Java)
                case "$DISTRO_CLASS" in
                    debian|kali) eval "$PKG_INSTALL openjdk-17-jdk" &>/dev/null ;;
                    arch)        eval "$PKG_INSTALL jdk17-openjdk" &>/dev/null ;;
                    fedora|suse) eval "$PKG_INSTALL java-17-openjdk" &>/dev/null ;;
                esac ;;
            Node.js)
                case "$DISTRO_CLASS" in
                    debian|kali) curl -fsSL https://deb.nodesource.com/setup_20.x | bash - &>/dev/null && eval "$PKG_INSTALL nodejs" &>/dev/null ;;
                    arch)        eval "$PKG_INSTALL nodejs npm" &>/dev/null ;;
                    fedora)      eval "$PKG_INSTALL nodejs" &>/dev/null ;;
                    suse)        eval "$PKG_INSTALL nodejs16" &>/dev/null ;;
                esac ;;
            Ruby)
                case "$DISTRO_CLASS" in
                    debian|kali) eval "$PKG_INSTALL ruby-full" &>/dev/null ;;
                    arch|fedora|suse) eval "$PKG_INSTALL ruby" &>/dev/null ;;
                esac ;;
            Docker)
                case "$DISTRO_CLASS" in
                    debian|kali) curl -fsSL https://get.docker.com | bash &>/dev/null ;;
                    arch)        eval "$PKG_INSTALL docker" &>/dev/null ;;
                    fedora)      eval "$PKG_INSTALL docker-ce" &>/dev/null ;;
                    suse)        eval "$PKG_INSTALL docker" &>/dev/null ;;
                esac
                systemctl enable --now docker &>/dev/null || true ;;
        esac
        success "$dep installed"
    done
}

# ============================================================================
# ALIASES
# ============================================================================
setup_aliases() {
    header "Setting Up Aliases"
    local bashrc="/root/.bashrc"
    local added=0

    declare -A aliases=(
        ["alias msf="]='alias msf="msfconsole"'
        ["alias nmapall="]='alias nmapall="nmap -p- -sV -sC -O -A"'
        ["alias gobusterdir="]='alias gobusterdir="gobuster dir -u"'
        ["alias ffufext="]='alias ffufext="ffuf -w /usr/share/wordlists/SecLists/Discovery/Web-Content/common.txt"'
        ["alias up="]='alias up="cd .."'
        ["alias ll="]='alias ll="ls -alh"'
        ["alias update-tools="]='alias update-tools="root-red-team"'
        ['export PATH="/opt']='export PATH="$PATH:/opt:/opt/*/bin:/opt/*/sbin"'
    )

    for key in "${!aliases[@]}"; do
        if ! grep -q "$key" "$bashrc" 2>/dev/null; then
            echo "${aliases[$key]}" >> "$bashrc"
            ((added++))
        fi
    done

    if ! grep -q "alias pwn=" "$bashrc" 2>/dev/null; then
        printf '%s\n' 'alias pwn='"'"'python3 -c "import pty; pty.spawn([\"/bin/bash\"])"'"'" >> "$bashrc"
        ((added++))
    fi

    if command -v docker &>/dev/null && ! grep -q "alias docker-nmap=" "$bashrc" 2>/dev/null; then
        cat >> "$bashrc" << 'EOF'
alias docker-nmap="docker run --rm -it --network host nmap/nmap"
alias docker-sqlmap="docker run --rm -it sqlmapproject/sqlmap"
alias docker-wpscan="docker run --rm -it wpscanteam/wpscan"
EOF
        ((added+=3))
    fi

    [[ $added -gt 0 ]] && success "Added $added aliases — run: source $bashrc" || info "Aliases already configured"
}

# ============================================================================
# DOCKER
# ============================================================================
pull_pen_test_containers() {
    header "Pulling Pentest Docker Images"
    ! command -v docker &>/dev/null && warn "Docker not installed." && return

    local images=(
        "kalilinux/kali-rolling" "remnux/metasploit" "wpscanteam/wpscan"
        "joshhighet/responder" "bettercap/bettercap" "nmap/nmap"
        "sqlmapproject/sqlmap" "dustyfresh/evil-winrm" "amass/amass"
        "projectdiscovery/nuclei" "projectdiscovery/httpx"
    )

    local total=${#images[@]}
    local i=0
    for img in "${images[@]}"; do
        ((i++))
        progress_bar "$i" "$total" "$img"
        if ! docker image inspect "$img" &>/dev/null; then
            docker pull "$img" &>/dev/null || true
        fi
    done
    echo ""
    success "Docker images ready"
}

# ============================================================================
# BACKUP / RESTORE
# ============================================================================
backup_configs() {
    header "Backing Up Configurations"
    local backup_dir="/root/rrt-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    local configs=(
        /root/.msf4 /root/.burp /root/.wfuzz /root/.sqlmap
        /root/.john /root/.hashcat /root/.nmap /root/.ettercap
        /root/.bettercap /root/.wireshark
    )

    local total=${#configs[@]}
    local i=0
    for cfg in "${configs[@]}"; do
        ((i++))
        progress_bar "$i" "$total" "$(basename "$cfg")"
        [[ -d "$cfg" || -f "$cfg" ]] && cp -r "$cfg" "$backup_dir/" &>/dev/null || true
    done
    echo ""

    case "$DISTRO_CLASS" in
        kali|debian) dpkg -l | grep '^ii' | awk '{print $2}' > "$backup_dir/packages.txt" ;;
        arch)        pacman -Qe > "$backup_dir/packages.txt" ;;
        fedora|suse) rpm -qa > "$backup_dir/packages.txt" ;;
    esac

    tar -czf "${backup_dir}.tar.gz" -C "$(dirname "$backup_dir")" "$(basename "$backup_dir")" &>/dev/null
    rm -rf "$backup_dir"
    success "Backup saved: ${backup_dir}.tar.gz"
}

restore_configs() {
    local backup_file=""
    if [[ $# -lt 1 ]]; then
        echo -n -e "  ${BYELLOW}Enter backup archive path (.tar.gz):${NC} "
        read -r backup_file
    else
        backup_file="$1"
    fi
    [[ ! -f "$backup_file" ]] && error "File not found: $backup_file" && return 1
    info "Restoring from: $backup_file"
    tar -xzf "$backup_file" -C / &>/dev/null || warn "Restore had issues"
    success "Restored (may need restart)"
}

# ============================================================================
# FIX ISSUES
# ============================================================================
fix_common_issues() {
    header "Fixing Common Issues"

    if [[ "$DISTRO_CLASS" == "debian" || "$DISTRO_CLASS" == "kali" ]]; then
        info "Fixing broken packages..."
        apt-get --fix-broken install -y &>/dev/null || true
        dpkg --configure -a &>/dev/null || true
    fi

    info "Upgrading pip..."
    pip3 install --upgrade pip &>/dev/null || true

    if command -v msfdb &>/dev/null; then
        info "Initializing Metasploit DB..."
        msfdb init &>/dev/null || warn "msfdb init had issues"
    fi

    info "Cleaning package cache..."
    case "$DISTRO_CLASS" in
        debian|kali) apt-get clean &>/dev/null || true ;;
        arch)        pacman -Scc --noconfirm &>/dev/null || true ;;
        fedora)      dnf clean all &>/dev/null || true ;;
        suse)        zypper clean &>/dev/null || true ;;
    esac

    fix_seclists_kali
    success "Common issues fixed"
}

# ============================================================================
# TOP 10
# ============================================================================
install_top10_kali() {
    header "Installing Top 10 Essential Tools"
    local tools=(nmap wireshark metasploit-framework burpsuite sqlmap john hashcat hydra nikto gobuster)
    local total=${#tools[@]}
    local i=0

    for tool in "${tools[@]}"; do
        ((i++))
        progress_bar "$i" "$total" "$tool"
        if ! command -v "$tool" &>/dev/null; then
            eval "$PKG_INSTALL $tool" &>/dev/null || true
        fi
    done
    echo ""
    success "Top 10 tools ready"
}

# ============================================================================
# INSTALL CATEGORIES
# ============================================================================
install_information_gathering() {
    header "Information Gathering / Reconnaissance"
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_INSTALL kali-tools-information-gathering" &>/dev/null || \
                eval "$PKG_INSTALL nmap dnsenum dnsrecon dnsutils fierce theharvester recon-ng netdiscover masscan enum4linux nbtscan onesixtyone snmpcheck smbclient ldapscripts nikto wafw00f arp-scan amap maltego" &>/dev/null ;;
        debian) eval "$PKG_INSTALL nmap dnsutils dnsenum dnsrecon fierce theharvester recon-ng netdiscover masscan enum4linux nbtscan onesixtyone snmpcheck smbclient nikto wafw00f arp-scan amap maltego lft fping hping3" &>/dev/null
                pip3 install --quiet shodan censys mmh3 2>/dev/null || true ;;
        arch)   setup_blackarch
                eval "$PKG_INSTALL nmap dnsutils dnsenum dnsrecon masscan nikto theharvester recon-ng netdiscover enum4linux nbtscan onesixtyone snmpcheck smbclient arp-scan amap maltego fping hping3 wafw00f" &>/dev/null || true ;;
        fedora) eval "$PKG_INSTALL nmap bind-utils dnsenum masscan nikto theharvester netdiscover nbtscan onesixtyone snmpcheck smbclient arp-scan fping hping3 wafw00f whois" &>/dev/null
                pip3 install --quiet shodan censys recon-ng 2>/dev/null || true ;;
        suse)   eval "$PKG_INSTALL nmap bind-utils masscan nikto theharvester netdiscover nbtscan onesixtyone snmpcheck smbclient arp-scan fping hping3 whois" &>/dev/null
                pip3 install --quiet shodan censys 2>/dev/null || true ;;
    esac
    install_git_tool "dnsrecon"  "https://github.com/darkoperator/dnsrecon.git"
    install_git_tool "sublist3r" "https://github.com/aboul3la/Sublist3r.git"
    install_git_tool "massdns"   "https://github.com/blechschmidt/massdns.git"
}

install_vulnerability_analysis() {
    header "Vulnerability Analysis"
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_INSTALL kali-tools-vulnerability" &>/dev/null || \
                eval "$PKG_INSTALL openvas gvm nikto legion lynis oscanner sqlmap skipfish wapiti whatweb" &>/dev/null ;;
        debian) eval "$PKG_INSTALL nikto lynis sqlmap wapiti whatweb oscanner legion" &>/dev/null ;;
        arch)   setup_blackarch; eval "$PKG_INSTALL nikto lynis sqlmap wapiti whatweb" &>/dev/null || true ;;
        fedora) eval "$PKG_INSTALL nikto lynis sqlmap wapiti whatweb" &>/dev/null
                install_git_tool "vulners" "https://github.com/vulnersCom/vulners-scanner.git" ;;
        suse)   eval "$PKG_INSTALL nikto lynis sqlmap wapiti whatweb" &>/dev/null ;;
    esac
}

install_web_application() {
    header "Web Application Testing"
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_INSTALL kali-tools-web" &>/dev/null || \
                eval "$PKG_INSTALL burpsuite zaproxy dirb dirbuster gobuster wfuzz ffuf sqlmap commix wpscan joomscan beef-project xsser httrack whatweb nikto skipfish" &>/dev/null ;;
        debian) eval "$PKG_INSTALL zaproxy dirb gobuster wfuzz ffuf sqlmap wpscan xsser httrack whatweb nikto skipfish commix" &>/dev/null
                pip3 install --quiet xsstrike 2>/dev/null || true
                install_git_tool "dirsearch" "https://github.com/maurosoria/dirsearch.git" ;;
        arch)   setup_blackarch
                eval "$PKG_INSTALL burpsuite zaproxy gobuster wfuzz ffuf sqlmap wpscan httrack whatweb nikto skipfish" &>/dev/null || true ;;
        fedora) eval "$PKG_INSTALL zaproxy dirb gobuster wfuzz ffuf sqlmap wpscan httrack whatweb nikto skipfish" &>/dev/null ;;
        suse)   eval "$PKG_INSTALL zaproxy gobuster wfuzz ffuf sqlmap wpscan httrack whatweb nikto skipfish" &>/dev/null ;;
    esac
}

install_exploitation() {
    header "Exploitation Frameworks"
    local msf_url="https://raw.githubusercontent.com/rapid7/metasploit-omnibus/master/config/templates/metasploit-framework-wrappers/msfupdate.erb"
    _install_msf() {
        if ! command -v msfconsole &>/dev/null; then
            curl -fsSL "$msf_url" > /tmp/msfinstall
            chmod +x /tmp/msfinstall
            /tmp/msfinstall &>/dev/null || warn "Metasploit install issues"
        fi
    }
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_INSTALL kali-tools-exploitation" &>/dev/null || \
                eval "$PKG_INSTALL metasploit-framework exploitdb beef-project xsser commix sqlmap shellnoob powersploit" &>/dev/null ;;
        debian) eval "$PKG_INSTALL exploitdb metasploit-framework commix sqlmap" &>/dev/null
                _install_msf; pip3 install --quiet pocsuite3 2>/dev/null || true
                install_git_tool "routersploit" "https://github.com/threat9/routersploit.git" ;;
        arch)   setup_blackarch; pacman -S --noconfirm metasploit exploitdb &>/dev/null || true
                install_git_tool "routersploit" "https://github.com/threat9/routersploit.git" ;;
        fedora) _install_msf; eval "$PKG_INSTALL exploitdb sqlmap commix" &>/dev/null
                install_git_tool "routersploit" "https://github.com/threat9/routersploit.git" ;;
        suse)   eval "$PKG_INSTALL sqlmap commix" &>/dev/null; _install_msf
                install_git_tool "routersploit" "https://github.com/threat9/routersploit.git" ;;
    esac
}

install_password_tools() {
    header "Password Cracking & Attacks"
    local seclists_dir="/usr/share/wordlists"
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_INSTALL kali-tools-passwords" &>/dev/null || \
                eval "$PKG_INSTALL john hashcat hydra medusa crunch cewl patator ophcrack chntpw samdump2 crowbar wordlists" &>/dev/null ;;
        debian) eval "$PKG_INSTALL john hashcat hydra medusa crunch cewl patator ophcrack chntpw samdump2 crowbar" &>/dev/null
                pip3 install --quiet hashid 2>/dev/null || true
                install_git_tool "hash-identifier" "https://github.com/nickvourd/Hash-Identifier.git"
                install_git_tool "SecLists" "https://github.com/danielmiessler/SecLists.git" "$seclists_dir" ;;
        arch)   setup_blackarch
                eval "$PKG_INSTALL john hashcat hydra medusa crunch cewl patator ophcrack chntpw samdump2 crowbar" &>/dev/null || true
                install_git_tool "SecLists" "https://github.com/danielmiessler/SecLists.git" "$seclists_dir" ;;
        fedora) eval "$PKG_INSTALL john hashcat hydra medusa crunch cewl patator ophcrack chntpw samdump2 crowbar" &>/dev/null
                install_git_tool "SecLists" "https://github.com/danielmiessler/SecLists.git" "$seclists_dir" ;;
        suse)   eval "$PKG_INSTALL john hashcat hydra medusa crunch cewl patator ophcrack chntpw samdump2" &>/dev/null
                install_git_tool "SecLists" "https://github.com/danielmiessler/SecLists.git" "$seclists_dir" ;;
    esac
}

install_wireless() {
    header "Wireless & Bluetooth Hacking"
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_INSTALL kali-tools-wireless" &>/dev/null || \
                eval "$PKG_INSTALL aircrack-ng kismet reaver bully mdk4 mdk3 wifite pixiewps bluelog bluez bluez-tools redfang ubertooth rfkill" &>/dev/null ;;
        debian) eval "$PKG_INSTALL aircrack-ng kismet reaver mdk4 mdk3 wifite bluez bluez-tools rfkill pixiewps" &>/dev/null
                install_git_tool "bully" "https://github.com/aanarchyy/bully.git" ;;
        arch)   setup_blackarch
                eval "$PKG_INSTALL aircrack-ng kismet reaver mdk4 wifite pixiewps bluez bluez-utils rfkill" &>/dev/null || true
                install_git_tool "bully" "https://github.com/aanarchyy/bully.git" ;;
        fedora) eval "$PKG_INSTALL aircrack-ng kismet reaver mdk4 wifite bluez bluez-tools pixiewps rfkill" &>/dev/null ;;
        suse)   eval "$PKG_INSTALL aircrack-ng kismet reaver bluez bluez-tools pixiewps rfkill" &>/dev/null
                install_git_tool "wifite" "https://github.com/derv82/wifite2.git" ;;
    esac
}

install_sniffing_spoofing() {
    header "Sniffing & Spoofing"
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_INSTALL kali-tools-sniffing-spoofing" &>/dev/null || \
                eval "$PKG_INSTALL wireshark tshark tcpdump dsniff ettercap-common mitmproxy scapy hping3 tcpreplay netsniff-ng yersinia macchanger" &>/dev/null ;;
        debian) eval "$PKG_INSTALL wireshark tshark tcpdump dsniff ettercap-graphical mitmproxy scapy hping3 tcpreplay netsniff-ng yersinia macchanger" &>/dev/null
                install_git_tool "bettercap" "https://github.com/bettercap/bettercap.git"
                install_git_tool "Responder" "https://github.com/lgandx/Responder.git" ;;
        arch)   setup_blackarch
                eval "$PKG_INSTALL wireshark-cli wireshark-qt tcpdump dsniff ettercap mitmproxy scapy hping3 tcpreplay netsniff-ng macchanger" &>/dev/null || true
                install_git_tool "bettercap" "https://github.com/bettercap/bettercap.git"
                install_git_tool "Responder" "https://github.com/lgandx/Responder.git" ;;
        fedora) eval "$PKG_INSTALL wireshark tshark tcpdump dsniff ettercap mitmproxy scapy hping3 tcpreplay netsniff-ng yersinia macchanger" &>/dev/null
                install_git_tool "bettercap" "https://github.com/bettercap/bettercap.git"
                install_git_tool "Responder" "https://github.com/lgandx/Responder.git" ;;
        suse)   eval "$PKG_INSTALL wireshark tshark tcpdump dsniff ettercap mitmproxy scapy hping3 tcpreplay macchanger" &>/dev/null
                install_git_tool "bettercap" "https://github.com/bettercap/bettercap.git"
                install_git_tool "Responder" "https://github.com/lgandx/Responder.git" ;;
    esac
}

install_post_exploitation() {
    header "Post-Exploitation & C2"
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_INSTALL kali-tools-post-exploitation" &>/dev/null || \
                eval "$PKG_INSTALL powershell-empire starkiller bloodhound impacket-scripts chisel ligolo-ng evil-winrm" &>/dev/null ;;
        debian) pip3 install --quiet bloodhound-py impacket 2>/dev/null || true
                install_git_tool "BloodHound.py" "https://github.com/fox-it/BloodHound.py.git"
                install_git_tool "chisel"         "https://github.com/jpillora/chisel.git"
                install_git_tool "ligolo-ng"      "https://github.com/nicocha30/ligolo-ng.git"
                install_git_tool "evil-winrm"     "https://github.com/Hackplayers/evil-winrm.git" ;;
        arch)   setup_blackarch
                pacman -S --noconfirm bloodhound impacket chisel ligolo-ng &>/dev/null || true
                pip3 install --quiet impacket bloodhound-py 2>/dev/null || true
                install_git_tool "evil-winrm" "https://github.com/Hackplayers/evil-winrm.git" ;;
        fedora) eval "$PKG_INSTALL bloodhound" &>/dev/null
                pip3 install --quiet impacket bloodhound-py 2>/dev/null || true
                install_git_tool "chisel"     "https://github.com/jpillora/chisel.git"
                install_git_tool "ligolo-ng"  "https://github.com/nicocha30/ligolo-ng.git"
                install_git_tool "evil-winrm" "https://github.com/Hackplayers/evil-winrm.git" ;;
        suse)   pip3 install --quiet impacket bloodhound-py 2>/dev/null || true
                install_git_tool "chisel"        "https://github.com/jpillora/chisel.git"
                install_git_tool "ligolo-ng"     "https://github.com/nicocha30/ligolo-ng.git"
                install_git_tool "evil-winrm"    "https://github.com/Hackplayers/evil-winrm.git"
                install_git_tool "BloodHound.py" "https://github.com/fox-it/BloodHound.py.git" ;;
    esac
}

install_reverse_engineering() {
    header "Reverse Engineering"
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_INSTALL kali-tools-reverse-engineering" &>/dev/null || \
                eval "$PKG_INSTALL radare2 ghidra gdb edb-debugger binwalk apktool dex2jar jd-gui nasm yara" &>/dev/null ;;
        debian) eval "$PKG_INSTALL radare2 gdb edb-debugger binwalk apktool dex2jar jd-gui nasm yara" &>/dev/null
                pip3 install --quiet uncompyle6 frida-tools 2>/dev/null || true
                install_git_tool "peda"   "https://github.com/longld/peda.git" "/root/peda"
                install_git_tool "ghidra" "https://github.com/NationalSecurityAgency/ghidra.git" ;;
        arch)   setup_blackarch
                eval "$PKG_INSTALL radare2 ghidra gdb binwalk apktool dex2jar nasm yara" &>/dev/null || true
                pip3 install --quiet frida-tools uncompyle6 2>/dev/null || true ;;
        fedora) eval "$PKG_INSTALL radare2 gdb edb-debugger binwalk apktool nasm yara" &>/dev/null
                pip3 install --quiet frida-tools uncompyle6 2>/dev/null || true
                install_git_tool "ghidra" "https://github.com/NationalSecurityAgency/ghidra.git" ;;
        suse)   eval "$PKG_INSTALL radare2 gdb binwalk nasm yara" &>/dev/null
                pip3 install --quiet frida-tools uncompyle6 2>/dev/null || true
                install_git_tool "ghidra" "https://github.com/NationalSecurityAgency/ghidra.git" ;;
    esac
}

install_forensics() {
    header "Digital Forensics"
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_INSTALL kali-tools-forensics" &>/dev/null || \
                eval "$PKG_INSTALL autopsy sleuthkit guymager dc3dd dcfldd foremost scalpel testdisk photorec bulk-extractor binwalk volatility afflib ewf-tools" &>/dev/null ;;
        debian) eval "$PKG_INSTALL autopsy sleuthkit foremost scalpel testdisk photorec bulk-extractor binwalk afflib-tools ewf-tools dc3dd dcfldd" &>/dev/null
                install_git_tool "volatility3" "https://github.com/volatilityfoundation/volatility3.git" ;;
        arch)   setup_blackarch
                eval "$PKG_INSTALL autopsy sleuthkit foremost scalpel testdisk photorec bulk-extractor binwalk volatility dc3dd" &>/dev/null || true ;;
        fedora) eval "$PKG_INSTALL sleuthkit foremost testdisk photorec bulk-extractor binwalk dc3dd dcfldd" &>/dev/null
                pip3 install --quiet volatility3 2>/dev/null || true
                install_git_tool "autopsy" "https://github.com/sleuthkit/autopsy.git" ;;
        suse)   eval "$PKG_INSTALL sleuthkit foremost testdisk photorec bulk-extractor binwalk dc3dd" &>/dev/null
                pip3 install --quiet volatility3 2>/dev/null || true ;;
    esac
}

install_osint_social() {
    header "OSINT & Social Engineering"
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_INSTALL kali-tools-social-engineering" &>/dev/null || \
                eval "$PKG_INSTALL set theharvester maltego recon-ng spiderfoot exiftool metagoofil gophish" &>/dev/null ;;
        debian) eval "$PKG_INSTALL theharvester exiftool metagoofil maltego recon-ng" &>/dev/null
                pip3 install --quiet sherlock holehe maigret 2>/dev/null || true
                install_git_tool "spiderfoot" "https://github.com/smicallef/spiderfoot.git"
                install_git_tool "gophish"    "https://github.com/gophish/gophish.git" ;;
        arch)   setup_blackarch
                eval "$PKG_INSTALL theharvester exiftool metagoofil maltego recon-ng spiderfoot" &>/dev/null || true
                pip3 install --quiet sherlock holehe maigret 2>/dev/null || true ;;
        fedora) eval "$PKG_INSTALL theharvester exiftool metagoofil maltego recon-ng" &>/dev/null
                pip3 install --quiet sherlock holehe maigret 2>/dev/null || true
                install_git_tool "spiderfoot" "https://github.com/smicallef/spiderfoot.git"
                install_git_tool "gophish"    "https://github.com/gophish/gophish.git" ;;
        suse)   eval "$PKG_INSTALL theharvester exiftool metagoofil maltego recon-ng" &>/dev/null
                pip3 install --quiet sherlock holehe maigret 2>/dev/null || true
                install_git_tool "spiderfoot" "https://github.com/smicallef/spiderfoot.git" ;;
    esac
}

install_database_tools() {
    header "Database Assessment"
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_INSTALL kali-tools-database" &>/dev/null || \
                eval "$PKG_INSTALL sqlmap sqlninja redis-tools postgresql-client mysql-client" &>/dev/null ;;
        debian) eval "$PKG_INSTALL sqlmap mysql-client postgresql-client redis-tools" &>/dev/null
                install_git_tool "sqlninja" "https://github.com/xxgrunge/sqlninja.git" ;;
        arch)   setup_blackarch; eval "$PKG_INSTALL sqlmap mysql-clients postgresql-client redis" &>/dev/null || true ;;
        fedora) eval "$PKG_INSTALL sqlmap mysql postgresql redis" &>/dev/null ;;
        suse)   eval "$PKG_INSTALL sqlmap mysql-client postgresql-client redis" &>/dev/null ;;
    esac
}

install_hardware_rfid_sdr() {
    header "Hardware / RFID / SDR"
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_INSTALL kali-tools-hardware kali-tools-rfid kali-tools-sdr" &>/dev/null || \
                eval "$PKG_INSTALL gnuradio hackrf rtl-sdr bladeRF fcrackzip" &>/dev/null ;;
        debian) eval "$PKG_INSTALL gnuradio hackrf rtl-sdr bladerf fcrackzip" &>/dev/null
                install_git_tool "libbtbb" "https://github.com/greatscottgadgets/libbtbb.git" ;;
        arch)   setup_blackarch; eval "$PKG_INSTALL gnuradio hackrf rtl-sdr bladerf fcrackzip" &>/dev/null || true ;;
        fedora) eval "$PKG_INSTALL gnuradio hackrf rtl-sdr bladerf fcrackzip" &>/dev/null ;;
        suse)   eval "$PKG_INSTALL gnuradio hackrf rtl-sdr fcrackzip" &>/dev/null ;;
    esac
}

install_cloud_tools() {
    header "Cloud Security"
    pip3 install --quiet pacu cloudscraper awscli 2>/dev/null || true
    install_git_tool "pacu"       "https://github.com/RhinoSecurityLabs/pacu.git"
    install_git_tool "ScoutSuite" "https://github.com/nccgroup/ScoutSuite.git"
    case "$DISTRO_CLASS" in
        kali|debian) eval "$PKG_INSTALL awscli" &>/dev/null || true ;;
    esac
}

install_mobile_tools() {
    header "Mobile Security"
    install_git_tool "apktool" "https://github.com/iBotPeaches/Apktool.git"
    pip3 install --quiet frida-tools objection 2>/dev/null || true
    case "$DISTRO_CLASS" in
        kali|debian|arch) eval "$PKG_INSTALL apktool dex2jar jadx" &>/dev/null || true ;;
        fedora)           eval "$PKG_INSTALL jadx" &>/dev/null || true ;;
    esac
}

install_all() {
    local categories=(
        install_information_gathering
        install_vulnerability_analysis
        install_web_application
        install_exploitation
        install_password_tools
        install_wireless
        install_sniffing_spoofing
        install_post_exploitation
        install_reverse_engineering
        install_forensics
        install_osint_social
        install_database_tools
        install_hardware_rfid_sdr
        install_cloud_tools
        install_mobile_tools
    )
    local total=${#categories[@]}
    local i=0
    for fn in "${categories[@]}"; do
        ((i++))
        echo ""
        echo -e "  ${DIM}[$i/$total]${NC} ${WHITE}${fn/install_/}${NC}"
        $fn
    done
    fix_seclists_kali
    setup_aliases
    check_extra_deps
    case "$DISTRO_CLASS" in
        kali) eval "$PKG_INSTALL kali-linux-everything" &>/dev/null || \
              eval "$PKG_INSTALL kali-linux-large kali-tools-top10" &>/dev/null || true ;;
        arch) setup_blackarch; pacman -S --noconfirm blackarch &>/dev/null || warn "BlackArch full install failed" ;;
    esac
}

# ============================================================================
# REMOVE CATEGORIES
# ============================================================================
remove_information_gathering() {
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_REMOVE kali-tools-information-gathering" &>/dev/null || true
                remove_packages "Info Gathering" nmap dnsenum dnsrecon dnsutils fierce theharvester recon-ng netdiscover masscan enum4linux nbtscan onesixtyone snmpcheck smbclient ldapscripts nikto wafw00f arp-scan amap maltego ;;
        debian) remove_packages "Info Gathering" nmap dnsutils dnsenum dnsrecon fierce theharvester recon-ng netdiscover masscan enum4linux nbtscan onesixtyone snmpcheck smbclient nikto wafw00f arp-scan amap maltego lft fping hping3
                pip3 uninstall -y shodan censys mmh3 &>/dev/null || true ;;
        arch)   remove_packages "Info Gathering" nmap dnsutils dnsenum dnsrecon masscan nikto theharvester recon-ng netdiscover enum4linux nbtscan onesixtyone snmpcheck smbclient arp-scan amap maltego fping hping3 wafw00f ;;
        fedora) remove_packages "Info Gathering" nmap bind-utils dnsenum masscan nikto theharvester netdiscover nbtscan onesixtyone snmpcheck smbclient arp-scan fping hping3 wafw00f whois
                pip3 uninstall -y shodan censys recon-ng &>/dev/null || true ;;
        suse)   remove_packages "Info Gathering" nmap bind-utils masscan nikto theharvester netdiscover nbtscan onesixtyone snmpcheck smbclient arp-scan fping hping3 whois
                pip3 uninstall -y shodan censys &>/dev/null || true ;;
    esac
    remove_git_tool "dnsrecon" "/opt/dnsrecon"
    remove_git_tool "sublist3r" "/opt/sublist3r"
    remove_git_tool "massdns" "/opt/massdns"
}

remove_vulnerability_analysis() {
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_REMOVE kali-tools-vulnerability" &>/dev/null || true
                remove_packages "Vuln Analysis" openvas gvm nikto legion lynis oscanner sqlmap skipfish wapiti whatweb ;;
        debian) remove_packages "Vuln Analysis" nikto lynis sqlmap wapiti whatweb oscanner legion ;;
        arch)   remove_packages "Vuln Analysis" nikto lynis sqlmap wapiti whatweb ;;
        fedora) remove_packages "Vuln Analysis" nikto lynis sqlmap wapiti whatweb; remove_git_tool "vulners" "/opt/vulners" ;;
        suse)   remove_packages "Vuln Analysis" nikto lynis sqlmap wapiti whatweb ;;
    esac
}

remove_web_application() {
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_REMOVE kali-tools-web" &>/dev/null || true
                remove_packages "Web App" burpsuite zaproxy dirb dirbuster gobuster wfuzz ffuf sqlmap commix wpscan joomscan beef-project xsser httrack whatweb nikto skipfish ;;
        debian) remove_packages "Web App" zaproxy dirb gobuster wfuzz ffuf sqlmap wpscan xsser httrack whatweb nikto skipfish commix
                pip3 uninstall -y xsstrike &>/dev/null || true
                remove_git_tool "dirsearch" "/opt/dirsearch" ;;
        arch)   remove_packages "Web App" burpsuite zaproxy gobuster wfuzz ffuf sqlmap wpscan httrack whatweb nikto skipfish ;;
        fedora) remove_packages "Web App" zaproxy dirb gobuster wfuzz ffuf sqlmap wpscan httrack whatweb nikto skipfish ;;
        suse)   remove_packages "Web App" zaproxy gobuster wfuzz ffuf sqlmap wpscan httrack whatweb nikto skipfish ;;
    esac
}

remove_exploitation() {
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_REMOVE kali-tools-exploitation" &>/dev/null || true
                remove_packages "Exploitation" metasploit-framework exploitdb beef-project xsser commix sqlmap shellnoob powersploit ;;
        debian|fedora)
                remove_packages "Exploitation" exploitdb metasploit-framework commix sqlmap
                pip3 uninstall -y pocsuite3 &>/dev/null || true
                remove_git_tool "routersploit" "/opt/routersploit"
                [[ -f /opt/metasploit-framework/bin/msfconsole ]] && rm -rf /opt/metasploit-framework ;;
        arch)   remove_packages "Exploitation" metasploit exploitdb; remove_git_tool "routersploit" "/opt/routersploit" ;;
        suse)   remove_packages "Exploitation" sqlmap commix; remove_git_tool "routersploit" "/opt/routersploit" ;;
    esac
}

remove_password_tools() {
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_REMOVE kali-tools-passwords" &>/dev/null || true
                remove_packages "Passwords" john hashcat hydra medusa crunch cewl patator ophcrack chntpw samdump2 crowbar ;;
        debian) remove_packages "Passwords" john hashcat hydra medusa crunch cewl patator ophcrack chntpw samdump2 crowbar
                pip3 uninstall -y hashid &>/dev/null || true; remove_git_tool "hash-identifier" "/opt/hash-identifier" ;;
        arch|fedora) remove_packages "Passwords" john hashcat hydra medusa crunch cewl patator ophcrack chntpw samdump2 crowbar ;;
        suse)   remove_packages "Passwords" john hashcat hydra medusa crunch cewl patator ophcrack chntpw samdump2 ;;
    esac
    if [[ -d "/usr/share/wordlists/SecLists" ]]; then
        echo -n -e "  ${BYELLOW}Remove SecLists? (y/N):${NC} "
        read -r resp
        [[ "$resp" == "y" || "$resp" == "Y" ]] && rm -rf "/usr/share/wordlists/SecLists" && success "SecLists removed"
    fi
}

remove_wireless() {
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_REMOVE kali-tools-wireless" &>/dev/null || true
                remove_packages "Wireless" aircrack-ng kismet reaver bully mdk4 mdk3 wifite pixiewps bluelog bluez bluez-tools redfang ubertooth rfkill ;;
        debian) remove_packages "Wireless" aircrack-ng kismet reaver mdk4 mdk3 wifite bluez bluez-tools rfkill pixiewps; remove_git_tool "bully" "/opt/bully" ;;
        arch)   remove_packages "Wireless" aircrack-ng kismet reaver mdk4 wifite pixiewps bluez bluez-utils rfkill; remove_git_tool "bully" "/opt/bully" ;;
        fedora) remove_packages "Wireless" aircrack-ng kismet reaver mdk4 wifite bluez bluez-tools pixiewps rfkill ;;
        suse)   remove_packages "Wireless" aircrack-ng kismet reaver bluez bluez-tools pixiewps rfkill; remove_git_tool "wifite" "/opt/wifite" ;;
    esac
}

remove_sniffing_spoofing() {
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_REMOVE kali-tools-sniffing-spoofing" &>/dev/null || true
                remove_packages "Sniffing" wireshark tshark tcpdump dsniff ettercap-common mitmproxy scapy hping3 tcpreplay netsniff-ng yersinia macchanger ;;
        debian) remove_packages "Sniffing" wireshark tshark tcpdump dsniff ettercap-graphical mitmproxy scapy hping3 tcpreplay netsniff-ng yersinia macchanger
                remove_git_tool "bettercap" "/opt/bettercap"; remove_git_tool "Responder" "/opt/Responder" ;;
        arch)   remove_packages "Sniffing" wireshark-cli wireshark-qt tcpdump dsniff ettercap mitmproxy scapy hping3 tcpreplay netsniff-ng macchanger
                remove_git_tool "bettercap" "/opt/bettercap"; remove_git_tool "Responder" "/opt/Responder" ;;
        fedora) remove_packages "Sniffing" wireshark tshark tcpdump dsniff ettercap mitmproxy scapy hping3 tcpreplay netsniff-ng yersinia macchanger
                remove_git_tool "bettercap" "/opt/bettercap"; remove_git_tool "Responder" "/opt/Responder" ;;
        suse)   remove_packages "Sniffing" wireshark tshark tcpdump dsniff ettercap mitmproxy scapy hping3 tcpreplay macchanger
                remove_git_tool "bettercap" "/opt/bettercap"; remove_git_tool "Responder" "/opt/Responder" ;;
    esac
}

remove_post_exploitation() {
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_REMOVE kali-tools-post-exploitation" &>/dev/null || true
                remove_packages "Post-Exploit" powershell-empire starkiller bloodhound impacket-scripts chisel ligolo-ng evil-winrm ;;
        debian|fedora|suse)
                pip3 uninstall -y bloodhound-py impacket &>/dev/null || true
                remove_git_tool "BloodHound.py" "/opt/BloodHound.py"
                remove_git_tool "chisel"         "/opt/chisel"
                remove_git_tool "ligolo-ng"      "/opt/ligolo-ng"
                remove_git_tool "evil-winrm"     "/opt/evil-winrm" ;;
        arch)   remove_packages "Post-Exploit" bloodhound impacket chisel ligolo-ng
                pip3 uninstall -y impacket bloodhound-py &>/dev/null || true
                remove_git_tool "evil-winrm" "/opt/evil-winrm" ;;
    esac
}

remove_reverse_engineering() {
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_REMOVE kali-tools-reverse-engineering" &>/dev/null || true
                remove_packages "RE" radare2 ghidra gdb edb-debugger binwalk apktool dex2jar jd-gui nasm yara ;;
        debian) remove_packages "RE" radare2 gdb edb-debugger binwalk apktool dex2jar jd-gui nasm yara
                pip3 uninstall -y uncompyle6 frida-tools &>/dev/null || true
                remove_git_tool "peda" "/root/peda"; remove_git_tool "ghidra" "/opt/ghidra" ;;
        arch)   remove_packages "RE" radare2 ghidra gdb binwalk apktool dex2jar nasm yara
                pip3 uninstall -y frida-tools uncompyle6 &>/dev/null || true ;;
        fedora) remove_packages "RE" radare2 gdb edb-debugger binwalk apktool nasm yara
                pip3 uninstall -y frida-tools uncompyle6 &>/dev/null || true; remove_git_tool "ghidra" "/opt/ghidra" ;;
        suse)   remove_packages "RE" radare2 gdb binwalk nasm yara
                pip3 uninstall -y frida-tools uncompyle6 &>/dev/null || true; remove_git_tool "ghidra" "/opt/ghidra" ;;
    esac
}

remove_forensics() {
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_REMOVE kali-tools-forensics" &>/dev/null || true
                remove_packages "Forensics" autopsy sleuthkit guymager dc3dd dcfldd foremost scalpel testdisk photorec bulk-extractor binwalk volatility afflib ewf-tools ;;
        debian) remove_packages "Forensics" autopsy sleuthkit foremost scalpel testdisk photorec bulk-extractor binwalk afflib-tools ewf-tools dc3dd dcfldd
                remove_git_tool "volatility3" "/opt/volatility3" ;;
        arch)   remove_packages "Forensics" autopsy sleuthkit foremost scalpel testdisk photorec bulk-extractor binwalk volatility dc3dd ;;
        fedora) remove_packages "Forensics" sleuthkit foremost testdisk photorec bulk-extractor binwalk dc3dd dcfldd
                pip3 uninstall -y volatility3 &>/dev/null || true; remove_git_tool "autopsy" "/opt/autopsy" ;;
        suse)   remove_packages "Forensics" sleuthkit foremost testdisk photorec bulk-extractor binwalk dc3dd
                pip3 uninstall -y volatility3 &>/dev/null || true ;;
    esac
}

remove_osint_social() {
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_REMOVE kali-tools-social-engineering" &>/dev/null || true
                remove_packages "OSINT" set theharvester maltego recon-ng spiderfoot exiftool metagoofil gophish ;;
        debian|fedora|suse)
                remove_packages "OSINT" theharvester exiftool metagoofil maltego recon-ng
                pip3 uninstall -y sherlock holehe maigret &>/dev/null || true
                remove_git_tool "spiderfoot" "/opt/spiderfoot"; remove_git_tool "gophish" "/opt/gophish" ;;
        arch)   remove_packages "OSINT" theharvester exiftool metagoofil maltego recon-ng spiderfoot
                pip3 uninstall -y sherlock holehe maigret &>/dev/null || true ;;
    esac
}

remove_database_tools() {
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_REMOVE kali-tools-database" &>/dev/null || true
                remove_packages "Database" sqlmap sqlninja redis-tools postgresql-client mysql-client ;;
        debian) remove_packages "Database" sqlmap mysql-client postgresql-client redis-tools; remove_git_tool "sqlninja" "/opt/sqlninja" ;;
        arch)   remove_packages "Database" sqlmap mysql-clients postgresql-client redis ;;
        fedora) remove_packages "Database" sqlmap mysql postgresql redis ;;
        suse)   remove_packages "Database" sqlmap mysql-client postgresql-client redis ;;
    esac
}

remove_hardware_rfid_sdr() {
    case "$DISTRO_CLASS" in
        kali)   eval "$PKG_REMOVE kali-tools-hardware kali-tools-rfid kali-tools-sdr" &>/dev/null || true
                remove_packages "Hardware" gnuradio hackrf rtl-sdr bladeRF fcrackzip ;;
        debian) remove_packages "Hardware" gnuradio hackrf rtl-sdr bladerf fcrackzip
                remove_git_tool "libbtbb" "/opt/libbtbb" ;;
        arch|fedora) remove_packages "Hardware" gnuradio hackrf rtl-sdr bladerf fcrackzip ;;
        suse)   remove_packages "Hardware" gnuradio hackrf rtl-sdr fcrackzip ;;
    esac
}

remove_cloud_tools() {
    pip3 uninstall -y pacu cloudscraper awscli &>/dev/null || true
    remove_git_tool "pacu" "/opt/pacu"
    remove_git_tool "ScoutSuite" "/opt/ScoutSuite"
    remove_packages "Cloud" awscli &>/dev/null || true
}

remove_mobile_tools() {
    pip3 uninstall -y frida-tools objection &>/dev/null || true
    remove_git_tool "apktool" "/opt/apktool"
    remove_git_tool "dex2jar" "/opt/dex2jar"
    case "$DISTRO_CLASS" in
        kali|debian|arch) remove_packages "Mobile" apktool dex2jar jadx ;;
        fedora)           remove_packages "Mobile" jadx ;;
    esac
}

remove_blackarch_repo() {
    if pacman -Qg 2>/dev/null | grep -q blackarch; then
        echo -n -e "  ${BYELLOW}Remove BlackArch repo? (y/N):${NC} "
        read -r resp
        if [[ "$resp" == "y" || "$resp" == "Y" ]]; then
            rm -f /etc/pacman.d/blackarch-mirrorlist &>/dev/null || true
            sed -i '/\[blackarch\]/,+1d' /etc/pacman.conf &>/dev/null || true
            pacman -Sy &>/dev/null || true
            success "BlackArch repository removed"
        fi
    fi
}

# ============================================================================
# MENUS
# ============================================================================
show_main_menu() {
    echo ""
    echo -e "${BRED}  ╔══════════════════════════════════════╗${NC}"
    echo -e "${BRED}  ║${NC}${WHITE}           ROOT RED TEAM              ${NC}${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}${DIM}         Main Control Panel           ${NC}${BRED}║${NC}"
    echo -e "${BRED}  ╠══════════════════════════════════════╣${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}I${NC}  ${DIM}|${NC} Install Tools                  ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}R${NC}  ${DIM}|${NC} Remove Tools                   ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}U${NC}  ${DIM}|${NC} Update Git Tools               ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}F${NC}  ${DIM}|${NC} Fix Common Issues              ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}B${NC}  ${DIM}|${NC} Backup Configs                 ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}C${NC}  ${DIM}|${NC} Restore Configs                ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}D${NC}  ${DIM}|${NC} Pull Docker Images             ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}T${NC}  ${DIM}|${NC} Install Top 10                 ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}V${NC}  ${DIM}|${NC} Check for Updates              ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}Q${NC}  ${DIM}|${NC} Exit                           ${BRED}║${NC}"
    echo -e "${BRED}  ╚══════════════════════════════════════╝${NC}"
    echo ""
    echo -n -e "  ${BYELLOW}root@red-team${NC}${DIM}:~#${NC} "
    read -r main_choice
    echo ""
}

show_install_menu() {
    echo ""
    echo -e "${BRED}  ╔══════════════════════════════════════╗${NC}"
    echo -e "${BRED}  ║${NC}${WHITE}          Install Options              ${NC}${BRED}║${NC}"
    echo -e "${BRED}  ╠══════════════════════════════════════╣${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}1${NC}  ${DIM}|${NC} Auto-detect & Install ALL      ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}2${NC}  ${DIM}|${NC} Select Categories              ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}3${NC}  ${DIM}|${NC} Manual Distro + Categories     ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}4${NC}  ${DIM}|${NC} Install EVERYTHING             ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}B${NC}  ${DIM}|${NC} Back                          ${BRED}║${NC}"
    echo -e "${BRED}  ╚══════════════════════════════════════╝${NC}"
    echo ""
    echo -n -e "  ${BYELLOW}root@red-team${NC}${DIM}:~#${NC} "
    read -r inst_choice
    echo ""
}

show_category_menu() {
    echo ""
    echo -e "${BRED}  ╔══════════════════════════════════════╗${NC}"
    echo -e "${BRED}  ║${NC}${WHITE}        Select Categories              ${NC}${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}${DIM}    Comma-separated e.g. 1,3,5         ${NC}${BRED}║${NC}"
    echo -e "${BRED}  ╠══════════════════════════════════════╣${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} 1${NC}  ${DIM}|${NC} Information Gathering         ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} 2${NC}  ${DIM}|${NC} Vulnerability Analysis        ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} 3${NC}  ${DIM}|${NC} Web Application Testing       ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} 4${NC}  ${DIM}|${NC} Exploitation Frameworks       ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} 5${NC}  ${DIM}|${NC} Password Cracking             ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} 6${NC}  ${DIM}|${NC} Wireless / Bluetooth          ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} 7${NC}  ${DIM}|${NC} Sniffing & Spoofing           ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} 8${NC}  ${DIM}|${NC} Post-Exploitation & C2        ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} 9${NC}  ${DIM}|${NC} Reverse Engineering           ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}10${NC}  ${DIM}|${NC} Digital Forensics             ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}11${NC}  ${DIM}|${NC} OSINT & Social Engineering    ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}12${NC}  ${DIM}|${NC} Database Assessment           ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}13${NC}  ${DIM}|${NC} Hardware / RFID / SDR         ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}14${NC}  ${DIM}|${NC} Cloud Security                ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}15${NC}  ${DIM}|${NC} Mobile Security               ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} A${NC}  ${DIM}|${NC} ALL Categories                ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} B${NC}  ${DIM}|${NC} Back                          ${BRED}║${NC}"
    echo -e "${BRED}  ╚══════════════════════════════════════╝${NC}"
    echo ""
    echo -n -e "  ${BYELLOW}root@red-team${NC}${DIM}:~#${NC} "
    read -r cat_choice
    echo ""
}

show_remove_menu() {
    echo ""
    echo -e "${BRED}  ╔══════════════════════════════════════╗${NC}"
    echo -e "${BRED}  ║${NC}${WHITE}         Remove Options                ${NC}${BRED}║${NC}"
    echo -e "${BRED}  ╠══════════════════════════════════════╣${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} 1${NC}  ${DIM}|${NC} Information Gathering         ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} 2${NC}  ${DIM}|${NC} Vulnerability Analysis        ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} 3${NC}  ${DIM}|${NC} Web Application Testing       ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} 4${NC}  ${DIM}|${NC} Exploitation Frameworks       ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} 5${NC}  ${DIM}|${NC} Password Cracking             ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} 6${NC}  ${DIM}|${NC} Wireless / Bluetooth          ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} 7${NC}  ${DIM}|${NC} Sniffing & Spoofing           ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} 8${NC}  ${DIM}|${NC} Post-Exploitation & C2        ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} 9${NC}  ${DIM}|${NC} Reverse Engineering           ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}10${NC}  ${DIM}|${NC} Digital Forensics             ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}11${NC}  ${DIM}|${NC} OSINT & Social Engineering    ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}12${NC}  ${DIM}|${NC} Database Assessment           ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}13${NC}  ${DIM}|${NC} Hardware / RFID / SDR         ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}14${NC}  ${DIM}|${NC} Cloud Security                ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}15${NC}  ${DIM}|${NC} Mobile Security               ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} A${NC}  ${DIM}|${NC} REMOVE ALL                    ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} G${NC}  ${DIM}|${NC} Remove All Git Tools /opt     ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} B${NC}  ${DIM}|${NC} Remove BlackArch Repo         ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN} Q${NC}  ${DIM}|${NC} Back                          ${BRED}║${NC}"
    echo -e "${BRED}  ╚══════════════════════════════════════╝${NC}"
    echo ""
    echo -n -e "  ${BYELLOW}root@red-team${NC}${DIM}:~#${NC} "
    read -r remove_choice
    echo ""
}

show_distro_menu() {
    echo ""
    echo -e "${BRED}  ╔══════════════════════════════════════╗${NC}"
    echo -e "${BRED}  ║${NC}${WHITE}         Select Distribution           ${NC}${BRED}║${NC}"
    echo -e "${BRED}  ╠══════════════════════════════════════╣${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}1${NC}  ${DIM}|${NC} Kali Linux                    ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}2${NC}  ${DIM}|${NC} Arch / BlackArch              ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}3${NC}  ${DIM}|${NC} Debian / Ubuntu / Parrot      ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}4${NC}  ${DIM}|${NC} Fedora / RHEL / CentOS        ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}5${NC}  ${DIM}|${NC} openSUSE                      ${BRED}║${NC}"
    echo -e "${BRED}  ║${NC}  ${BGREEN}B${NC}  ${DIM}|${NC} Back                          ${BRED}║${NC}"
    echo -e "${BRED}  ╚══════════════════════════════════════╝${NC}"
    echo ""
    echo -n -e "  ${BYELLOW}root@red-team${NC}${DIM}:~#${NC} "
    read -r dc
    case "$dc" in
        1) DISTRO_CLASS="kali" ;;
        2) DISTRO_CLASS="arch" ;;
        3) DISTRO_CLASS="debian" ;;
        4) DISTRO_CLASS="fedora" ;;
        5) DISTRO_CLASS="suse" ;;
        b|B) return 1 ;;
        *)   warn "Invalid" ; return 1 ;;
    esac
    return 0
}

install_selected_categories() {
    local selection="$1"
    [[ "$selection" == "A" || "$selection" == "a" ]] && install_all && return
    IFS=',' read -ra cats <<< "$(echo "$selection" | tr -d ' ')"
    for c in "${cats[@]}"; do
        case "$c" in
            1)  install_information_gathering ;;
            2)  install_vulnerability_analysis ;;
            3)  install_web_application ;;
            4)  install_exploitation ;;
            5)  install_password_tools ;;
            6)  install_wireless ;;
            7)  install_sniffing_spoofing ;;
            8)  install_post_exploitation ;;
            9)  install_reverse_engineering ;;
            10) install_forensics ;;
            11) install_osint_social ;;
            12) install_database_tools ;;
            13) install_hardware_rfid_sdr ;;
            14) install_cloud_tools ;;
            15) install_mobile_tools ;;
            *)  warn "Unknown: $c" ;;
        esac
    done
}

remove_selected_categories() {
    local selection="$1"
    if [[ "$selection" == "A" || "$selection" == "a" ]]; then
        remove_information_gathering; remove_vulnerability_analysis; remove_web_application
        remove_exploitation; remove_password_tools; remove_wireless; remove_sniffing_spoofing
        remove_post_exploitation; remove_reverse_engineering; remove_forensics
        remove_osint_social; remove_database_tools; remove_hardware_rfid_sdr
        remove_cloud_tools; remove_mobile_tools
        return
    fi
    IFS=',' read -ra cats <<< "$(echo "$selection" | tr -d ' ')"
    for c in "${cats[@]}"; do
        case "$c" in
            1)  remove_information_gathering ;;
            2)  remove_vulnerability_analysis ;;
            3)  remove_web_application ;;
            4)  remove_exploitation ;;
            5)  remove_password_tools ;;
            6)  remove_wireless ;;
            7)  remove_sniffing_spoofing ;;
            8)  remove_post_exploitation ;;
            9)  remove_reverse_engineering ;;
            10) remove_forensics ;;
            11) remove_osint_social ;;
            12) remove_database_tools ;;
            13) remove_hardware_rfid_sdr ;;
            14) remove_cloud_tools ;;
            15) remove_mobile_tools ;;
            G|g) remove_all_git_tools ;;
            B|b) remove_blackarch_repo ;;
            *)  warn "Unknown: $c" ;;
        esac
    done
}

# ============================================================================
# POST INSTALL
# ============================================================================
post_install_msg() {
    echo ""
    divider
    echo ""
    loading_bar "Finalizing installation" 1.0
    echo ""
    echo -e "${BGREEN}  Installation Complete!${NC}"
    echo ""
    echo -e "  ${DIM}Distro     :${NC} ${WHITE}$DISTRO_NAME${NC}"
    echo -e "  ${DIM}PM         :${NC} ${WHITE}$PKG_MGR${NC}"
    echo -e "  ${DIM}Log File   :${NC} ${WHITE}$LOG_FILE${NC}"
    echo ""
    echo -e "  ${BYELLOW}Post-install notes:${NC}"
    echo -e "  ${DIM}  - Metasploit  : run 'msfdb init' first time${NC}"
    echo -e "  ${DIM}  - Wireshark   : add user to 'wireshark' group${NC}"
    echo -e "  ${DIM}  - Aliases     : run 'source /root/.bashrc'${NC}"
    echo ""
    if [[ -d /opt ]]; then
        echo -e "  ${BYELLOW}Installed tools in /opt:${NC}"
        ls -1 /opt/ 2>/dev/null | while read -r d; do
            echo -e "  ${DIM}  - $d${NC}"
        done
    fi
    echo ""
    divider
    echo ""
    type_text "  Happy Hacking!" 0.04 "$BRED"
    echo ""
}

# ============================================================================
# SELF INSTALL
# ============================================================================
self_install() {
    local target="/usr/local/bin/root-red-team"
    if [[ "$0" != "$target" ]]; then
        if cp "$0" "$target" &>/dev/null; then
            chmod +x "$target"
            info "Installed to $target — run 'root-red-team' anytime"
        fi
    fi
}

# ============================================================================
# MAIN
# ============================================================================
main() {
    # Handle --no-update-check flag
    local skip_update=0
    for arg in "$@"; do
        [[ "$arg" == "--no-update-check" ]] && skip_update=1
    done

    banner
    check_root
    detect_distro
    classify_distro

    # System info line
    echo -e "  ${DIM}System  :${NC} ${WHITE}${DISTRO_NAME:-Unknown}${NC}  ${DIM}|${NC}  ${WHITE}${DISTRO_CLASS:-unknown}${NC}  ${DIM}|${NC}  ${WHITE}$(uname -m)${NC}"
    echo -e "  ${DIM}Log     :${NC} ${BCYAN}${LOG_FILE}${NC}"
    echo ""

    [[ $skip_update -eq 0 ]] && check_for_updates

    self_install

    while true; do
        show_main_menu

        case "$main_choice" in
            I|i)
                while true; do
                    show_install_menu
                    case "$inst_choice" in
                        1)
                            [[ "$DISTRO_CLASS" == "unknown" ]] && { show_distro_menu || continue; }
                            setup_pm; install_prereqs || continue
                            install_all; post_install_msg; break 2 ;;
                        2)
                            [[ "$DISTRO_CLASS" == "unknown" ]] && { show_distro_menu || continue; }
                            setup_pm; install_prereqs || continue
                            while true; do
                                show_category_menu
                                [[ "$cat_choice" == "b" || "$cat_choice" == "B" ]] && break
                                install_selected_categories "$cat_choice"
                                echo -n -e "  ${BYELLOW}Install more? (y/N):${NC} "; read -r more
                                [[ "$more" != "y" && "$more" != "Y" ]] && break
                            done
                            fix_seclists_kali; setup_aliases; check_extra_deps
                            post_install_msg; break 2 ;;
                        3)
                            show_distro_menu || continue
                            setup_pm; install_prereqs || continue
                            while true; do
                                show_category_menu
                                [[ "$cat_choice" == "b" || "$cat_choice" == "B" ]] && break
                                install_selected_categories "$cat_choice"
                                echo -n -e "  ${BYELLOW}Install more? (y/N):${NC} "; read -r more
                                [[ "$more" != "y" && "$more" != "Y" ]] && break
                            done
                            fix_seclists_kali; setup_aliases; check_extra_deps
                            post_install_msg; break 2 ;;
                        4)
                            [[ "$DISTRO_CLASS" == "unknown" ]] && { show_distro_menu || continue; }
                            setup_pm; install_prereqs || continue; install_all
                            case "$DISTRO_CLASS" in
                                kali)   eval "$PKG_INSTALL kali-linux-everything" &>/dev/null || \
                                        eval "$PKG_INSTALL kali-linux-large" &>/dev/null || true ;;
                                arch)   setup_blackarch; pacman -S --noconfirm blackarch &>/dev/null || true ;;
                                fedora) eval "$PKG_INSTALL @security-lab" &>/dev/null || true ;;
                            esac
                            post_install_msg; break 2 ;;
                        b|B) break ;;
                        *)   warn "Invalid choice" ;;
                    esac
                done ;;

            R|r)
                [[ "$DISTRO_CLASS" == "unknown" ]] && { show_distro_menu || continue; }
                setup_pm
                while true; do
                    show_remove_menu
                    [[ "$remove_choice" == "q" || "$remove_choice" == "Q" ]] && break
                    remove_selected_categories "$remove_choice"
                    echo -n -e "  ${BYELLOW}Remove more? (y/N):${NC} "; read -r more
                    [[ "$more" != "y" && "$more" != "Y" ]] && break
                done ;;

            U|u)
                [[ "$DISTRO_CLASS" == "unknown" ]] && { show_distro_menu || continue; }
                update_all_git_tools
                echo -n -e "  ${BYELLOW}Press Enter to continue...${NC} "; read -r ;;

            F|f)
                [[ "$DISTRO_CLASS" == "unknown" ]] && { show_distro_menu || continue; }
                setup_pm; fix_common_issues
                echo -n -e "  ${BYELLOW}Press Enter to continue...${NC} "; read -r ;;

            B|b)
                backup_configs
                echo -n -e "  ${BYELLOW}Press Enter to continue...${NC} "; read -r ;;

            C|c)
                restore_configs
                echo -n -e "  ${BYELLOW}Press Enter to continue...${NC} "; read -r ;;

            D|d)
                if ! command -v docker &>/dev/null; then
                    warn "Docker not installed. Use option F to install it."
                else
                    pull_pen_test_containers
                fi
                echo -n -e "  ${BYELLOW}Press Enter to continue...${NC} "; read -r ;;

            T|t)
                [[ "$DISTRO_CLASS" == "unknown" ]] && { show_distro_menu || continue; }
                setup_pm; install_top10_kali
                echo -n -e "  ${BYELLOW}Press Enter to continue...${NC} "; read -r ;;

            V|v)
                rm -f "$UPDATE_CACHE" &>/dev/null || true
                check_for_updates
                echo -n -e "  ${BYELLOW}Press Enter to continue...${NC} "; read -r ;;

            Q|q)
                echo ""
                type_text "  Exiting Root Red Team..." 0.03 "$BRED"
                echo -e "  ${DIM}Log saved to: $LOG_FILE${NC}"
                echo ""
                tput cnorm 2>/dev/null || true
                exit 0 ;;

            *)
                warn "Invalid option. Choose from the menu above." ;;
        esac
    done
}

main "$@"
