# Security Policy

## 🔒 Security Overview

This document outlines security best practices, vulnerability reporting procedures, and security considerations for running Hyperliquid nodes.

## 🚨 Reporting Security Vulnerabilities

### Reporting Process

If you discover a security vulnerability, please follow these steps:

1. **DO NOT** open a public GitHub issue
2. Email security concerns to: [security@cryptomanufaktur.io]
3. Include detailed information about the vulnerability
4. Allow reasonable time for response before public disclosure

### What to Include

Please provide:
- Description of the vulnerability
- Steps to reproduce the issue
- Potential impact assessment
- Suggested mitigation (if any)
- Your contact information

## 🛡️ Security Best Practices

### Validator Security

**Private Key Management:**
```bash
# Generate secure private keys
openssl rand -hex 32

# Use hardware security modules for production
# Consider key management services (AWS KMS, HashiCorp Vault)

# NEVER commit private keys to version control
echo ".env" >> .gitignore
echo "*.key" >> .gitignore
```

**Environment Security:**
```bash
# Set proper file permissions
chmod 600 .env
chmod 700 ~/.ssh/

# Use dedicated user account
sudo useradd -m -s /bin/bash hyperliquid
sudo usermod -aG docker hyperliquid

# Limit sudo access
# Only grant specific permissions needed
```

**Network Isolation:**
```bash
# Use firewall rules
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow only necessary ports
sudo ufw allow 22/tcp          # SSH
sudo ufw allow 4000:4010/tcp   # P2P
# Do NOT expose RPC ports publicly without authentication
```

### Infrastructure Security

**Server Hardening:**
```bash
# Update system regularly
sudo apt update && sudo apt upgrade -y

# Configure SSH security
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Enable automatic security updates
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

**Docker Security:**
```bash
# Run Docker daemon with security options
sudo systemctl edit docker
# Add:
# [Service]
# ExecStart=
# ExecStart=/usr/bin/dockerd --userland-proxy=false --live-restore

# Use non-root containers (already configured)
# Regular image updates
./hld update

# Limit container resources
# Configure in docker-compose override files
```

**Monitoring and Alerting:**
```bash
# Monitor system logs
sudo journalctl -u docker -f

# Set up log aggregation
# Configure alerts for:
# - Failed login attempts
# - Unusual network activity
# - Container failures
# - Disk space issues
```

### Network Security

**RPC Security:**
```bash
# Internal access only
COMPOSE_FILE=hyperliquid.yml:monitoring.yml

# For external access, use Traefik with TLS
COMPOSE_FILE=hyperliquid.yml:monitoring.yml:ext-network.yml
DOMAIN=your-secure-domain.com

# Consider VPN for administrative access
# Use fail2ban for SSH protection
sudo apt install fail2ban
```

**TLS Configuration:**
```yaml
# Example Traefik TLS configuration
labels:
  - "traefik.http.routers.hyperliquid.tls=true"
  - "traefik.http.routers.hyperliquid.tls.certresolver=letsencrypt"
```

## 🔐 Operational Security

### Access Control

**User Management:**
```bash
# Principle of least privilege
# Create dedicated service accounts
# Use sudo for specific commands only
# Regular access reviews

# SSH key management
ssh-keygen -t ed25519 -C "your-email@example.com"
# Use different keys for different environments
```

**Multi-Factor Authentication:**
```bash
# Enable MFA for critical accounts
# Use hardware tokens when possible
# Implement break-glass procedures

# Example: Google Authenticator setup
sudo apt install libpam-google-authenticator
google-authenticator
```

### Data Protection

**Backup Security:**
```bash
# Encrypt backups
gpg --symmetric --cipher-algo AES256 backup.tar.gz

# Secure backup storage
# Test backup restoration procedures
# Implement backup retention policies

# Example backup script
#!/bin/bash
tar -czf backup-$(date +%Y%m%d).tar.gz .env consensus-data/
gpg --symmetric backup-$(date +%Y%m%d).tar.gz
rm backup-$(date +%Y%m%d).tar.gz
```

**Secret Management:**
```bash
# Use external secret management
# Examples: HashiCorp Vault, AWS Secrets Manager
# Rotate secrets regularly
# Audit secret access

