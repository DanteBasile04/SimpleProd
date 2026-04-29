# SimpleProd — Safety Documentation

> 📖 The canonical safety documentation is now at **[SAFETY.md](../../SAFETY.md)** in the project root.

This file is kept for backwards compatibility. Please refer to the root SAFETY.md for the complete Domain 0 safety documentation covering:

- SSH Lockout Prevention (7-step process)
- UFW Firewall Safety (allow first, deny later)
- Pre-flight Checks (root, OS, internet, disk, RAM)
- Auto-Backup and Rollback
- Dry-Run Mode
- Failure Handling (retry/skip/rollback/abort)
- Secret Management
- GitHub Actions CI/CD safety enforcement
- Safety Checklist for production

All mechanisms are documented with code examples from Bash, Ansible, and Python adapters.