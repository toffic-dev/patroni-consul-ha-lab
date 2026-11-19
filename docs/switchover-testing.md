# Patroni Controlled Switchover Testing

## 1. Objective

Verify that Patroni can safely transfer PostgreSQL leadership from one healthy node to another while keeping the cluster operational.

## 2. Initial Cluster State

Before the test:

| Node | IP Address | Role |
|---|---|---|
| patroni1 | 192.168.116.129 | Leader |
| patroni2 | 192.168.116.132 | Replica |
| patroni3 | 192.168.116.133 | Replica |

All three nodes were healthy before the switchover.

## 3. Execute the Switchover

The switchover was initiated from `patroni1` using:

```bash
sudo -u postgres patronictl -c /etc/patroni/config.yml switchover patroni-lab
```

The command prompted for:

- Current leader: `patroni1`
- Candidate: `patroni2`
- Schedule: immediate

The operation was confirmed.

## 4. Verify the New Leader

Run:

```bash
sudo -u postgres patronictl -c /etc/patroni/config.yml list
```

The cluster elected `patroni2` as the new Leader.

`patroni1` rejoined as a Replica, and `patroni3` remained a Replica.

## 5. Verify Replication After Switchover

On the new leader (`patroni2`), run:

```bash
sudo -u postgres psql -X -d postgres -c "
SELECT application_name, client_addr, state, sync_state
FROM pg_stat_replication
ORDER BY client_addr;
"
```

Both `patroni1` and `patroni3` appeared as streaming replicas.

The reported replication lag was zero for both replicas in the final cluster status.

## 6. Verify Existing Data

On `patroni2`, run:

```bash
sudo -u postgres psql -X -d postgres -c "SELECT * FROM ha_test;"
```

The original replication test row was still present after the leadership change.

## 7. Final Cluster State

| Node | IP Address | Final Role | State |
|---|---|---|---|
| patroni1 | 192.168.116.129 | Replica | Streaming |
| patroni2 | 192.168.116.132 | Leader | Running |
| patroni3 | 192.168.116.133 | Replica | Streaming |

<badge color="success">Passed</badge>

## 8. Test Results

| Test | Result |
|---|---|
| Controlled switchover initiated | Passed |
| patroni2 elected as new leader | Passed |
| patroni1 rejoined as replica | Passed |
| patroni3 remained a replica | Passed |
| Both replicas streaming from new leader | Passed |
| Existing test data remained available | Passed |
| Timeline advanced from 1 to 2 | Passed |

## 9. Conclusion

The controlled switchover completed successfully.

Patroni transferred leadership from `patroni1` to `patroni2`, and both standby nodes rejoined or remained connected as streaming replicas.

The test demonstrates successful planned leadership transfer. It does not, by itself, prove automatic failover after an unexpected node failure.