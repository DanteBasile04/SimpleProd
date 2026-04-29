# SimpleProd v0.1.0

**Bundle de Provisionamiento VPS — Clean Architecture, Safety-First, para Principiantes**

[![Versión](https://img.shields.io/badge/versi%C3%B3n-0.1.0-blue)](https://github.com/DanteBasile04/SimpleProd/releases/tag/v0.1.0)
[![Testeado](https://img.shields.io/badge/testeado-Ubuntu%2022.04%20%7C%20Vagrant%20VM-brightgreen)](#-resultados-de-testing)
[![Licencia](https://img.shields.io/badge/licencia-MIT-green)](LICENSE)

<p align="center">
  <br>
  <em>🇦🇷 Español (Rioplatense) &nbsp;|&nbsp; 🇺🇸 <a href="../../README.md">English</a></em>
</p>

---

## ¿Qué es SimpleProd?

SimpleProd es un **bundle de provisionamiento VPS para principiantes** que convierte un servidor Ubuntu/Debian pelado en un entorno listo para producción en minutos. Enseña **CONCEPTOS, no comandos** — vas a entender QUÉ estás haciendo y POR QUÉ, no solo copiar y pegar scripts.

**Tres adaptadores, un mismo dominio:**
- **Scripts Bash** — aprendé leyendo, ideal para principiantes que quieren entender cada línea
- **Roles Ansible** — automatizá a escala, idempotente por diseño, multi-servidor
- **TUI en Python** — wizard interactivo con barras de progreso Rich y preview dry-run

Los tres implementan los mismos 15 casos de uso. Elegí el que se adapte a tu nivel.

---

## 🚀 Arranque rápido

### Opción 1: TUI en Python (recomendado para principiantes)

```bash
git clone https://github.com/DanteBasile04/SimpleProd.git
cd SimpleProd

# Instalar dependencias
cd infrastructure/python
pip3 install --user questionary rich click pyyaml

# Ejecutar el wizard interactivo
PYTHONPATH=. python3 -c "from simpleprod.cli import main; main()"
```

### Opción 2: Scripts Bash (aprendé leyendo)

```bash
# Primero dry-run — SIEMPRE
sudo SP_LANG=es bash infrastructure/bash/main.sh --dry-run

# Revisá la salida, después ejecutá de verdad
sudo SP_LANG=es bash infrastructure/bash/main.sh
```

### Opción 3: Ansible (automatización pro)

```bash
# Chequeo de sintaxis
ansible-playbook -i infrastructure/ansible/inventory/vagrant.yml \
  infrastructure/ansible/playbooks/site.yml --syntax-check

# Dry run
ansible-playbook -i infrastructure/ansible/inventory/vagrant.yml \
  infrastructure/ansible/playbooks/site.yml --check

# Ejecutar
sudo ANSIBLE_ROLES_PATH=infrastructure/ansible/roles \
  ansible-playbook -i infrastructure/ansible/inventory/vagrant.yml \
  infrastructure/ansible/playbooks/site.yml
```

> ⚠️ **Corré siempre dry-run primero.** SimpleProd modifica configuración del sistema. El flag `--dry-run` muestra exactamente qué va a cambiar sin tocar nada.

---

## ✨ Funcionalidades

- 🛡️ **Safety-First (Domain 0)** — Prevención de lockout, verificaciones previas, backups automáticos, rollback ante fallos
- 🐳 **3 caminos de deployment** — Aislamiento Docker, Aislamiento System User, o Híbrido
- 🧱 **Clean Architecture** — Domain (qué) → Application (composición) → Infrastructure (cómo)
- 🔄 **3 adaptadores** — Bash (aprender · un servidor), Ansible (automatizar · multi-servidor), Python TUI (interactuar · wizard)
- 🌐 **Bilingüe** — Inglés y Español (Rioplatense), configurable por ejecución
- 🚀 **CI/CD listo** — GitHub Actions para lint, test, y release
- 🔒 **15 casos de uso** — SSH hardening, UFW, fail2ban, Nginx+SSL, PostgreSQL, Docker, Node.js, PM2, y más
- 📦 **7 plantillas Jinja2** — Roles Ansible renderizan config dinámicamente (sin strings hardcodeados)

---

## 🛡️ Domain 0: Garantías de Seguridad

SimpleProd te protege de los desastres más comunes al configurar un VPS. Cada mecanismo de seguridad está implementado en los tres adaptadores.

| Protección | Bash | Ansible | Cómo |
|------------|:----:|:-------:|------|
| 🔑 Prevención de lockout | ✅ | ✅ | Verifica clave SSH ANTES de deshabilitar password auth |
| 🔥 Seguridad firewall | ✅ | ✅ | Permite SSH ANTES de habilitar deny-all |
| 💾 Auto-backup | ✅ | ✅ | Backup con timestamp de cada archivo de config |
| 🔄 Rollback | ✅ | — | Restaura desde backups si algún paso falla |
| ⚠️ Manejo de fallos | ✅ | ✅ | Reintentar / Saltar / Revertir / Abortar en cada paso |
| 🔐 Gestión de secretos | ✅ | ✅ | Contraseñas con modo 600, nunca en logs |
| 🧪 Verificaciones previas | ✅ | ✅ | Root, SO, internet, disco (≥10GB), RAM (≥1GB) |
| 👁️ Modo dry-run | ✅ | ✅ | Previsualizá todos los cambios antes de aplicar |

> 📖 Leé la [Documentación de Seguridad](../../SAFETY.md) completa

---

## 📐 Arquitectura

```
SimpleProd/
├── domain/                        # QUÉ: Casos de uso + entidades (YAML puro, sin código)
│   ├── usecases/                  # 15 casos de uso de provisionamiento
│   └── entities/                  # Server, Client, Database, AppConfig
├── application/                   # COMPOSICIÓN: Caminos + orquestador + config
│   ├── paths/                     # 3 especificaciones de caminos de deployment
│   └── config/                    # Defaults + mensajes EN/ES
├── infrastructure/                # CÓMO: 3 adaptadores independientes
│   ├── bash/                      # Scripts Bash (principiantes, un servidor)
│   │   ├── adapters/              # 15 scripts setup-*.sh
│   │   ├── common/                # safety, backup, logging, secrets
│   │   └── main.sh                # Punto de entrada con orden de dependencias
│   ├── ansible/                   # Roles Ansible (automatización, multi-servidor)
│   │   ├── roles/                 # 15 roles con tasks + defaults + templates
│   │   ├── playbooks/             # site.yml + plays por camino
│   │   └── inventory/             # producción + vagrant + group_vars
│   └── python/                    # TUI Python (interactivo, Rich + Questionary)
│       └── simpleprod/
│           ├── cli.py             # Entrada CLI con Click
│           ├── orchestrator/      # config resolver, preflight, resolver, runner
│           ├── tui/               # wizard, display, menus
│           └── i18n/              # Mensajes EN/ES
├── ci/                            # Workflows GitHub Actions
├── ansible.cfg                    # Config compartida de Ansible
├── VERSION                        # Versión semántica (leída por el banner)
└── Makefile                       # Objetivos lint, test, release
```

**Clean Architecture en 3 oraciones:**
1. **Domain** define QUÉ hace cada paso — datos puros, sin código, YAML agnóstico del lenguaje
2. **Application** define CÓMO se componen los pasos en caminos de deployment — lógica del orquestador
3. **Infrastructure** implementa los pasos en Bash, Ansible, o Python — adaptadores intercambiables

---

## 📦 Componentes (testeados en Ubuntu 22.04)

| Componente | Bash | Ansible | Descripción |
|-----------|:----:|:-------:|-------------|
| Base Tools | ✅ | ✅ | git, curl, wget, vim, htop, tmux, unzip, build-essential |
| SSH Hardening | ✅ | ✅ | Solo key auth, deshabilita root, deshabilita password, puerto configurable |
| UFW Firewall | ✅ | ✅ | Permite SSH primero → HTTP/HTTPS → deny-all (orden Domain 0) |
| Fail2Ban | ✅ | ✅ | Jail SSH con bantime/findtime/maxretry configurables |
| Nginx + SSL | ✅ | ✅ | Reverse proxy + Certbot (listo para Let's Encrypt) |
| Node.js | ✅ | ✅ | nvm → Node.js LTS → PM2 process manager |
| Docker | ✅ | ✅ | Docker CE + Docker Compose v2 |
| PostgreSQL | ✅ | ✅ | Base de datos + usuario, contraseña persistida |
| Homebrew | ✅ | ✅ | Linuxbrew en directorio home |
| Zsh + Starship | ✅ | ✅ | Shell moderno con prompt Starship |
| AI/Dev Tools | ✅ | ✅ | Opencode CLI + GitHub CLI |
| Backups | ✅ | ✅ | Dump PostgreSQL con rotación de 7 días (cron) |
| Monitoring | ✅ | ✅ | Alertas disco/CPU/RAM vía cron (cada 15min) |
| Logrotate | ✅ | ✅ | Logs Nginx (14 días) + App (30 días de rotación) |
| Base User | ✅ | ✅ | Usuario deploy no-root con sudo, directorio SSH |

> Los componentes marcados ✅ están completamente implementados y testeados en una VM real. Las plantillas usan Jinja2 (sin valores hardcodeados).

---

## 🧪 Resultados de Testing (VM Vagrant, Ubuntu 22.04, 2GB RAM)

| Adaptador | Tests | Resultado |
|-----------|-------|-----------|
| **Bash** | 5 pasos (base-tools, user, ssh, ufw, fail2ban) | ✅ Todos OK |
| **Ansible** | 45 tareas en 4 plays | ✅ 45/45 OK |
| **Python** | Config resolver, step resolver, preflight (5 checks), CLI dry-run | ✅ End-to-end |

**Servicios verificados después del provisionamiento completo:**
```
ssh:       active  ✅  passwordauth=no  permitrootlogin=no
ufw:       active  ✅  SSH(22) + HTTP(80) + HTTPS(443) permitidos
fail2ban:  active  ✅  1 jail (sshd)
nginx:     active  ✅  reverse proxy configurado
docker:    active  ✅  v29.1.3
postgresql: active ✅  base simpleprod creada
pm2:       v6.0.14 ✅
```

---

## 📖 Documentación

- **[SAFETY.md](../../SAFETY.md)** — Documentación completa de seguridad con todos los mecanismos Domain 0
- **[docs/en/README.md](../en/README.md)** — Guía rápida en inglés
- **[docs/es/README.md](README.md)** — Esta guía en español (rioplatense)

---

## 🤝 Contribuir

SimpleProd está diseñado para principiantes — las contribuciones que mejoren la claridad, seguridad o documentación son especialmente bienvenidas.

```bash
# Lint de todo
make lint

# Chequeos de sintaxis
make test

# Crear un release
make release
```

---

## 📄 Licencia

MIT — hacé lo que quieras, solo no nos culpes si salteaste `--dry-run`.