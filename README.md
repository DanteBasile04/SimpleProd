# SimpleProd

**VPS Production Setup Bundle — Clean Architecture, Safety-First, Beginner-Friendly**

<p align="center">
  <br>
  <em>🇺🇸 <a href="docs/en/README.md">English</a> &nbsp;|&nbsp; 🇦🇷 <a href="docs/es/README.md">Español (Rioplatense)</a></em>
</p>

---

## What is SimpleProd?

SimpleProd is a **beginner-friendly VPS provisioning bundle** that turns a bare Ubuntu/Debian server into a production-ready environment. It teaches **CONCEPTS over commands** — you'll understand WHAT you're doing and WHY, not just copy-paste scripts.

## ✨ Features

- 🛡️ **Safety-First**: Lockout prevention, pre-flight checks, automatic backups, step failure handling
- 🐳 **3 Deployment Paths**: Docker isolation, System User isolation, or Hybrid
- 🧱 **Clean Architecture**: Domain (what) → Application (composition) → Infrastructure (how)
- 🔄 **3 Adapters**: Bash (learn), Ansible (automate), Python TUI (interact)
- 🌐 **Bilingual**: English and Spanish with configurable language
- 🚀 **CI/CD Ready**: GitHub Actions for lint, test, and release
- 🔒 **15 Use Cases**: SSH hardening, UFW, fail2ban, Nginx+SSL, PostgreSQL, Docker, Node.js, and more

## 🚀 Quick Start

```bash
# Clone and enter
git clone https://github.com/YOUR_USER/SimpleProd.git
cd SimpleProd

# Run the TUI wizard (recommended for beginners)
cd infrastructure/python && python -m simpleprod.cli

# Or run Bash scripts directly
sudo bash infrastructure/bash/main.sh --dry-run  # preview first!
sudo bash infrastructure/bash/main.sh             # actually run

# Or use Ansible (pro path)
ansible-playbook -i infrastructure/ansible/inventory/production.yml \
  infrastructure/ansible/playbooks/site.yml
```

## 📐 Architecture

```
SimpleProd/
├── domain/                    # WHAT: Use cases + entities
│   ├── usecases/              # 15 setup use cases (SSH, UFW, Docker, etc.)
│   └── entities/              # Server, Client, Database, AppConfig
├── application/               # COMPOSITION: Paths + orchestrator + config
│   ├── paths/                 # 3 deployment paths (Docker, SystemUser, Hybrid)
│   └── config/                # YAML config + EN/ES messages
├── infrastructure/            # HOW: 3 adapters
│   ├── bash/                  # Bash scripts (beginner-friendly)
│   ├── ansible/               # Ansible roles + playbooks (automation)
│   └── python/                # Python TUI (Questionary + Rich)
├── ci/                        # GitHub Actions workflows
└── docs/                      # EN/ES documentation
```

## 🛡️ Domain 0: Safety Guarantees

SimpleProd protects you from the most common VPS setup disasters:

| Protection | How |
|------------|-----|
| 🔑 **Lockout prevention** | Verifies SSH key authentication BEFORE disabling password auth |
| 🔥 **Firewall safety** | Allows SSH port BEFORE enabling deny-all policy |
| 💾 **Automatic backups** | Timestamps every config file before modification |
| 🔄 **Rollback** | Restores from backups if any step fails |
| ⚠️ **Failure handling** | Retry / Skip / Rollback / Abort on every step |
| 🔐 **Secret management** | Passwords stored with mode 600, never logged |

## 📦 Components

| Component | Bash | Ansible | Description |
|-----------|------|---------|-------------|
| SSH Hardening | ✅ | ✅ | Key-only auth, disable root, configurable port |
| UFW Firewall | ✅ | ✅ | Allow SSH first, then HTTP/HTTPS, then deny-all |
| Fail2ban | ✅ | ✅ | Ban repeated failed SSH attempts |
| Nginx + SSL | ✅ | ✅ | Reverse proxy + Let's Encrypt |
| Node.js | ✅ | ✅ | nvm + Node.js LTS + PM2 |
| Docker | ✅ | ✅ | Docker CE + Docker Compose |
| PostgreSQL | ✅ | ✅ | Database + user per client, secure credentials |
| Homebrew | ✅ | ✅ | Linuxbrew in home directory |
| Zsh + Starship | ✅ | ✅ | Modern shell with beautiful prompt |
| AI/Dev Tools | ✅ | ✅ | Opencode CLI + GitHub CLI |
| Backups | ✅ | ✅ | Automated DB backups with cron |
| Monitoring | ✅ | ✅ | Disk/CPU/memory alerts |
| Logrotate | ✅ | ✅ | Log rotation for Nginx + apps |

## 🔧 Testing

```bash
# Run all tests
make test

# Lint only
make lint

# Create release
make release
```

All 100+ YAML files, 19 Bash scripts, and 11 Python modules pass syntax validation.
See `ci/.github/workflows/` for automated CI/CD pipelines.

## 📖 Documentation

- [English README](docs/en/README.md)
- [Spanish README (Rioplatense)](docs/es/README.md)
- [Safety Documentation](docs/en/SAFETY.md)

## 🤝 Contributing

SimpleProd is designed for beginners — contributions that improve clarity, safety, or documentation are especially welcome. See `Makefile` for lint and test targets.

## 📄 License

MIT — do what you want, just don't blame us if you run without `--dry-run` first.