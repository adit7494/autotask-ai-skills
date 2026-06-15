---
name: autotask-execute-command
description: Use when building deep-link integrations that open specific Autotask pages programmatically for tickets, accounts, contacts, projects, contracts, or other entities via the ExecuteCommand API
---

# Autotask ExecuteCommand API

## Overview

ExecuteCommand API creates URLs that open specific Autotask pages in a browser popup. Used for deep-linking from external applications into Autotask records.

**Key difference:** REST API for data operations. ExecuteCommand for UI navigation.

## How It Works

1. Build URL with command and parameters
2. User clicks link in external app
3. Autotask login page appears (if not authenticated)
4. Target page opens in popup window

## Prerequisites

- Autotask server URL (`ww*.autotask.net`) in **Trusted Sites**
- Pop-up blockers disabled for `ww*.autotask.net`
- Valid Autotask user credentials

## URL Format

```
https://ww[number].autotask.net/ExecuteCommand?Command={command}&Parameters={parameters}
```

## Available Commands

### Ticket Commands

| Command | Parameters | Description |
|---------|------------|-------------|
| `NewTicket` | Phone Number, Account ID, or GlobalTaskID | Create new ticket |
| `OpenTicketDetail` | Ticket Number or Ticket ID | Open ticket detail |
| `OpenTicketTime` | TicketID; optionally TimeEntryID | Open time entry page |
| `EditTimeEntry` | WorkEntryID | Edit existing time entry |

### Account (Company) Commands

| Command | Parameters | Description |
|---------|------------|-------------|
| `NewAccount` | None | Open new account form |
| `OpenAccount` | Phone, AccountName, or Account ID | Open account |
| `EditAccount` | Phone, AccountName, or Account ID | Edit account |
| `NewAccountNote` | Account ID | Create account note |

### Contact Commands

| Command | Parameters | Description |
|---------|------------|-------------|
| `NewContact` | Phone, AccountName, or Account ID | Create contact |
| `EditContact` | Email, FirstName, LastName, or Contact ID | Edit contact |
| `OpenContact` | Email, FirstName, LastName, or Contact ID | Open contact |

### Opportunity Commands

| Command | Parameters | Description |
|---------|------------|-------------|
| `OpenOpportunity` | Opportunity ID | Open opportunity |

### Asset Commands

| Command | Parameters | Description |
|---------|------------|-------------|
| `NewInstalledProduct` | Phone, Account ID, or AccountName | Create asset |
| `EditInstalledProduct` | Asset ID | Edit asset |
| `OpenIPDW` | Wizard extension name | Open discovery wizard |

### Other Commands

| Command | Parameters | Description |
|---------|------------|-------------|
| `OpenAppointment` | AppointmentID | Open appointment |
| `OpenContract` | ContractID | Open contract |
| `OpenKBArticle` | Knowledgebase article ID | Open KB article |
| `OpenProject` | ProjectID | Open project |
| `OpenQuote` | Quote ID | Open quote |
| `OpenSalesOrder` | SalesOrderID | Open sales order |
| `OpenServiceCall` | Service Call ID | Open service call |
| `OpenTimeOffRequest` | ApproverID and ResourceID (required) | Open time-off request |
| `OpenToDo` | ToDoID | Open to-do item |

## Usage Examples

### Open Ticket by Number

```
https://ww3.autotask.net/ExecuteCommand?Command=OpenTicketDetail&Parameters=T20240115.0001
```

### Open Ticket by ID

```
https://ww3.autotask.net/ExecuteCommand?Command=OpenTicketDetail&Parameters=12345
```

### Create New Ticket for Account

```
https://ww3.autotask.net/ExecuteCommand?Command=NewTicket&Parameters=11111
```

### Open Account by Name

```
https://ww3.autotask.net/ExecuteCommand?Command=OpenAccount&Parameters=ACME%20Corp
```

### Open Contact by Email

```
https://ww3.autotask.net/ExecuteCommand?Command=OpenContact&Parameters=john@acme.com
```

### Edit Time Entry

```
https://ww3.autotask.net/ExecuteCommand?Command=EditTimeEntry&Parameters=67890
```

### Open Project

```
https://ww3.autotask.net/ExecuteCommand?Command=OpenProject&Parameters=54321
```

## Integration Patterns

### Email Notification Links

Include deep links in ticket notification emails:

```html
<a href="https://ww3.autotask.net/ExecuteCommand?Command=OpenTicketDetail&Parameters={{ticketNumber}}">
  View Ticket in Autotask
</a>
```

### Dashboard Quick Links

Embed in external dashboards:

```javascript
function openAutotaskTicket(ticketId) {
  window.open(
    `https://ww3.autotask.net/ExecuteCommand?Command=OpenTicketDetail&Parameters=${ticketId}`,
    'Autotask',
    'width=1200,height=800'
  );
}
```

### CRM Integration

Link from CRM to Autotask account:

```javascript
function openAutotaskAccount(accountId) {
  window.open(
    `https://ww3.autotask.net/ExecuteCommand?Command=OpenAccount&Parameters=${accountId}`,
    'Autotask'
  );
}
```

## Terminology Notes

| API Term | UI Term |
|----------|---------|
| Account | Company |
| Installed Product | Asset |

Parameters accept either terminology.

## Error Handling

- Invalid URL or parameters show error message in Autotask
- User must be authenticated first (login page appears if not)
- Popup blockers must be disabled for Autotask domain

## Best Practices

1. **URL encode parameters** — Spaces and special characters need encoding
2. **Use IDs when possible** — More reliable than names (names may have duplicates)
3. **Handle popup blockers** — Guide users to allow popups for Autotask
4. **Test zone URLs** — Different zones have different `ww[number]` prefixes
5. **Provide fallback** — Include direct URL to Autotask if popup fails
6. **Document parameter format** — Some commands accept multiple parameter types

## Limitations

1. **Browser only** — Opens in browser, not API
2. **Popup required** — Blocked by default in most browsers
3. **No return data** — One-way navigation, no data feedback
4. **Authentication required** — User must have Autotask access
5. **Zone-specific** — URL varies by Autotask zone

## Reference

- API Skill: `autotask-psa-api`
- Full Documentation: https://www.autotask.net/help/developerhelp/Content/APIs/ExecuteCommand/ExecuteCommandAPIIntro.htm
