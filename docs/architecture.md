# Architecture – PostgreSQL HA with Patroni and Consul

## 1. Overview

This project implements a three-node PostgreSQL high-availability cluster using Patroni and Consul.

The infrastructure runs on three Ubuntu virtual machines hosted on VMware. Each virtual machine runs PostgreSQL, Patroni, and a Consul server.

Consul provides the Distributed Configuration Store (DCS) used by Patroni to coordinate cluster membership, leader ownership, and shared configuration.

Patroni manages PostgreSQL instances and maintains the primary-replica topology.

## 2. Infrastructure Topology

| Node | IP Address | PostgreSQL Port | Patroni REST API | Consul |
|---|---|---:|---:|---|
| patroni1 | 192.168.116.129 | 5432 | 8008 | Server |
| patroni2 | 192.168.116.132 | 5432 | 8008 | Server |
| patroni3 | 192.168.116.133 | 5432 | 8008 | Server |

### Initial topology

- patroni1: Initial PostgreSQL leader.
- patroni2: PostgreSQL replica.
- patroni3: PostgreSQL replica.

### Current topology

After the controlled switchover:

- patroni1: PostgreSQL replica.
- patroni2: PostgreSQL leader.
- patroni3: PostgreSQL replica.

All three nodes are also Consul servers participating in the same Consul cluster.

## 3. Component Responsibilities

### PostgreSQL

PostgreSQL is the database engine running on each node.

Responsibilities:
- Store application data.
- Accept database connections.
- Stream write-ahead log (WAL) records to replicas.
- Support read-only standby operation on replicas.

### Patroni

Patroni manages PostgreSQL high availability.

Responsibilities:
- Bootstrap PostgreSQL instances.
- Manage primary and replica roles.
- Coordinate leader election using Consul.
- Monitor PostgreSQL health.
- Manage streaming replication.
- Perform controlled switchovers and failovers.

### Consul

Consul acts as the Distributed Configuration Store for Patroni.

Responsibilities:
- Store shared Patroni configuration.
- Maintain cluster membership information.
- Coordinate leader ownership through Consul sessions and locks.
- Provide distributed coordination between Patroni nodes.

Consul cluster details:

| Setting | Value |
|---|---|
| Consul Version | 2.1.0 |
| Datacenter | patroni-dc |
| Number of Servers | 3 |
| HTTP API | 8500 |
| RPC | 8300 |
| Serf LAN | 8301 |

## 4. Communication Flow

### Patroni and Consul

Each Patroni instance communicates with its local Consul HTTP API:

`http://127.0.0.1:8500`

Patroni uses Consul to read and update shared cluster state, maintain leader ownership, and coordinate database roles.

### PostgreSQL replication

PostgreSQL uses streaming replication over TCP port 5432.

The primary streams WAL records to both replicas.

The replication connections use the PostgreSQL replication user and SCRAM-SHA-256 authentication.

### Patroni REST API

Each node exposes the Patroni REST API on port 8008.

This API provides node health and cluster information used by Patroni and other management tools.

## 5. High Availability Design

The cluster uses:

- One PostgreSQL primary.
- Two PostgreSQL standby replicas.
- Asynchronous streaming replication.
- Consul-backed distributed coordination.
- Patroni-managed leader election and role transitions.

The primary accepts writes and streams WAL records to the replicas.

If a controlled switchover or eligible failover occurs, Patroni coordinates the transition and updates cluster ownership through Consul.

**Note:** Asynchronous replication can result in data loss if a primary fails before its latest transactions reach a replica. This lab does not configure synchronous replication.

## 6. Controlled Switchover

A controlled switchover was tested from `patroni1` to `patroni2`.

The operation completed successfully.

Observed results:

1. patroni1 was demoted from primary.
2. patroni2 was promoted to primary.
3. patroni3 continued operating as a replica.
4. patroni1 rejoined as a replica.
5. Both replicas resumed streaming from patroni2.
6. PostgreSQL timeline advanced from 1 to 2.

The final topology was:

```text
                 Consul Cluster
             (3 Consul Server Nodes)
                       |
          Patroni DCS / Leader Coordination
                       |
                patroni2
             PostgreSQL Leader
                 /       \
                /         \
         patroni1         patroni3
         Replica          Replica
```

## 7. Network Ports

| Port | Protocol | Purpose |
|---|---|---|
| 5432 | TCP | PostgreSQL connections and replication |
| 8008 | TCP | Patroni REST API |
| 8500 | TCP | Consul HTTP API |
| 8300 | TCP | Consul RPC |
| 8301 | TCP/UDP | Consul LAN gossip |
| 8302 | TCP/UDP | Consul WAN gossip, if WAN federation is used |

Firewall rules should restrict these ports to the required cluster networks and trusted management hosts.

## 8. Architecture Limitations

This is a learning environment rather than a production-ready deployment.

Current design limitations:

- All three Consul servers run on the same physical laptop.
- All three PostgreSQL nodes run on the same physical laptop.
- Asynchronous replication is used.
- No PostgreSQL backup solution is configured.
- No external monitoring or alerting system is included.
- No TLS or Consul ACL configuration is documented as implemented.

Although the lab demonstrates cluster coordination and controlled switchover, it does not provide physical-host failure isolation.

## 9. Summary

The architecture demonstrates how PostgreSQL, Patroni, and Consul work together to provide database high availability.

PostgreSQL handles data storage and replication, Patroni manages database roles and cluster operations, and Consul provides distributed coordination through the DCS.