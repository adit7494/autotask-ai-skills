#!/usr/bin/env bash
#
# Autotask AI Skills Installer
# Installs Autotask PSA skills for various AI coding assistants
#
# Usage:
#   bash install.sh              # Interactive - choose which tools to install
#   bash install.sh --all        # Install for all detected tools
#   bash install.sh --tool claude # Install for specific tool
#   bash install.sh --help       # Show help
#

set -euo pipefail

# ─── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ─── Helpers ───────────────────────────────────────────────────────────────────
info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC}   $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $1"; }
error()   { echo -e "${RED}[ERR]${NC}  $1"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"

# ─── Help ──────────────────────────────────────────────────────────────────────
show_help() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║           Autotask AI Skills Installer v1.0.0               ║
╚══════════════════════════════════════════════════════════════╝

USAGE:
    bash install.sh [OPTIONS]

OPTIONS:
    --tool <name>    Install for a specific AI tool
    --all            Install for all detected AI tools
    --help           Show this help message

SUPPORTED TOOLS:
    claude     Claude Code (Anthropic)
    cursor     Cursor IDE
    windsurf   Windsurf IDE
    continue   Continue (VS Code extension)
    aider      Aider (terminal AI)
    copilot    GitHub Copilot

EXAMPLES:
    bash install.sh --tool claude
    bash install.sh --tool cursor
    bash install.sh --all
    bash install.sh                    # Interactive mode

EOF
}

# ─── Detection ─────────────────────────────────────────────────────────────────
detect_tools() {
    local found=()

    # Claude Code
    if command -v claude &> /dev/null || [ -d "$HOME/.claude" ]; then
        found+=("claude")
    fi

    # Cursor
    if [ -d "$HOME/.cursor" ] || command -v cursor &> /dev/null; then
        found+=("cursor")
    fi

    # Windsurf
    if [ -d "$HOME/.windsurf" ] || command -v windsurf &> /dev/null; then
        found+=("windsurf")
    fi

    # Continue (VS Code extension)
    if [ -d "$HOME/.continue" ]; then
        found+=("continue")
    fi

    # Aider
    if command -v aider &> /dev/null; then
        found+=("aider")
    fi

    # GitHub Copilot (check for gh CLI)
    if command -v gh &> /dev/null; then
        found+=("copilot")
    fi

    echo "${found[@]}"
}

# ─── Install: Claude Code ─────────────────────────────────────────────────────
install_claude() {
    local target="$HOME/.claude/skills"
    mkdir -p "$target"

    info "Installing skills to $target ..."

    local count=0
    for skill_dir in "$SKILLS_DIR"/autotask-*; do
        [ -d "$skill_dir" ] || continue
        local name
        name=$(basename "$skill_dir")
        cp -r "$skill_dir" "$target/"
        success "Installed: $name"
        ((count++))
    done

    echo ""
    success "Claude Code: $count skills installed to $target"
    echo -e "  ${CYAN}Skills are auto-discovered by Claude Code.${NC}"
    echo -e "  ${CYAN}Use them in any project with Claude Code.${NC}"
}

# ─── Install: Cursor ──────────────────────────────────────────────────────────
install_cursor() {
    local target="$SKILLS_DIR/../adapters/cursor/.cursorrules"
    local dest="./.cursorrules"

    if [ ! -f "$target" ]; then
        error "Cursor adapter not found at $target"
        return 1
    fi

    cp "$target" "$dest"
    success "Cursor: Installed .cursorrules to current directory"
    echo -e "  ${CYAN}Copy this file to your project root.${NC}"
}

# ─── Install: Windsurf ────────────────────────────────────────────────────────
install_windsurf() {
    local target="$SKILLS_DIR/../adapters/windsurf/.windsurfrules"
    local dest="./.windsurfrules"

    if [ ! -f "$target" ]; then
        error "Windsurf adapter not found at $target"
        return 1
    fi

    cp "$target" "$dest"
    success "Windsurf: Installed .windsurfrules to current directory"
    echo -e "  ${CYAN}Copy this file to your project root.${NC}"
}

