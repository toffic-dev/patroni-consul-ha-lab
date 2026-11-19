# Prerequisites

## 1. Host Machine

The lab was built on the following host machine:

| Component | Specification |
|---|---|
| Device | HP Envy x360 14-fc0xxx |
| Operating System | Windows 11 Pro |
| RAM | 16 GB |
| CPU | 14 logical processors |
| Virtualization | Hyper-V detected |
| Virtualization Platform | VMware |

## 2. Virtual Machines

Three Ubuntu virtual machines are required.

| Node | Operating System | IP Address |
|---|---|---|
| patroni1 | Ubuntu 26.04.1 LTS | 192.168.116.129 |
| patroni2 | Ubuntu 26.04.1 LTS | 192.168.116.132 |
| patroni3 | Ubuntu 26.04.1 LTS | 192.168.116.133 |

Each VM must have:

- A unique hostname.
- A static or consistently assigned IP address.
- Network connectivity to the other two VMs.
- SSH access.
- Sufficient CPU, RAM, and disk space to run Ubuntu, Consul, PostgreSQL, and Patroni.

## 3. Software Requirements

| Software | Version / Purpose |
|---|---|
| Ubuntu Server | 26.04.1 LTS |
| PostgreSQL | 18 |
| Patroni | 4.1.0 |
| Consul | 2.1.0 |
| Python | Required by Patroni |
| python3-consul | Python Consul client |
| VMware | Virtual machine management |
| OpenSSH | Remote administration |

## 4. Network Requirements

The three VMs must communicate over the lab network.

Required ports:

| Port | Protocol | Purpose |
|---|---|---|
| 5432 | TCP | PostgreSQL connections and replication |
| 8008 | TCP | Patroni REST API |
| 8500 | TCP | Consul HTTP API |
| 8300 | TCP | Consul server RPC |
| 8301 | TCP/UDP | Consul LAN gossip |

Allow communication between the three nodes on the required ports.

## 5. Access Requirements

- Administrative access through `sudo`.
- SSH access between the host and virtual machines.
- Access to Ubuntu package repositories during installation.
- PostgreSQL administrative access through the `postgres` system user.

## 6. Important Notes

- All three VMs run on the same physical laptop.
- Consul is used as Patroni's Distributed Configuration Store (DCS).
- PostgreSQL replication is asynchronous.
- The lab does not implement a backup solution.
- Credentials and passwords must be kept out of the Git repository.
- This is a learning and testing environment, not a production deployment.