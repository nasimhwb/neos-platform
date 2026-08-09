import subprocess, json

def run_cmd(cmd):
    try:
        res = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=10)
        return res.stdout.strip()
    except Exception as e:
        return str(e)

audit = {}

# 1. SSH Config Audit
audit['ssh'] = {
    'sshd_config_root_login': run_cmd("grep -iE '^PermitRootLogin' /etc/ssh/sshd_config || echo 'Not explicitly set'"),
    'sshd_config_password_auth': run_cmd("grep -iE '^PasswordAuthentication' /etc/ssh/sshd_config || echo 'Not explicitly set'"),
    'sshd_port': run_cmd("grep -iE '^Port' /etc/ssh/sshd_config || echo '22 (Default)'")
}

# 2. Firewall & Fail2Ban
audit['firewall'] = {
    'ufw_status': run_cmd("ufw status || iptables -L -n -v | head -n 15"),
    'fail2ban_status': run_cmd("fail2ban-client status || echo 'Fail2Ban service not found'")
}

# 3. Docker Ports & Sockets
audit['docker'] = {
    'listening_ports': run_cmd("netstat -tulpn | grep -iE 'docker|listen|sshd' || ss -tulpn"),
    'socket_perms': run_cmd("ls -la /var/run/docker.sock")
}

# 4. .env File Permissions & Git Check
audit['secrets_env'] = {
    'env_perms': run_cmd("ls -la /srv/neos/.env /srv/neos/neos-platform/.env /srv/neos/shared/.env 2>/dev/null"),
    'git_history_env_check': run_cmd("cd /srv/neos/neos-platform && git log --all --grep='env' --oneline -n 5 2>/dev/null || echo 'No git repo or clean'")
}

# 5. Database RLS & Permissions
audit['db_security'] = {
    'rls_disabled_tables': run_cmd("docker exec neos_postgres psql -U postgres -d postgres -t -A -c \"SELECT count(*) FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = false;\""),
    'db_superuser_count': run_cmd("docker exec neos_postgres psql -U postgres -d postgres -t -A -c \"SELECT count(*) FROM pg_roles WHERE rolsuper = true;\"")
}

# 6. TLS & Certs
audit['tls'] = {
    'cert_check': run_cmd("ls -la /etc/letsencrypt/live/ 2>/dev/null || echo 'Certs managed via proxy/docker'")
}

# 7. Backup Cron
audit['backups'] = {
    'crontab': run_cmd("crontab -l || echo 'No crontab for root'"),
    'backup_dir': run_cmd("ls -la /srv/neos/backups /var/backups 2>/dev/null || echo 'No backup directory found'")
}

print(json.dumps(audit, indent=2))
