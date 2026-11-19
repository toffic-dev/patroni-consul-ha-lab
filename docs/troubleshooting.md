# Troubleshooting Guide

This document records some of the issues encountered while building the three-node Patroni and Consul lab and how they were resolved.

## 1. Missing Python Consul Module

**Problem**

Patroni could not import the Python Consul client.

**Cause**

The required Python Consul library was missing.

**Solution**

Install the package on the affected nodes:

```bash
sudo apt update
sudo apt install -y python3-consul
```

Verify:

```bash
python3 -c "import consul; print('Consul module available')"
```

## 2. Replica Failed to Join the Cluster

**Problem**

A replica could not complete its initial connection to the leader.

**Cause**

The PostgreSQL host-based authentication rules did not initially allow the required replication connection.

**Solution**

Update Patroni's dynamic configuration to include the replication rule:

```yaml
postgresql:
  pg_hba:
    - local all postgres peer
    - host all all 127.0.0.1/32 scram-sha-256
    - host all all ::1/128 scram-sha-256
    - host replication replicator 192.168.116.0/24 scram-sha-256
```

Inspect the shared configuration:

```bash
sudo -u postgres patronictl -c /etc/patroni/config.yml show-config patroni-lab
```

## 3. Local PostgreSQL Connections Failed on Replicas

**Problem**

Local connections using the `postgres` system account failed with an error similar to:

```text
FATAL: no pg_hba.conf entry for host "[local]", user "postgres", database "postgres", no encryption
```

**Cause**

The active `pg_hba.conf` files on the replicas did not contain the required local authentication rules, even though the shared Patroni configuration displayed them.

**Solution**

The missing rules were added to the active authentication files on `patroni2` and `patroni3`:

```text
local all postgres peer
host all all 127.0.0.1/32 scram-sha-256
host all all ::1/128 scram-sha-256
```

The files were assigned to the PostgreSQL system user, and PostgreSQL was reloaded.

```bash
sudo chown postgres:postgres /var/lib/postgresql/18/patroni/pg_hba.conf

sudo -u postgres /usr/lib/postgresql/18/bin/pg_ctl \
  -D /var/lib/postgresql/18/patroni reload
```

Local PostgreSQL queries subsequently succeeded on both replicas.

**Note:** Verify that Patroni continues to preserve these rules after a restart or configuration change. Manual edits to Patroni-managed files may be overwritten.

## 4. Duplicate or Incorrect Node Identity

**Problem**

A replica failed to join correctly because its node identity or connection address was incorrect.

**Cause**

The node-specific Patroni name and network address did not correctly identify the VM.

**Solution**

Correct the node's unique `name` and `connect_address` in `/etc/patroni/config.yml`.

Each node must have its own unique identity and address.

## 5. PostgreSQL Service Management

**Problem**

The default PostgreSQL service could conflict with the PostgreSQL instance managed by Patroni.

**Solution**

Use Patroni to manage the database process:

```bash
sudo systemctl status patroni --no-pager
```

Check the Patroni-managed PostgreSQL instance:

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/pg_ctl \
  -D /var/lib/postgresql/18/patroni status
```

Do not independently start the default PostgreSQL cluster.

## 6. Useful Diagnostic Commands

Check cluster membership and roles:

```bash
sudo -u postgres patronictl -c /etc/patroni/config.yml list
```

Check Patroni service:

```bash
sudo systemctl status patroni --no-pager
```

Check Consul membership:

```bash
consul members
```

Check Consul Raft peers:

```bash
consul operator raft list-peers
```

Check recent Patroni logs:

```bash
sudo journalctl -u patroni -n 100 --no-pager
```

Check PostgreSQL replication connections on the leader:

```bash
sudo -u postgres psql -X -d postgres -c "
SELECT application_name, client_addr, state, sync_state
FROM pg_stat_replication;
"
```

## 7. Final Notes

The issues above were encountered and resolved during the lab setup.

The final verified state had:

- One Patroni leader.
- Two streaming replicas.
- All three Consul servers participating in the cluster.
- Successful data replication.
- Successful controlled switchover.

Automatic failover after an unexpected failure and backup recovery were not tested as part of this lab.