# Environment variable security
# Avoid logging sensitive data
export HISTCONTROL=ignoreboth
```

### Incident Response

**Preparation:**
```bash
# Document incident response procedures
# Identify key contacts and escalation paths
# Prepare isolation scripts
# Test disaster recovery procedures

# Example isolation script
#!/bin/bash
# Emergency shutdown
./hld down
docker network disconnect bridge $(docker ps -q)
sudo ufw deny from any
```

**Detection:**
```bash
# Monitor for indicators of compromise
# Set up automated alerts
# Regular security audits
# Log analysis and correlation

# Example monitoring alerts
# - Unusual network connections
# - High resource usage
# - Failed authentication attempts
# - Container restarts
```

## 🛠️ Security Tools and Auditing

### Container Security Scanning

```bash
# Scan images for vulnerabilities
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image hyperliquid:latest

# Regular security updates
./hld update
docker system prune -a
```

### Network Security Testing

```bash
# Port scanning (from external perspective)
nmap -sT -O your-server-ip

# Expected open ports only:
# 22 (SSH), 4000-4010 (P2P)
# All other ports should be filtered/closed
```

### Configuration Auditing

```bash
# Docker security benchmarks
docker run --rm --net host --pid host --userns host --cap-add audit_control \
  -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
  -v /etc:/etc:ro \
  -v /var/lib:/var/lib:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --label docker_bench_security \
  docker/docker-bench-security

# System security audit
sudo lynis audit system
```

## 📋 Security Checklist

### Pre-Deployment Security

- [ ] **Server Hardening**
  - [ ] System updates applied
  - [ ] SSH hardened (key-based auth, no root login)
  - [ ] Firewall configured
  - [ ] User accounts properly configured
  - [ ] Monitoring and logging enabled

- [ ] **Application Security**
  - [ ] Docker security best practices applied
  - [ ] Container images regularly updated
  - [ ] Secrets properly managed
  - [ ] Network access restricted

- [ ] **Operational Security**
  - [ ] Backup procedures tested
  - [ ] Incident response plan documented
  - [ ] Access controls implemented
  - [ ] Security monitoring configured

### Post-Deployment Security

- [ ] **Regular Maintenance**
  - [ ] Security updates applied monthly
  - [ ] Container images updated weekly
  - [ ] Log reviews conducted weekly
  - [ ] Access reviews conducted quarterly

- [ ] **Monitoring and Response**
  - [ ] Security alerts configured
  - [ ] Incident response procedures tested
  - [ ] Backup restoration tested
  - [ ] Security audit conducted annually

## 🔄 Security Update Process

### Regular Updates

```bash
# Weekly security updates
./hld update
./hld up -d --remove-orphans

# Monthly system updates
sudo apt update && sudo apt upgrade -y
sudo reboot
```

### Emergency Security Updates

```bash
# For critical vulnerabilities:
1. Assess impact and urgency
2. Test updates in staging environment
3. Schedule maintenance window
4. Apply updates with rollback plan
5. Verify system functionality
6. Document changes and lessons learned
```

## 📞 Security Resources

### Official Resources
- [Docker Security](https://docs.docker.com/engine/security/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks/)

### Hyperliquid Security
- [Hyperliquid Documentation](https://hyperliquid.gitbook.io/)
- [Node Security Guidelines](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api/node-info)

### Emergency Contacts
- Security Issues: [security@cryptomanufaktur.io]
- Technical Support: [GitHub Issues](https://github.com/CryptoManufaktur-io/hyperliquid-docker/issues)

## 📄 Disclaimer

This security policy provides general guidelines and best practices. Security requirements may vary based on your specific deployment environment, regulatory requirements, and risk tolerance. Always consult with security professionals for production deployments handling significant value or sensitive data.

Regular security assessments and penetration testing are recommended for production environments.