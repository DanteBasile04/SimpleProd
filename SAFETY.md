# SimpleProd — Safety Documentation (Domain 0)

## Why Domain 0 Exists

Setting up a VPS is dangerous. A single typo in an SSH config can lock you out forever. Enabling a firewall without allowing SSH first means instant disconnection. Overwriting configs without backup means no way back.

**Domain 0 is the safety layer that runs BEFORE any provisioning.** It validates that:
1. You won't get locked out (SSH key verification)
2. The environment meets minimum requirements (pre-flight checks)
3. Every change is reversible (auto-backup + rollback)
4. You can preview before applying (dry-run mode)
5. Secrets remain secret (never logged, restricted permissions)

If Domain 0 fails, **nothing happens** — the entire provisioning stops.

---

## 1. SSH Lockout Prevention (CRITICAL)

**Risk:** Disabling password authentication without verifying key-based auth works means permanent lockout.

### Bash Adapter — 7-Step Process

```
Step 1: BACKUP         sshd_config → sshd_config.{timestamp}.bak
Step 2: VERIFY KEY     Check authorized_keys exists AND has content
Step 3: DETECT         Check current SSH configuration
Step 4: HARDEN         Apply changes (port, password auth, root login, etc.)
Step 5: VALIDATE       sshd -t — validate syntax before restart
Step 6: RESTART        Restart SSH service
Step 7: VERIFY         Open new SSH connection to confirm session alive
```

If **any step fails**, password authentication remains enabled. The `sp_verify_ssh_key_auth()` function checks that the deploy user's `authorized_keys` file exists AND has content.

### Ansible Adapter

```yaml
- name: Check if authorized_keys exists for user
  ansible.builtin.stat:
    path: "/home/{{ simpleprod_ssh_user }}/.ssh/authorized_keys"
  register: _ssh_key_file

- name: FAIL if SSH key is not configured
  ansible.builtin.fail:
    msg: "LOCKOUT RISK: Could not verify key authentication"
  when: not _ssh_key_file.stat.exists or _ssh_key_file.stat.size == 0
```

Playbook **halts immediately** if no authorized_keys found. Password auth stays enabled.

---

## 2. UFW Firewall Safety

**Risk:** Enabling `ufw --force enable` with deny-all policy before allowing SSH means instant disconnection.

### The Golden Rule: ALLOW FIRST, THEN DENY

```
Step 1: ufw allow SSH (port 22 or custom)
Step 2: ufw allow HTTP (port 80)
Step 3: ufw allow HTTPS (port 443)
Step 4: ufw enable (policy: deny incoming)
```

SSH is **always allowed first** — before any deny rule takes effect. This order is enforced in Bash (line order in `setup-ufw.sh`) and Ansible (task order in `ufw/tasks/main.yml`).

### Port Consistency

The SSH port is shared across all components via `simpleprod_ssh_port` (group_vars/all.yml). If you change the SSH port, UFW and Fail2Ban automatically use the new port — no manual sync needed.

---

## 3. Pre-flight Checks

Before any provisioning run (Bash, Ansible, or Python), 5 checks run:

| Check | Requirement | Failure Action |
|-------|-------------|----------------|
| **Root privileges** | Must run as root or with sudo | Abort immediately |
| **OS compatibility** | Ubuntu 22.04+ or Debian 12+ | Abort — unsupported |
| **Internet connectivity** | Can reach 8.8.8.8 | Abort — can't install packages |
| **Disk space** | ≥ 10GB free on `/` | Abort — insufficient space |
| **RAM** | ≥ 1GB available | Abort — insufficient memory |

All checks must pass. If any fails, provisioning stops — no partial states.

### Python Orchestrator

```python
checks = [
    (check_root(), "Root privileges"),
    (check_os(), "Supported OS"),
    (check_internet(), "Internet connectivity"),
    (check_disk_space(), "Disk space"),
    (check_ram(), "RAM")
]
```

Each check shows a Rich Panel (green ✓ or red ✗). Add `--no-preflight` to skip (dangerous).

---

## 4. Auto-Backup and Rollback

### Backup

Every config file modification creates a timestamped backup:

