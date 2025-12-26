#!/usr/bin/env bash
set -euo pipefail

#####################################
#  Fully Supported LXD Installer
#  Ubuntu (Snap) | Debian (APT)
#####################################

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "Please run as root or with sudo"
        exit 1
    fi
}

detect_os() {
    if [ -r /etc/os-release ]; then
        . /etc/os-release
        OS_ID="$ID"
        OS_VERSION_ID="$VERSION_ID"
        OS_NAME="$PRETTY_NAME"
    else
        echo "Cannot detect OS"
        exit 1
    fi
}

install_common_deps() {
    apt-get update -y
    apt-get install -y curl uidmap iproute2 ca-certificates
}

install_lxd_ubuntu() {
    echo "Detected Ubuntu – installing LXD via Snap"

    apt-get install -y snapd
    systemctl enable --now snapd.socket

    if [ ! -L /snap ]; then
        ln -s /var/lib/snapd/snap /snap || true
    fi

    snap install lxd --channel=latest/stable
    systemctl enable --now snap.lxd.daemon
}

install_lxd_debian() {
    echo "Detected Debian – installing LXD via APT"

    apt-get install -y lxd lxd-client
    systemctl enable --now lxd

    # Required UID/GID mappings on Debian
    if ! grep -q "^root:" /etc/subuid; then
        echo "root:100000:65536" >> /etc/subuid
    fi

    if ! grep -q "^root:" /etc/subgid; then
        echo "root:100000:65536" >> /etc/subgid
    fi
}

configure_user() {
    TARGET_USER="${SUDO_USER:-root}"

    if ! id "$TARGET_USER" &>/dev/null; then
        return
    fi

    if ! groups "$TARGET_USER" | grep -q '\blxd\b'; then
        usermod -aG lxd "$TARGET_USER"
        echo "User $TARGET_USER added to lxd group (re-login required)"
    fi
}

validate_install() {
    if ! systemctl is-active --quiet lxd; then
        echo "LXD service is not running"
        exit 1
    fi

    lxc version
}

main() {
    require_root
    detect_os
    install_common_deps

    case "$OS_ID" in
        ubuntu)
            install_lxd_ubuntu
            ;;
        debian)
            install_lxd_debian
            ;;
        *)
            echo "Unsupported OS: $OS_NAME"
            exit 1
            ;;
    esac

    configure_user
    validate_install

    echo
    echo "LXD installation complete"
    echo "Log out and log back in to use LXD as a non-root user"
    echo "Run: lxd init"
}

main
