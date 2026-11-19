# PostgreSQL Replication Testing

## 1. Objective

Verify that PostgreSQL data written on the Patroni leader is replicated to both standby nodes through streaming replication.

## 2. Initial Cluster Topology

At the time of the initial replication test:

| Node | IP Address | Role |
|---|---|---|
| patroni1 | 192.168.116.129 | Leader |
| patroni2 | 192.168.116.132 | Replica |
| patroni3 | 192.168.116.133 | Replica |

## 3. Verify Cluster Status

Run on any node:

```bash
sudo -u postgres patronictl -c /etc/patroni/config.yml list
```

Confirm that one node is the Leader and the other two are Replicas.

## 4. Create a Test Table

Run the following SQL on the leader (`patroni1` during this test):

```sql
CREATE TABLE IF NOT EXISTS ha_test (
    id SERIAL PRIMARY KEY,
    message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO ha_test (message)
VALUES ('Consul-backed Patroni replication test');
```

## 5. Verify Data on Replica Nodes

Connect to PostgreSQL on `patroni2`:

```bash
sudo -u postgres psql -X -d postgres -c "SELECT * FROM ha_test;"
```

Repeat on `patroni3`:

```bash
sudo -u postgres psql -X -d postgres -c "SELECT * FROM ha_test;"
```

Both replicas returned the inserted row, including the same ID, message, and timestamp.

## 6. Verify Streaming Replication

Run on the current leader:

```bash
sudo -u postgres psql -X -d postgres -c "
SELECT application_name, client_addr, state, sync_state
FROM pg_stat_replication
ORDER BY client_addr;
"
```

The query showed both replicas connected to the leader with `streaming` state and asynchronous replication.

## 7. Test Results

<badge color="success">Passed</badge>

| Test | Result |
|---|---|
| Test table created on leader | Passed |
| Test row inserted on leader | Passed |
| Data visible on patroni2 | Passed |
| Data visible on patroni3 | Passed |
| Both replicas streaming | Passed |

## 8. Conclusion

The replication test confirmed that data written on the active PostgreSQL leader was successfully replicated to both standby nodes.

This verifies PostgreSQL streaming replication and the functioning Patroni-managed cluster.