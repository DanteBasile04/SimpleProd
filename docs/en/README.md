# SimpleProd v0.1.0

**VPS Production Setup Bundle — Clean Architecture, Safety-First, Beginner-Friendly**

<p align="center">
  <br>
  <em>🇺🇸 English &nbsp;|&nbsp; 🇦🇷 <a href="../es/README.md">Español (Rioplatense)</a></em>
</p>

---

## Quick Start

### Python TUI (recommended)

```bash
git clone https://github.com/DanteBasile04/SimpleProd.git
cd SimpleProd/infrastructure/python
pip3 install --user questionary rich click pyyaml
PYTHONPATH=. python3 -c "from simpleprod.cli import main; main()"
```

### Bash scripts (learn by reading)

```bash
sudo SP_LANG=en bash infrastructure/bash/main.sh --dry-run   # preview
sudo SP_LANG=en bash infrastructure/bash/main.sh             # run
```

### Ansible (automation)

```bash
sudo ANSIBLE_ROLES_PATH=infrastructure/ansible/roles \
  ansible-playbook -i infrastructure/ansible/inventory/vagrant.yml \
  infrastructure/ansible/playbooks/site.yml --check           # dry run
sudo ANSIBLE_ROLES_PATH=infrastructure/ansible/roles \
  ansible-playbook -i infrastructure/ansible/inventory/vagrant.yml \
  infrastructure/ansible/playbooks/site.yml                   # run
```

> ⚠️ Always run dry-run first.

---

## Features

- 🛡️ **Safety-First (Domain 0)** — SSH lockout prevention, UFW order safety, auto-backup, rollback
- 🐳 **3 deployment paths** — Docker, System User, Hybrid
- 🔄 **3 adapters** — Bash (learn), Ansible (automate), Python TUI (interact)
- 🌐 **Bilingual** — English and Spanish, configurable per run
- 🚀 **CI/CD** — GitHub Actions: lint, test, release
- 🔒 **15 use cases** — SSH, UFW, fail2ban, Nginx+SSL, PostgreSQL, Docker, Node.js, PM2, more

---

## Architecture

```
domain/               # WHAT: 15 YAML use cases + entities (no code)
application/          # COMPOSITION: 3 paths + config + messages
infrastructure/       # HOW: Bash (scripts), Ansible (roles), Python (TUI)
├── bash/             # Single-server, beginner-friendly
├── ansible/          # Multi-server, idempotent automation
└── python/           # Interactive wizard + orchestrator
```

**Clean Architecture:** Domain (what) → Application (composition) → Infrastructure (how). All three adapters implement the same 15 use cases. They are interchangeable.

---

## Safety (Domain 0)

| Protection | Bash | Ansible | How |
|------------|:----:|:-------:|-----|
| 🔑 Lockout prevention | ✅ | ✅ | Verify SSH key BEFORE disabling password auth |
| 🔥 Firewall safety | ✅ | ✅ | Allow SSH BEFORE deny-all |
| 💾 Auto-backup | ✅ | ✅ | Timestamp every config file before modification |
| 🔄 Rollback | ✅ | — | Restore from backups on failure |
| ⚠️ Failure handling | ✅ | ✅ | Retry / Skip / Rollback / Abort per step |
| 🔐 Secrets | ✅ | ✅ | Mode 600, never logged, git-ignored |
| 🧪 Pre-flight | ✅ | ✅ | Root, OS, internet, disk (10GB), RAM (1GB) |
| 👁️ Dry-run | ✅ | ✅ | Preview before applying |

> 📖 Full docs: [SAFETY.md](../../SAFETY.md) — every mechanism explained in detail.

---

## Tested On

| Adapter | Tests | VM |
|---------|-------|-----|
| Bash | 5/5 steps | Ubuntu 22.04, 2GB RAM |
| Ansible | 45/45 tasks | Ubuntu 22.04, 2GB RAM |
| Python | E2E (config, preflight, resolver, runner) | Ubuntu 22.04, 2GB RAM |

```
ssh ✓  ufw ✓  fail2ban ✓  nginx ✓  docker ✓  postgresql ✓  pm2 ✓
```

---

## Documentation

- **[Root README](../../README.md)** — Complete overview with components table and test results
- **[SAFETY.md](../../SAFETY.md)** — Domain 0 safety documentation
- **[docs/es/README.md](../es/README.md)** — Spanish (Rioplatense)

---

## License

MIT — do what you want, just don't blame us if you skip `--dry-run` first.