# AI Threat Intelligence Report — Week of 2026-04-14

## Summary

Major supply chain attacks continued to dominate the AI security landscape this week. The LiteLLM PyPI compromise (March 24) has cascading effects as more downstream victims are identified, including AI recruiting startup Mercor. The Axios NPM package was also compromised through account takeover, attributed to a North Korean threat actor. EU AI Act full obligations take effect August 2, 2026 — organizations deploying AI agents must begin compliance planning now.

## Critical Incidents

### 1. LiteLLM Supply Chain Attack — Cascading Impact

- **Date:** March 24, 2026 (ongoing fallout)
- **Category:** Supply Chain
- **Impact:** Mercor (AI recruiting startup) confirmed breached via compromised LiteLLM dependency. Sensitive customer data and AI training data exposed. Extortion crew claiming Lapsus$ lineage took credit. LiteLLM is present in approximately 36% of cloud environments.
- **Technical Details:** TeamPCP exploited Trivy CI/CD misconfiguration to obtain PyPI publishing credentials. Malicious versions 1.82.7 and 1.82.8 contained a three-stage payload: credential harvesting (SSH keys, AWS/GCP/Azure tokens, K8s configs), lateral movement via Kubernetes, and persistent backdoor via `.pth` file auto-execution. The `.pth` mechanism executes code every time Python interpreter starts — no explicit import needed.
- **Detection:** Scan for `litellm_init.pth` in Python site-packages. Check pip install logs for versions 1.82.7/1.82.8 between 0800-1244 UTC on March 24. Monitor for outbound connections to `models.litellm.cloud`.
- **Mitigation:** Rotate all potentially exposed secrets (PyPI tokens, API keys, SSH keys, cloud credentials). Pin dependencies with hash verification. Audit `.pth` files in all Python environments. Use private package registries.

### 2. Axios NPM Package Compromise

- **Date:** March 30, 2026
- **Category:** Supply Chain
- **Impact:** Widely-used NPM package compromised through maintainer account takeover, attributed to North Korean threat actor.
- **Technical Details:** Attackers bypassed GitHub Actions CI/CD by compromising the maintainer's NPM account and changing its associated email. Malicious code injected into distributed package.
- **Detection:** Verify package integrity against source repository. Monitor for unexpected NPM account email changes in your dependencies.
- **Mitigation:** Enable NPM 2FA for all maintainer accounts. Use `npm audit` and lockfile verification. Pin exact versions.

### 3. TeamPCP Multi-Target Campaign

- **Date:** February-March 2026
- **Category:** Supply Chain
- **Impact:** Coordinated campaign targeting security and AI infrastructure tools: Trivy (Feb 2026), Checkmarx KICS (March 23), LiteLLM (March 24), Telnyx (March 2026).
- **Technical Details:** TeamPCP exploited `pull_request_target` workflow misconfiguration in Trivy's CI to exfiltrate the aqua-bot PAT. Used this to force-push malicious commits to 76 of 77 release tags in trivy-action. The campaign demonstrates deep understanding of Python execution models and CI/CD trust chains.
- **Detection:** Audit GitHub Actions workflows for `pull_request_target` triggers with write permissions. Verify release tag integrity. Monitor for force-pushes to release tags.
- **Mitigation:** Restrict `pull_request_target` workflows. Use tag protection rules. Implement atomic credential rotation. Treat security scanning tools as part of your attack surface.

## Emerging Threats

**MCP Server Abuse:** Model Context Protocol servers are being adopted rapidly with minimal security review. MCP servers can access local filesystems, databases, and APIs — a compromised MCP server is equivalent to a compromised admin session. Expect exploitation as adoption grows.

**AI Agent Autonomy Risks:** AI agents with tool-calling capabilities (browsing, code execution, API access) create new lateral movement paths. An agent that can be prompt-injected into calling external APIs can exfiltrate data without traditional network-based detection.

**EU AI Act Compliance Deadline:** Full obligations take effect August 2, 2026. Organizations deploying AI agents in the EU must implement risk classification, consent workflows, and audit documentation. Non-compliance carries fines up to 7% of global revenue.

## Detection Recommendations

1. **Scan Python environments for `.pth` files** — Any `.pth` file in `site-packages` that contains executable code (not just path entries) is suspicious
2. **Audit CI/CD workflows for `pull_request_target`** — This trigger runs with write permissions and can be exploited by external PRs
3. **Monitor outbound connections from AI infrastructure** — LLM gateways, MCP servers, and model serving endpoints should have strict egress rules
4. **Verify package digests before deployment** — Compare PyPI/NPM distributed artifacts against source code. Use `pip install --require-hashes`
5. **Track AI dependency SBOM** — Maintain a Software Bill of Materials for all AI/ML packages in your stack

## Sources

- Trend Micro: Inside the LiteLLM Supply Chain Compromise (March 26, 2026)
- Zscaler ThreatLabz: Supply Chain Attacks Surge in March 2026 (April 10, 2026)
- Arthur AI: LiteLLM Supply Chain Attack — What AI Teams Need to Know (April 2026)
- Security Boulevard: The AI Supply Chain is Actually an API Supply Chain (April 10, 2026)
- LiteLLM Official Security Update (March 2026)
- The Meridiem: AI Supply Chain Attack Crosses Into Production (April 1, 2026)

---

*Auto-generated by [AI Threat Intel Tracker](https://github.com/Aleks1712/cybersecurity-labs/tree/main/ai-threat-intel) using Anthropic API with web search.*
