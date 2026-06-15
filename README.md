# 🤖 Autotask AI Skills

![License](https://img.shields.io/badge/license-MIT-blue)
![Skills](https://img.shields.io/badge/skills-8-orange)
![Entities](https://img.shields.io/badge/entities-226+-green)
![AI Tools](https://img.shields.io/badge/compatible-6_AI_tools-purple)

> **AI-powered skills for Autotask PSA integration — works with Claude Code, Cursor, Windsurf, Continue, Aider, and GitHub Copilot.**

Stop writing the same Autotask API boilerplate every time. These skills give your AI assistant deep knowledge of the Autotask PSA REST API — 226+ entities, query patterns, KPI formulas, webhook setup, inventory management, and more.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| **226+ Entity Reference** | Complete field-level documentation for every Autotask entity |
| **Smart Query Patterns** | Filter operators, pagination, UDF queries, AND/OR grouping |
| **KPI Dashboards** | Pre-built formulas for tickets, utilization, SLA, revenue, and more |
| **Contract Management** | Recurring services, block hours, retainers, fixed price billing |
| **Inventory Tracking** | Stock levels, purchase orders, serial numbers, transfers |
| **Webhook Integration** | Real-time event-driven setup for tickets, contacts, assets |
| **Data Warehouse** | SQL Server reporting with 26+ common views |
| **Deep-Link URLs** | 20+ ExecuteCommand URLs for Autotask UI navigation |
| **Multi-AI Support** | Works with 6 major AI coding assistants |
| **One-Click Install** | Automated installation scripts for all platforms |

---

## 🚀 Quick Install

### Claude Code

```bash
# Clone and install
git clone https://github.com/YOUR_USERNAME/autotask-ai-skills.git
cd autotask-ai-skills
bash install.sh --tool claude
```

### Cursor

```bash
bash install.sh --tool cursor
```

### Windsurf

```bash
bash install.sh --tool windsurf
```

### All Supported Tools

```bash
bash install.sh --all
```

### Windows (PowerShell)

```powershell
git clone https://github.com/YOUR_USERNAME/autotask-ai-skills.git
cd autotask-ai-skills
.\install.ps1 -Tool claude
# or
.\install.ps1 -All
```

---

## 📋 Skills Overview

### 1. `autotask-psa-api` — Core API Reference
The foundation skill. Covers authentication, zone discovery, CRUD operations, query syntax, pagination, rate limits, and all 226+ entity types organized by domain.

### 2. `autotask-contract-management` — Contracts & Billing
Manage recurring services, block hours, retainers, fixed price contracts, per-ticket billing, and time & materials. Includes 17 sub-entities and billing rule patterns.

### 3. `autotask-data-warehouse` — SQL Reporting
Connect to the Autotask Report Data Warehouse (SQL Server, port 1433) for complex analytics. Covers 26 common views, BI tool integration, and terminology mapping.

### 4. `autotask-execute-command` — Deep Links
Build deep-link integrations that open specific Autotask pages via browser. 20+ commands for tickets, accounts, contacts, opportunities, assets, and more.

### 5. `autotask-inventory` — Stock & Purchasing
Full inventory lifecycle: stock levels, transfers, purchase orders, receiving, serial number tracking, location management, and reorder alerts.

### 6. `autotask-kpi-reporting` — Analytics & Dashboards
Pre-built KPI patterns for tickets, resource utilization, SLA compliance, financial summaries, project tracking, sales pipeline, and client satisfaction.

### 7. `autotask-udf` — User-Defined Fields
Extend any entity with custom data. Covers UDF types, query syntax, definition management, protected fields, and integration patterns.

### 8. `autotask-webhooks` — Real-Time Events
Set up push-based notifications for companies, contacts, tickets, assets, and ticket notes. Includes security setup, payload structure, and error handling.

---

## 📖 Detailed Installation

### Prerequisites

- **Autotask PSA** account with API access
- **API User** credentials (email, secret, integration code)
- **AI Tool** installed (one of: Claude Code, Cursor, Windsurf, Continue, Aider, GitHub Copilot)

### Claude Code Installation

**Option A: Automated (Recommended)**
```bash
git clone https://github.com/YOUR_USERNAME/autotask-ai-skills.git
cd autotask-ai-skills
bash install.sh --tool claude
```

This copies all skills to `~/.claude/skills/` where Claude Code automatically discovers them.

**Option B: Manual**
```bash
# Copy skills to Claude Code's skill directory
cp -r skills/* ~/.claude/skills/
```

**Option C: Project-Level**
```bash
# Copy to your project's .claude/skills/ directory
mkdir -p /path/to/your/project/.claude/skills/
cp -r skills/* /path/to/your/project/.claude/skills/
```

### Cursor Installation

```bash
bash install.sh --tool cursor
```

This creates a `.cursorrules` file in your project root with all skill knowledge consolidated.

### Windsurf Installation

```bash
bash install.sh --tool windsurf
```

This creates a `.windsurfrules` file in your project root.

### Continue Installation

```bash
bash install.sh --tool continue
```

This adds context provider configuration to your Continue config.

### Aider Installation

```bash
bash install.sh --tool aider
```

This creates `.aider.conf.yml` and a conventions file with Autotask API knowledge.

### GitHub Copilot Installation

```bash
bash install.sh --tool copilot
```

This creates `.github/copilot-instructions.md` with all skill knowledge.

---

## 🔧 Usage Examples

### Query Open Tickets

```
Ask your AI: "Show me all open high-priority tickets in Autotask"

The AI will use the autotask-psa-api skill to:
1. Discover your zone via ZoneInformation
2. Query tickets with status != 5 and priority = 1
3. Return formatted results
```

### Set Up Webhooks

```
Ask your AI: "Help me set up a webhook for new ticket creation"

The AI will use the autotask-webhooks skill to:
1. Create an API-only user with webhook permissions
2. Configure the webhook via POST /TicketsWebhooks
3. Set up your endpoint to receive payloads
```

### Build a KPI Dashboard

```
Ask your AI: "Create a ticket SLA compliance report"

The AI will use the autotask-kpi-reporting skill to:
1. Query ServiceLevelAgreementResults
2. Calculate compliance percentages
3. Generate formatted report data
```

### Check Inventory Levels

```
Ask your AI: "What products are below reorder point?"

The AI will use the autotask-inventory skill to:
1. Query InventoryProducts
2. Filter where quantityOnHand <= reorderPoint
3. List items needing restock
```

---

## 🏗️ Architecture

```
autotask-ai-skills/
├── skills/                          # Claude Code native format
│   ├── autotask-psa-api/           # Foundation - all others depend on this
│   ├── autotask-contract-management/
│   ├── autotask-data-warehouse/
│   ├── autotask-execute-command/
│   ├── autotask-inventory/
│   ├── autotask-kpi-reporting/
│   ├── autotask-udf/
│   └── autotask-webhooks/
├── adapters/                        # Converted formats for other AI tools
│   ├── cursor/.cursorrules
│   ├── windsurf/.windsurfrules
│   ├── continue/config.yaml
│   ├── aider/.aider.conf.yml
│   └── copilot/copilot-instructions.md
├── install.sh                       # Unix/macOS installer
├── install.ps1                      # Windows installer
└── examples/                        # Usage examples
```

---

## 🤝 Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

1. Fork the repository
2. Create a feature branch (`git checkout -b add-new-skill`)
3. Commit your changes (`git commit -m 'Add new skill'`)
4. Push to the branch (`git push origin add-new-skill`)
5. Open a Pull Request

---

## 📄 License

MIT License — see [LICENSE](LICENSE) for details.

---

## 🙏 Acknowledgments

- [Autotask PSA](https://www.autotask.net/) by Datto/Kaseya
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) by Anthropic
- The MSP community for feedback and testing

---

## 📬 Support

- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/autotask-ai-skills/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/autotask-ai-skills/discussions)

---

<p align="center">Made with ❤️ for MSPs using Autotask PSA</p>
