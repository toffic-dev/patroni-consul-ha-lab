# Patroni and Consul Configuration

## 1. Overview

The lab uses Consul as the Distributed Configuration Store (DCS) for Patroni.

All three nodes run Consul, PostgreSQL, and Patroni. Patroni uses the local Consul HTTP API to coordinate cluster membership, leader information, and failover decisions.

## 2. Consul Configuration

| Setting | Value |
|---|---|
| Consul version | 2.1.0 |
| Datacenter | `patroni-dc` |
| Number of servers | 3 |
| HTTP API | `127.0.0.1:8500` |
| Server RPC | `8300` |
| LAN gossip | `8301` |

Verify Consul membership:

```bash
consul members
```

Verify the Raft peers:

```bash
consul operator raft list-peers
```

## 3. Patroni Configuration

Configuration file:

```text
/etc/patroni/config.yml
```

The following are the shared cluster settings:

```yaml
scope: patroni-lab
namespace: /service/

consul:
  host: 127.0.0.1:8500
  register_service: true
```

Each node has a unique name and PostgreSQL connection address.

| Node | Connect Address |
|---|---|
| patroni1 | `192.168.116.129:5432` |
| patroni2 | `192.168.116.132:5432` |
| patroni3 | `192.168.116.133:5432` |

## 4. PostgreSQL Settings

The cluster uses PostgreSQL 18 with streaming replication.

Important settings include:

```yaml
bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:
        wal_level: replica
        hot_standby: "on"
        wal_log_hints: "on"
        max_wal_senders: 5
        max_replication_slots: 5
```

These settings are stored in Patroni's bootstrap configuration. After initialization, the DCS configuration is managed through Patroni.

## 5. Dynamic PostgreSQL Access Rules

The cluster's dynamic configuration includes PostgreSQL authentication rules:

```yaml
postgresql:
  pg_hba:
    - local all postgres peer
    - host all all 127.0.0.1/32 scram-sha-256
    - host all all ::1/128 scram-sha-256
    - host replication replicator 192.168.116.0/24 scram-sha-256
```

These rules allow local PostgreSQL administration and replication connections from the lab network.

The configuration is managed through Patroni's DCS rather than being treated as an independent node-specific setting.

## 6. Configuration Validation

Check Patroni's cluster configuration:

```bash
sudo -u postgres patronictl -c /etc/patroni/config.yml show-config patroni-lab
```

Check the local Patroni service:

```bash
sudo systemctl status patroni --no-pager
```

Check the PostgreSQL data directory:

```bash
sudo -u postgres /usr/lib/postgresql/18/bin/pg_ctl \
  -D /var/lib/postgresql/18/patroni status
```

## 7. Security Notes

- The Patroni configuration file is owned by `postgres`.
- Configuration file permissions are restricted to `600`.
- Database passwords and other credentials are excluded from this repository.
- Real credentials must be supplied privately on each node.
- This lab does not document a configured Consul ACL or TLS deployment.

## 8. Important Paths

| Purpose | Path |
|---|---|
| Patroni configuration | `/etc/patroni/config.yml` |
| PostgreSQL data directory | `/var/lib/postgresql/18/patroni` |
| PostgreSQL configuration | `/var/lib/postgresql/18/patroni/postgresql.conf` |
| PostgreSQL authentication rules | `/var/lib/postgresql/18/patroni/pg_hba.conf` |
| Patroni systemd service | `patroni.service` |