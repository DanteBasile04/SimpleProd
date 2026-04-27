# SimpleProd

## Project Overview
SimpleProd is a server provisioning tool that automates the setup of production servers with hardened security and isolation.

## Quick Start Guide

### Docker Isolation Path
1. Install Docker
2. Run `docker-compose -f application/paths/docker/compose.yaml up`

### System User Isolation Path
1. Install Ansible
2. Run `ansible-playbook -i infrastructure/ansible/inventory/production.yml infrastructure/ansible/playbooks/site.yml`

### Hybrid Path
1. Install Docker and Ansible
2. Run both the Docker compose and Ansible playbook

## Safety Guarantees
- Domain 0 isolation
- Lockout prevention
- Pre-flight checks
- Step failure handling
- Backup and rollback
- Secret management

## Configuration Options
- Customize `application/paths/` for different isolation strategies
- Modify `infrastructure/ansible/inventory/` for multi-server setups

## How It Works
SimpleProd follows Clean Architecture principles with:
- Clear separation of concerns
- Dependency inversion
- Independent deployability

## Contributing
1. Fork the repository
2. Create a feature branch
3. Submit a pull request
