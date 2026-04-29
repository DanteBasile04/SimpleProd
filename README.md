# SimpleProd v0.1.0

**VPS Production Setup Bundle — Clean Architecture, Safety-First, Beginner-Friendly**

[![Version](https://img.shields.io/badge/version-0.1.0-blue)](https://github.com/DanteBasile04/SimpleProd/releases/tag/v0.1.0)
[![Tested](https://img.shields.io/badge/tested-Ubuntu%2022.04%20%7C%20Vagrant%20VM-brightgreen)](#-testing-results)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

<p align="center">
  <br>
  <em>🇺🇸 English &nbsp;|&nbsp; 🇦🇷 <a href="docs/es/README.md">Español (Rioplatense)</a></em>
</p>

---

## What is SimpleProd?

SimpleProd is a **beginner-friendly VPS provisioning bundle** that turns a bare Ubuntu/Debian server into a production-ready environment in minutes. It teaches **CONCEPTS over commands** — you'll understand WHAT you're doing and WHY, not just copy-paste scripts.

**Three adapters, one domain:**
- **Bash scripts** — learn by reading, perfect for beginners who want to understand every line
- **Ansible roles** — automate at scale, idempotent by design, multi-server ready
- **Python TUI** — interactive wizard with Rich progress bars and dry-run previews

All three implement the same 15 use cases. Pick the one that matches your comfort level.

---

## 🚀 Quick Start

### Option 1: Python TUI (recommended for beginners)

```bash
git clone https://github.com/DanteBasile04/SimpleProd.git
cd SimpleProd

# Install dependencies
cd infrastructure/python
pip3 install --user questionary rich click pyyaml

# Run the interactive wizard
PYTHONPATH=. python3 -c "from simpleprod.cli import main; main()"
```

### Option 2: Bash scripts (learn by reading)

```bash
# Dry-run first — ALWAYS
sudo SP_LANG=en bash infrastructure/bash/main.sh --dry-run

# Review the output, then run for real
sudo SP_LANG=en bash infrastructure/bash/main.sh
```

### Option 3: Ansible (automation pro)

```bash
# Syntax check
ansible-playbook -i infrastructure/ansible/inventory/vagrant.yml \
  infrastructure/ansible/playbooks/site.yml --syntax-check

# Dry run
ansible-playbook -i infrastructure/ansible/inventory/vagrant.yml \
  infrastructure/ansible/playbooks/site.yml --check

# Run
sudo ANSIBLE_ROLES_PATH=infrastructure/ansible/roles \
  ansible-playbook -i infrastructure/ansible/inventory/vagrant.yml \
  infrastructure/ansible/playbooks/site.yml
```

> ⚠️ **Always run dry-run first.** SimpleProd modifies system configuration. The `--dry-run` flag shows exactly what will change before touching anything.

---

## ✨ Features

- 🛡️ **Safety-First (Domain 0)** — Lockout prevention, pre-flight checks, automatic backups, rollback on failure
- 🐳 **3 Deployment Paths** — Docker isolation, System User isolation, or Hybrid
- 🧱 **Clean Architecture** — Domain (what) → Application (composition) → Infrastructure (how)
- 🔄 **3 Adapters** — Bash (learn · single server), Ansible (automate · multi-server), Python TUI (interact · wizard)
- 🌐 **Bilingual** — English and Spanish (Rioplatense), configurable per run
- 🚀 **CI/CD Ready** — GitHub Actions for lint, test, and release
- 🔒 **15 Use Cases** — SSH hardening, UFW, fail2ban, Nginx+SSL, PostgreSQL, Docker, Node.js, PM2, and more
- 📦 **7 Jinja2 Templates** — Ansible roles render config dynamically (not hardcoded strings)

---

## 🛡️ Domain 0: Safety Guarantees

SimpleProd protects you from the most common VPS setup disasters. Every safety mechanism is implemented in all three adapters.

| Protection | Bash | Ansible | How |
|------------|:----:|:-------:|-----|
| 🔑 Lockout prevention | ✅ | ✅ | Verifies SSH key BEFORE disabling password auth |
| 🔥 Firewall safety | ✅ | ✅ | Allows SSH port BEFORE enabling deny-all |
| 💾 Auto-backup | ✅ | ✅ | Timestamps every config file before modification |
| 🔄 Rollback | ✅ | — | Restores from backups if any step fails |
| ⚠️ Failure handling | ✅ | ✅ | Retry / Skip / Rollback / Abort on every step |
| 🔐 Secret management | ✅ | ✅ | Passwords stored with mode 600, never logged |
| 🧪 Pre-flight checks | ✅ | ✅ | Root, OS, internet, disk (≥10GB), RAM (≥1GB) |
| 👁️ Dry-run mode | ✅ | ✅ | Preview all changes before applying |

> 📖 Read the full [Safety Documentation](SAFETY.md)

---

## 📐 Architecture

```
SimpleProd/
├── domain/                        # WHAT: Use cases + entities (pure YAML, no code)
│   ├── usecases/                  # 15 setup use cases
│   └── entities/                  # Server, Client, Database, AppConfig
├── application/                   # COMPOSITION: Paths + orchestrator + config
│   ├── paths/                     # 3 deployment path specs
│   └── config/                    # Defaults + EN/ES messages
├── infrastructure/                # HOW: 3 independent adapters
│   ├── bash/                      # Bash scripts (beginner-friendly, single server)
│   │   ├── adapters/              # 15 setup-*.sh scripts
│   │   ├── common/                # safety, backup, logging, secrets
│   │   └── main.sh                # Entry point with dependency order
│   ├── ansible/                   # Ansible roles (automation, multi-server)
│   │   ├── roles/                 # 15 roles with tasks + defaults + templates
│   │   ├── playbooks/             # site.yml + path-specific plays
│   │   └── inventory/             # production + vagrant + group_vars
│   └── python/                    # Python TUI (interactive, Rich + Questionary)
│       └── simpleprod/
│           ├── cli.py             # Click CLI entry point
│           ├── orchestrator/      # config resolver, preflight, resolver, runner
│           ├── tui/               # wizard, display, menus
│           └── i18n/              # EN/ES messages
├── ci/                            # GitHub Actions workflows
├── ansible.cfg                    # Shared Ansible config
├── VERSION                        # Semantic version (read by banner)
└── Makefile                       # Lint, test, release targets
```

**Clean Architecture in 3 sentences:**
1. **Domain** defines WHAT each setup step does — pure data, no code, language-agnostic YAML
2. **Application** defines HOW steps compose into deployment paths — orchestrator logic
3. **Infrastructure** implements steps in Bash, Ansible, or Python — interchangeable adapters

---

## 📦 Components (tested on Ubuntu 22.04)

| Component | Bash | Ansible | Description |
|-----------|:----:|:-------:|-------------|
| Base Tools | ✅ | ✅ | git, curl, wget, vim, htop, tmux, unzip, build-essential |
| SSH Hardening | ✅ | ✅ | Key-only auth, disable root, disable password, configurable port |
| UFW Firewall | ✅ | ✅ | Allow SSH first → HTTP/HTTPS → deny-all (Domain 0 order) |
| Fail2Ban | ✅ | ✅ | SSH jail with configurable bantime/findtime/maxretry |
| Nginx + SSL | ✅ | ✅ | Reverse proxy + Certbot (Let's Encrypt ready) |
| Node.js | ✅ | ✅ | nvm → Node.js LTS → PM2 process manager |
| Docker | ✅ | ✅ | Docker CE + Docker Compose v2 |
| PostgreSQL | ✅ | ✅ | Database + user creation, password persisted |
| Homebrew | ✅ | ✅ | Linuxbrew in home directory |
| Zsh + Starship | ✅ | ✅ | Modern shell with Starship prompt |
| AI/Dev Tools | ✅ | ✅ | Opencode CLI + GitHub CLI |
| Backups | ✅ | ✅ | PostgreSQL dump with 7-day rotation cron job |
| Monitoring | ✅ | ✅ | Disk/CPU/RAM alerts via cron (every 15min) |
| Logrotate | ✅ | ✅ | Nginx logs (14-day) + App logs (30-day rotation) |
| Base User | ✅ | ✅ | Non-root deploy user with sudo, SSH directory |

> Components marked ✅ are fully implemented and tested on a real VM. Templates use Jinja2 (not hardcoded values).

---

## 🧪 Testing Results (Vagrant VM, Ubuntu 22.04, 2GB RAM)

| Adapter | Tests | Result |
|---------|-------|--------|
| **Bash** | 5 steps (base-tools, user, ssh, ufw, fail2ban) | ✅ All passed |
| **Ansible** | 45 tasks across 4 plays | ✅ 45/45 OK |
| **Python** | Config resolver, step resolver, preflight (5 checks), CLI dry-run | ✅ End-to-end |

**Services verified after full provisioning:**
```
ssh:       active  ✅  passwordauth=no  permitrootlogin=no
ufw:       active  ✅  SSH(22) + HTTP(80) + HTTPS(443) allowed
fail2ban:  active  ✅  1 jail (sshd)
nginx:     active  ✅  reverse proxy configured
docker:    active  ✅  v29.1.3
postgresql: active ✅  simpleprod database created
pm2:       v6.0.14 ✅
```

---

## 📖 Documentation

- **[SAFETY.md](SAFETY.md)** — Complete safety documentation with all Domain 0 mechanisms
- **[docs/en/README.md](docs/en/README.md)** — English quick start guide
- **[docs/es/README.md](docs/es/README.md)** — Spanish (Rioplatense) quick start guide

---

## 🤝 Contributing

SimpleProd is designed for beginners — contributions that improve clarity, safety, or documentation are especially welcome.

```bash
# Lint everything
make lint

# Run syntax checks
make test

# Create a release
make release
```

---

## 📄 License

MIT — do what you want, just don't blame us if you skip `--dry-run` first.