```
/etc/ssh/sshd_config              →  /var/backups/simpleprod/etc/ssh/sshd_config.1712345678.bak
/etc/nginx/sites-available/default →  /etc/nginx/sites-available/default.bak
```

Bash adapter uses `sp_manifest_start()` / `sp_backup_file()` to track all modifications. Ansible uses the `copy` module with `remote_src: true` for backups.

### Rollback

If a step fails, the Bash adapter offers an interactive menu:

```
[R] Retry  — run this step again
[S] Skip   — continue without this step
[B] Rollback — revert ALL changes made in this run
[A] Abort  — stop provisioning immediately
```

The Python orchestrator implements the same menu with Questionary select prompts. Ansible uses built-in `--check` mode for dry-run and `--start-at-task` for partial reruns.

---

## 5. Dry-Run Mode

**ALWAYS run dry-run first.** All three adapters support it:

```bash
# Bash
sudo SP_DRY_RUN=true bash infrastructure/bash/main.sh --dry-run

# Ansible
ansible-playbook ... --check

# Python
python3 -m simpleprod.cli --dry-run
```

In dry-run mode:
- Config is resolved and validated
- Pre-flight checks run
- Steps are listed in execution order
- **No system changes are made**
- Bash prints `[DRY RUN]` prefix for every command
- Ansible reports what WOULD change
- Python shows a Rich table preview + progress bar

---

## 6. Failure Handling

### Per-Step Recovery

Every step (Bash adapter) and task (Ansible adapter) can fail independently. The failure doesn't cascade:

| Option | Behavior |
|--------|----------|
| **Retry** | Re-run the failed step immediately |
| **Skip** | Continue to next step; dependent steps are also skipped |
| **Rollback** | Restore all backups created during this run |
| **Abort** | Stop execution; keep current system state |

### Dependency Chain Protection

Dependencies are enforced in `application/config/defaults.yaml`. If a dependency fails and is skipped, all dependent steps are automatically skipped too:

```
base-tools → user → ssh → ufw → fail2ban
                             → nginx-ssl → logrotate
```

---

## 7. Secret Management

**Passwords are never logged, displayed, or committed to git.**

| Practice | Implementation |
|----------|---------------|
| **Never log passwords** | `sp_secret_store()` writes to mode 600 files |
| **Git-ignored** | `credentials/` and `secrets/` in `.gitignore` |
| **Persisted across runs** | PostgreSQL password stored in file (not regenerated) |
| **SSH keys** | Setup-user.sh copies keys with correct permissions (600) |
| **Ansible Vault-ready** | Passwords can be encrypted with `ansible-vault encrypt` |

PostgreSQL password generation:
```yaml
# BEFORE (broken): generated new password every run
db_password: "{{ lookup('password', '/dev/null') }}"

# AFTER (fixed): persists in credentials/ directory
db_password: "{{ lookup('password', 'credentials/postgres_password.txt') }}"
```

---

## 8. GitHub Actions CI/CD

Three workflows enforce quality before every release:

| Workflow | File | What it checks |
|----------|------|---------------|
| **Lint** | `ci/.github/workflows/lint.yml` | YAML syntax, Bash shellcheck, Python flake8 |
| **Test** | `ci/.github/workflows/test.yml` | All YAML parse, all Bash scripts valid, Python imports |
| **Release** | `ci/.github/workflows/release.yml` | Triggers on tag push, creates GitHub Release |

---

## 9. Versioning

SimpleProd uses **semantic versioning** (`MAJOR.MINOR.PATCH`):

- `VERSION` file at project root (currently `0.1.0`)
- Banner reads `VERSION` dynamically — no hardcoded version strings
- Tag format: `v{version}` (e.g. `v0.1.0`)

---

## Safety Checklist (before running in production)

- [ ] Run `--dry-run` first — review ALL output
- [ ] Verify SSH key is in deploy user's `~/.ssh/authorized_keys`
- [ ] Open a second terminal — test key auth BEFORE running
- [ ] Check disk space: `df -h /` (need ≥ 10GB)
- [ ] Check RAM: `free -h` (need ≥ 1GB)
- [ ] Verify internet: `ping -c 1 8.8.8.8`
- [ ] Know the rollback path: check `/var/backups/simpleprod/`
- [ ] Be ready to use the second terminal if SSH session drops