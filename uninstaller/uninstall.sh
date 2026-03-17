#!/bin/bash
set -euo pipefail

# OpenClaw Uninstaller for macOS and Linux
# Usage: bash uninstall.sh

BOLD='\033[1m'
ACCENT='\033[38;2;255;77;77m'
INFO='\033[38;2;136;146;176m'
SUCCESS='\033[38;2;0;229;204m'
WARN='\033[38;2;255;176;32m'
ERROR='\033[38;2;230;57;70m'
MUTED='\033[38;2;90;100;128m'
NC='\033[0m'

ui_info() {
    echo -e "${INFO}${1}${NC}"
}

ui_success() {
    echo -e "${SUCCESS}✓${NC} ${1}"
}

ui_warn() {
    echo -e "${WARN}⚠${NC} ${1}"
}

ui_error() {
    echo -e "${ERROR}✗${NC} ${1}" >&2
}

ui_step() {
    echo -e "${BOLD}${ACCENT}▸${NC} ${BOLD}${1}${NC}"
}

is_root() {
    [[ "${EUID:-$(id -u)}" -eq 0 ]]
}

confirm_uninstall() {
    echo ""
    echo -e "${BOLD}${ACCENT}OpenClaw Uninstaller${NC}"
    echo ""
    ui_warn "This will remove:"
    echo "  • OpenClaw CLI and Gateway"
    echo "  • Configuration files in ~/.openclaw"
    echo "  • Global npm packages (openclaw, @openclaw/*)"
    echo "  • Shell integration (if installed)"
    echo ""
    
    if command -v gum >/dev/null 2>&1; then
        if ! gum confirm "Continue with uninstallation?"; then
            ui_info "Uninstallation cancelled"
            exit 0
        fi
    else
        read -p "Continue with uninstallation? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            ui_info "Uninstallation cancelled"
            exit 0
        fi
    fi
}

stop_gateway() {
    ui_step "Stopping OpenClaw Gateway"
    
    if command -v openclaw >/dev/null 2>&1; then
        openclaw gateway stop 2>/dev/null || true
        ui_success "Gateway stopped"
    else
        ui_info "OpenClaw CLI not found, skipping gateway stop"
    fi
}

uninstall_npm_packages() {
    ui_step "Removing npm packages"
    
    if ! command -v npm >/dev/null 2>&1; then
        ui_warn "npm not found, skipping npm package removal"
        return
    fi
    
    local packages=(
        "openclaw"
        "@openclaw/gateway"
        "@openclaw/cli"
    )
    
    for pkg in "${packages[@]}"; do
        if npm list -g "$pkg" >/dev/null 2>&1; then
            if is_root; then
                npm uninstall -g "$pkg" >/dev/null 2>&1 || true
            else
                sudo npm uninstall -g "$pkg" >/dev/null 2>&1 || true
            fi
            ui_success "Removed $pkg"
        fi
    done
}

remove_config_files() {
    ui_step "Removing configuration files"
    
    local openclaw_dir="${HOME}/.openclaw"
    
    if [[ -d "$openclaw_dir" ]]; then
        read -p "Remove ~/.openclaw directory? This will delete all your data. (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$openclaw_dir"
            ui_success "Removed ~/.openclaw"
        else
            ui_info "Kept ~/.openclaw directory"
        fi
    else
        ui_info "~/.openclaw not found"
    fi
}

remove_shell_integration() {
    ui_step "Removing shell integration"
    
    local shells=("bash" "zsh" "fish")
    local removed=0
    
    for shell in "${shells[@]}"; do
        local rc_file=""
        case "$shell" in
            bash)
                rc_file="${HOME}/.bashrc"
                [[ ! -f "$rc_file" ]] && rc_file="${HOME}/.bash_profile"
                ;;
            zsh)
                rc_file="${HOME}/.zshrc"
                ;;
            fish)
                rc_file="${HOME}/.config/fish/config.fish"
                ;;
        esac
        
        if [[ -f "$rc_file" ]]; then
            if grep -q "openclaw" "$rc_file" 2>/dev/null; then
                # Create backup
                cp "$rc_file" "${rc_file}.backup.$(date +%s)"
                
                # Remove openclaw-related lines
                sed -i.tmp '/openclaw/d' "$rc_file" 2>/dev/null || \
                    sed -i '' '/openclaw/d' "$rc_file" 2>/dev/null || true
                rm -f "${rc_file}.tmp"
                
                ui_success "Removed integration from $rc_file"
                removed=$((removed + 1))
            fi
        fi
    done
    
    if [[ $removed -eq 0 ]]; then
        ui_info "No shell integration found"
    fi
}

remove_systemd_service() {
    ui_step "Checking for systemd service"
    
    local service_file="${HOME}/.config/systemd/user/openclaw-gateway.service"
    
    if [[ -f "$service_file" ]]; then
        systemctl --user stop openclaw-gateway 2>/dev/null || true
        systemctl --user disable openclaw-gateway 2>/dev/null || true
        rm -f "$service_file"
        systemctl --user daemon-reload 2>/dev/null || true
        ui_success "Removed systemd service"
    else
        ui_info "No systemd service found"
    fi
}

remove_launchd_service() {
    ui_step "Checking for launchd service"
    
    local plist_file="${HOME}/Library/LaunchAgents/ai.openclaw.gateway.plist"
    
    if [[ -f "$plist_file" ]]; then
        launchctl unload "$plist_file" 2>/dev/null || true
        rm -f "$plist_file"
        ui_success "Removed launchd service"
    else
        ui_info "No launchd service found"
    fi
}

cleanup_cache() {
    ui_step "Cleaning up cache"
    
    local cache_dirs=(
        "${HOME}/.cache/openclaw"
        "${HOME}/Library/Caches/openclaw"
    )
    
    for dir in "${cache_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
            ui_success "Removed $dir"
        fi
    done
}

main() {
    echo ""
    confirm_uninstall
    echo ""
    
    stop_gateway
    
    # Remove services first
    if [[ "$(uname -s)" == "Darwin" ]]; then
        remove_launchd_service
    else
        remove_systemd_service
    fi
    
    uninstall_npm_packages
    remove_shell_integration
    cleanup_cache
    remove_config_files
    
    echo ""
    ui_success "OpenClaw has been uninstalled"
    echo ""
    ui_info "Note: Node.js was not removed (it may be used by other applications)"
    ui_info "If you want to remove Node.js, please do so manually"
    echo ""
    ui_info "Please restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
    echo ""
}

main "$@"
