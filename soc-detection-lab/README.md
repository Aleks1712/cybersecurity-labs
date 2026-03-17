# 🔓 ANTI-BAD-CHALLENGE — Backdoor Exploit Toolkit

Demonstrates the severity of backdoor attacks in LoRA-adapted LLMs before presenting defense mechanisms.

## Experiments

| # | Experiment | What it proves | Key metric |
|---|-----------|---------------|------------|
| 1 | **Targeted Misclassification** | Clearly negative text flips to positive with one word | Flip rate per trigger |
| 2 | **Stealth / Perplexity** | Triggers are nearly invisible to humans & LMs | Perplexity ratio |
| 3 | **Minimum Dose + Escalation** | Attack works on tiny inputs; stacking amplifies | Min words, escalation curve |
| 4 | **Pipeline Attack** | Real-world damage at various poison rates | Accuracy degradation |

## Quick Start

```bash
# Run everything on Slurm
sbatch slurm_exploits.sh

# Run single experiment
sbatch slurm_exploits.sh targeted
sbatch slurm_exploits.sh stealth
sbatch slurm_exploits.sh minimum_dose
sbatch slurm_exploits.sh pipeline

# Generate plots only (from existing CSVs)
python run_exploits.py --experiment plots
```

## Setup

Before running, update `config.yaml` with your actual paths:
- `models.task1.model1` → path to your LoRA adapters
- `data.task1` → path to test.json files

### Dependencies
```bash
pip install torch transformers peft bitsandbytes pyyaml pandas tabulate matplotlib
```

## Output

All results go to `reporting/exploits/`:
- `exploit_targeted_*.csv` — Misclassification demo
- `exploit_stealth_*.csv` — Perplexity analysis
- `exploit_minimum_dose.csv` — Shortest triggering inputs
- `exploit_escalation.csv` — Multi-trigger amplification
- `exploit_pipeline_attack.csv` — Pipeline simulation
- `plot_*.png` — Publication-ready figures

## Thesis Narrative

The experiments build a story:
1. **"The attack is devastating"** → Targeted misclassification
2. **"The attack is invisible"** → Stealth analysis
3. **"The attack is robust"** → Minimum dose + escalation
4. **"The attack has real-world impact"** → Pipeline simulation
5. **"Here is our defense"** → (your defense chapter)