# ─── Install: Continue ────────────────────────────────────────────────────────
install_continue() {
    local target="$SKILLS_DIR/../adapters/continue/config.yaml"
    local dest="$HOME/.continue/config.yaml"

    mkdir -p "$(dirname "$dest")"

    if [ ! -f "$target" ]; then
        error "Continue adapter not found at $target"
        return 1
    fi

    if [ -f "$dest" ]; then
        warn "Existing Continue config found at $dest"
        warn "Adapter file saved to ./continue-config.yaml"
        warn "Merge manually with your existing config."
        cp "$target" "./continue-config.yaml"
    else
        cp "$target" "$dest"
        success "Continue: Installed config to $dest"
    fi
}

# ─── Install: Aider ───────────────────────────────────────────────────────────
install_aider() {
    local target="$SKILLS_DIR/../adapters/aider/.aider.conf.yml"
    local dest="./.aider.conf.yml"

    if [ ! -f "$target" ]; then
        error "Aider adapter not found at $target"
        return 1
    fi

    cp "$target" "$dest"
    success "Aider: Installed .aider.conf.yml to current directory"
    echo -e "  ${CYAN}Copy this file to your project root.${NC}"
}

# ─── Install: Copilot ─────────────────────────────────────────────────────────
install_copilot() {
    local target="$SKILLS_DIR/../adapters/copilot/copilot-instructions.md"
    local dest="./.github/copilot-instructions.md"

    mkdir -p "$(dirname "$dest")"

    if [ ! -f "$target" ]; then
        error "Copilot adapter not found at $target"
        return 1
    fi

    cp "$target" "$dest"
    success "Copilot: Installed copilot-instructions.md to .github/"
    echo -e "  ${CYAN}Copy .github/ to your project root.${NC}"
}

# ─── Main ──────────────────────────────────────────────────────────────────────
main() {
    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║        🤖 Autotask AI Skills Installer v1.0.0              ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Verify skills directory exists
    if [ ! -d "$SKILLS_DIR" ]; then
        error "Skills directory not found: $SKILLS_DIR"
        error "Make sure you run this script from the repository root."
        exit 1
    fi

    local tool=""
    local install_all=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --tool)
                tool="$2"
                shift 2
                ;;
            --all)
                install_all=true
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    # Install all detected tools
    if [ "$install_all" = true ]; then
        local detected
        detected=$(detect_tools)
        if [ -z "$detected" ]; then
            warn "No AI tools detected. Installing for Claude Code by default."
            install_claude
        else
            info "Detected tools: $detected"
            for t in $detected; do
                echo ""
                "install_$t"
            done
        fi
        echo ""
        success "Installation complete!"
        exit 0
    fi

    # Install specific tool
    if [ -n "$tool" ]; then
        case $tool in
            claude|cursor|windsurf|continue|aider|copilot)
                "install_$tool"
                echo ""
                success "Installation complete!"
                ;;
            *)
                error "Unknown tool: $tool"
                echo "Supported: claude, cursor, windsurf, continue, aider, copilot"
                exit 1
                ;;
        esac
        exit 0
    fi

    # Interactive mode
    echo "Detected AI tools:"
    echo ""
    local detected
    detected=$(detect_tools)
    local options=("claude" "cursor" "windsurf" "continue" "aider" "copilot")
    local i=1

    for t in "${options[@]}"; do
        local marker=""
        if echo "$detected" | grep -qw "$t"; then
            marker=" ${GREEN}(detected)${NC}"
        fi
        echo -e "  ${BOLD}$i)${NC} $t$marker"
        ((i++))
    done

    echo ""
    echo -e "  ${BOLD}a)${NC} All detected tools"
    echo -e "  ${BOLD}q)${NC} Quit"
    echo ""
    read -rp "Choose tool(s) to install [1-6, a, q]: " choice

    case $choice in
        1) install_claude ;;
        2) install_cursor ;;
        3) install_windsurf ;;
        4) install_continue ;;
        5) install_aider ;;
        6) install_copilot ;;
        a|A)
            if [ -z "$detected" ]; then
                warn "No tools detected. Installing for Claude Code."
                install_claude
            else
                for t in $detected; do
                    "install_$t"
                done
            fi
            ;;
        q|Q)
            echo "Bye!"
            exit 0
            ;;
        *)
            error "Invalid choice"
            exit 1
            ;;
    esac

    echo ""
    success "Installation complete!"
}

main "$@"
