# Installation Guide

This document describes how the three-node PostgreSQL high-availability lab was installed and configured using Consul and Patroni.

## 1. Prepare the Virtual Machines

Create three Ubuntu 26.04.1 LTS virtual machines.

Assign the following hostnames and IP addresses:

| Hostname | IP Address |
|---|---|
| patroni1 | 192.168.116.129 |
| patroni2 | 192.168.116.132 |
| patroni3 | 192.168.116.133 |

Verify network connectivity between the nodes and confirm SSH access.

## 2. Install Consul

Install Consul 2.1.0 on all three nodes.

Configure each node as a Consul server and join the three-node cluster.

The lab uses:

- Datacenter: `patroni-dc`
- HTTP API: `127.0.0.1:8500`
- Server RPC: `8300`
- LAN gossip: `8301`

Verify cluster membership:

```bash
consul members
```

Check the Consul leader:

```bash
consul operator raft list-peers
```

Confirm all three servers are healthy and that a leader has been elected before proceeding.

## 3. Install PostgreSQL

Install PostgreSQL 18 on all three nodes.

Verify the installation:

```bash
postgres --version
```

The PostgreSQL data directory used by Patroni is:

```text
/var/lib/postgresql/18/patroni
```

Patroni manages the PostgreSQL process. Do not independently start the database using the default PostgreSQL systemd service.

## 4. Install Patroni and Consul Python Support

Install Patroni 4.1.0 and the Python Consul client on all three nodes.

Verify the versions and Python module:

```bash
patroni --version
python3 -c "import consul; print('Consul Python client available')"
```

## 5. Configure Patroni

Create the Patroni configuration directory:

```bash
sudo mkdir -p /etc/patroni
```

Create the configuration file:

```bash
sudo nano /etc/patroni/config.yml
```

Each node requires its own configuration, including its unique node name and network address.

Configure Patroni to use the local Consul HTTP API:

```yaml
consul:
  host: 127.0.0.1:8500
```

Use the same cluster scope and namespace on all nodes:

```yaml
scope: patroni-lab
namespace: /service/
```

The PostgreSQL configuration must support streaming replication, including:

- `wal_level: replica`
- `hot_standby: "on"`
- `wal_log_hints: "on"`
- Appropriate WAL sender and replication slot limits.

Keep PostgreSQL credentials out of configuration examples committed to GitHub. Use private configuration files and appropriate file permissions.

Set ownership and permissions:

```bash
sudo chown postgres:postgres /etc/patroni/config.yml
sudo chmod 600 /etc/patroni/config.yml
```

## 6. Start Patroni

Start Patroni on the initial bootstrap node first:

```bash
sudo systemctl enable --now patroni
```

Check its status:

```bash
sudo systemctl status patroni --no-pager
```

After the initial PostgreSQL cluster has been initialized, start Patroni on the remaining two nodes.

```bash
sudo systemctl enable --now patroni
```

Run the command on each remaining node.

## 7. Verify the Cluster

Run:

```bash
sudo -u postgres patronictl -c /etc/patroni/config.yml list
```

Expected cluster structure:

- One Leader.
- Two Replicas.
- Both replicas in streaming state.

Check Consul membership:

```bash
consul members
```

Check the Consul DCS keys through the local API:

```bash
curl -s http://127.0.0.1:8500/v1/kv/service/patroni-lab/?recurse
```

The presence of Patroni cluster keys confirms that Patroni is storing cluster state in Consul.

## 8. Installation Result

The installation produced a three-node PostgreSQL cluster managed by Patroni, with Consul providing distributed coordination and leader information.

Replication and controlled switchover were tested separately. See:

- `replication-testing.md`
- `switchover-testing.md`