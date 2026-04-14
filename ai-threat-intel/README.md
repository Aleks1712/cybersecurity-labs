# 🛡️ AI Threat Intelligence Tracker

![Auto-Updated](https://img.shields.io/badge/Updated-Weekly-2ECC71?style=flat-square)
![AI Security](https://img.shields.io/badge/AI_Security-Threat_Intel-E74C3C?style=flat-square)
![Automated](https://img.shields.io/badge/Powered_By-GitHub_Actions_+_Claude_API-9B59B6?style=flat-square)

Automated weekly AI security threat intelligence reports. A GitHub Actions workflow uses the Anthropic API with web search to research the latest AI/LLM security incidents, supply chain attacks, and emerging threats — then commits a structured analysis to this repository.

## How It Works

```mermaid
graph LR
    A[GitHub Actions Cron] -->|Weekly| B[Python Script]
    B --> C[Anthropic API + Web Search]
    C --> D[Research Latest AI Threats]
    D --> E[Generate Markdown Report]
    E --> F[Git Commit + Push]
    style A fill:#2ECC71,color:#fff
    style C fill:#9B59B6,color:#fff
    style F fill:#FF9900,color:#fff
```

## Reports

| Date | Report |
|------|--------|
| 2026-04-14 | [Weekly Report](reports/2026-04-14-weekly-report.md) |
| *Reports appear here automatically* | |

## Categories Tracked

- **Supply Chain Attacks** — Compromised packages, poisoned models, CI/CD hijacking
- **LLM Vulnerabilities** — Prompt injection, jailbreaks, data exfiltration via AI
- **Model Security** — Backdoor attacks, data poisoning, model inversion
- **AI Infrastructure** — MCP server abuse, AI gateway compromises, API key theft
- **Regulatory** — EU AI Act enforcement, NIST AI RMF updates

## Setup

Requires `ANTHROPIC_API_KEY` as a GitHub repository secret. The workflow runs every Monday at 08:00 UTC.

---

[⬅️ Back to cybersecurity-labs](../)
