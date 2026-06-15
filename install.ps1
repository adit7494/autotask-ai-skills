<#
.SYNOPSIS
    Autotask AI Skills Installer for Windows

.DESCRIPTION
    Installs Autotask PSA skills for various AI coding assistants.
    Supports Claude Code, Cursor, Windsurf, Continue, Aider, and GitHub Copilot.

.PARAMETER Tool
    Install for a specific AI tool. Options: claude, cursor, windsurf, continue, aider, copilot

.PARAMETER All
    Install for all detected AI tools

.EXAMPLE
    .\install.ps1 -Tool claude
    .\install.ps1 -Tool cursor
    .\install.ps1 -All
    .\install.ps1                          # Interactive mode
#>

param(
    [ValidateSet("claude", "cursor", "windsurf", "continue", "aider", "copilot")]
    [string]$Tool,
    [switch]$All,
    [switch]$Help
)

$ErrorActionPreference = "Stop"

# ─── Colors ────────────────────────────────────────────────────────────────────
function Write-Info    { Write-Host "[INFO] " -ForegroundColor Blue -NoNewline; Write-Host $args }
function Write-Ok      { Write-Host "[OK]   " -ForegroundColor Green -NoNewline; Write-Host $args }
function Write-Warn    { Write-Host "[WARN] " -ForegroundColor Yellow -NoNewline; Write-Host $args }
function Write-Err     { Write-Host "[ERR]  " -ForegroundColor Red -NoNewline; Write-Host $args }

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$SkillsDir = Join-Path $ScriptDir "skills"

# ─── Help ──────────────────────────────────────────────────────────────────────
function Show-Help {
    Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║           Autotask AI Skills Installer v1.0.0               ║
╚══════════════════════════════════════════════════════════════╝

USAGE:
    .\install.ps1 [OPTIONS]

OPTIONS:
    -Tool <name>    Install for a specific AI tool
    -All            Install for all detected AI tools
    -Help           Show this help message

SUPPORTED TOOLS:
    claude     Claude Code (Anthropic)
    cursor     Cursor IDE
    windsurf   Windsurf IDE
    continue   Continue (VS Code extension)
    aider      Aider (terminal AI)
    copilot    GitHub Copilot

EXAMPLES:
    .\install.ps1 -Tool claude
    .\install.ps1 -Tool cursor
    .\install.ps1 -All

"@
}

# ─── Detection ─────────────────────────────────────────────────────────────────
function Detect-Tools {
    $found = @()

    # Claude Code
    if ((Get-Command claude -ErrorAction SilentlyContinue) -or (Test-Path "$env:USERPROFILE\.claude")) {
        $found += "claude"
    }

    # Cursor
    if ((Test-Path "$env:USERPROFILE\.cursor") -or (Get-Command cursor -ErrorAction SilentlyContinue)) {
        $found += "cursor"
    }

    # Windsurf
    if ((Test-Path "$env:USERPROFILE\.windsurf") -or (Get-Command windsurf -ErrorAction SilentlyContinue)) {
        $found += "windsurf"
    }

    # Continue
    if (Test-Path "$env:USERPROFILE\.continue") {
        $found += "continue"
    }

    # Aider
    if (Get-Command aider -ErrorAction SilentlyContinue) {
        $found += "aider"
    }

    # GitHub Copilot
    if (Get-Command gh -ErrorAction SilentlyContinue) {
        $found += "copilot"
    }

    return $found
}

# ─── Install: Claude Code ─────────────────────────────────────────────────────
function Install-Claude {
    $target = Join-Path $env:USERPROFILE ".claude\skills"
    New-Item -ItemType Directory -Force -Path $target | Out-Null

    Write-Info "Installing skills to $target ..."

    $count = 0
    Get-ChildItem -Directory -Path $SkillsDir -Filter "autotask-*" | ForEach-Object {
        $dest = Join-Path $target $_.Name
        if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
        Copy-Item -Recurse $_.FullName $target
        Write-Ok "Installed: $($_.Name)"
        $count++
    }

    Write-Host ""
    Write-Ok "Claude Code: $count skills installed to $target"
    Write-Host "  Skills are auto-discovered by Claude Code." -ForegroundColor Cyan
}

# ─── Install: Cursor ──────────────────────────────────────────────────────────
function Install-Cursor {
    $source = Join-Path $ScriptDir "adapters\cursor\.cursorrules"
    $dest = ".\.cursorrules"

    if (-not (Test-Path $source)) {
        Write-Err "Cursor adapter not found at $source"
        return
    }

    Copy-Item $source $dest -Force
    Write-Ok "Cursor: Installed .cursorrules to current directory"
    Write-Host "  Copy this file to your project root." -ForegroundColor Cyan
}

# ─── Install: Windsurf ────────────────────────────────────────────────────────
function Install-Windsurf {
    $source = Join-Path $ScriptDir "adapters\windsurf\.windsurfrules"
    $dest = ".\.windsurfrules"

    if (-not (Test-Path $source)) {
        Write-Err "Windsurf adapter not found at $source"
        return
    }

    Copy-Item $source $dest -Force
    Write-Ok "Windsurf: Installed .windsurfrules to current directory"
    Write-Host "  Copy this file to your project root." -ForegroundColor Cyan
}

# ─── Install: Continue ────────────────────────────────────────────────────────
function Install-Continue {
    $source = Join-Path $ScriptDir "adapters\continue\config.yaml"
    $destDir = Join-Path $env:USERPROFILE ".continue"
    $dest = Join-Path $destDir "config.yaml"

    if (-not (Test-Path $source)) {
        Write-Err "Continue adapter not found at $source"
        return
    }

    New-Item -ItemType Directory -Force -Path $destDir | Out-Null

    if (Test-Path $dest) {
        Write-Warn "Existing Continue config found at $dest"
        Write-Warn "Adapter file saved to .\continue-config.yaml"
        Write-Warn "Merge manually with your existing config."
        Copy-Item $source ".\continue-config.yaml" -Force
    } else {
        Copy-Item $source $dest -Force
        Write-Ok "Continue: Installed config to $dest"
    }
}

# ─── Install: Aider ───────────────────────────────────────────────────────────
function Install-Aider {
    $source = Join-Path $ScriptDir "adapters\aider\.aider.conf.yml"
    $dest = ".\.aider.conf.yml"

    if (-not (Test-Path $source)) {
        Write-Err "Aider adapter not found at $source"
        return
    }

    Copy-Item $source $dest -Force
    Write-Ok "Aider: Installed .aider.conf.yml to current directory"
    Write-Host "  Copy this file to your project root." -ForegroundColor Cyan
}

# ─── Install: Copilot ─────────────────────────────────────────────────────────
function Install-Copilot {
    $source = Join-Path $ScriptDir "adapters\copilot\copilot-instructions.md"
    $destDir = ".\.github"
    $dest = Join-Path $destDir "copilot-instructions.md"

    if (-not (Test-Path $source)) {
        Write-Err "Copilot adapter not found at $source"
        return
    }

    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    Copy-Item $source $dest -Force
    Write-Ok "Copilot: Installed copilot-instructions.md to .github\"
    Write-Host "  Copy .github\ to your project root." -ForegroundColor Cyan
}

# ─── Main ──────────────────────────────────────────────────────────────────────
function Main {
    Write-Host ""
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor White
    Write-Host "║        🤖 Autotask AI Skills Installer v1.0.0              ║" -ForegroundColor White
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor White
    Write-Host ""

    if ($Help) {
        Show-Help
        return
    }

    # Verify skills directory
    if (-not (Test-Path $SkillsDir)) {
        Write-Err "Skills directory not found: $SkillsDir"
        Write-Err "Make sure you run this script from the repository root."
        exit 1
    }

    # Install all detected
    if ($All) {
        $detected = Detect-Tools
        if ($detected.Count -eq 0) {
            Write-Warn "No AI tools detected. Installing for Claude Code by default."
            Install-Claude
        } else {
            Write-Info "Detected tools: $($detected -join ', ')"
            foreach ($t in $detected) {
                Write-Host ""
                & "Install-$($t.Substring(0,1).ToUpper() + $t.Substring(1))"
            }
        }
        Write-Host ""
        Write-Ok "Installation complete!"
        return
    }

    # Install specific tool
    if ($Tool) {
        $funcName = "Install-$($Tool.Substring(0,1).ToUpper() + $Tool.Substring(1))"
        & $funcName
        Write-Host ""
        Write-Ok "Installation complete!"
        return
    }

    # Interactive mode
    Write-Host "Available AI tools:"
    Write-Host ""
    $tools = @("claude", "cursor", "windsurf", "continue", "aider", "copilot")
    $detected = Detect-Tools

    for ($i = 0; $i -lt $tools.Count; $i++) {
        $marker = ""
        if ($detected -contains $tools[$i]) {
            $marker = " (detected)"
        }
        Write-Host "  $($i + 1)) $($tools[$i])$marker" -ForegroundColor White
    }

    Write-Host ""
    Write-Host "  a) All detected tools"
    Write-Host "  q) Quit"
    Write-Host ""

    $choice = Read-Host "Choose tool(s) to install [1-6, a, q]"

    switch ($choice) {
        "1" { Install-Claude }
        "2" { Install-Cursor }
        "3" { Install-Windsurf }
        "4" { Install-Continue }
        "5" { Install-Aider }
        "6" { Install-Copilot }
        "a" {
            if ($detected.Count -eq 0) {
                Write-Warn "No tools detected. Installing for Claude Code."
                Install-Claude
            } else {
                foreach ($t in $detected) {
                    $funcName = "Install-$($t.Substring(0,1).ToUpper() + $t.Substring(1))"
                    & $funcName
                }
            }
        }
        "q" { Write-Host "Bye!"; return }
        default { Write-Err "Invalid choice"; exit 1 }
    }

    Write-Host ""
    Write-Ok "Installation complete!"
}

Main
