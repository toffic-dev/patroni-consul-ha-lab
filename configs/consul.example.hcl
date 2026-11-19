# Sanitized Consul server configuration example
# Adapt the node-specific values before using.

datacenter = "patroni-dc"
data_dir = "/opt/consul"

server = true
bootstrap_expect = 3

bind_addr = "192.168.116.129"
advertise_addr = "192.168.116.129"
client_addr = "127.0.0.1"

retry_join = [
  "192.168.116.129",
  "192.168.116.132",
  "192.168.116.133"
]

ui_config {
  enabled = true
}

# Example for patroni1 only.
# On patroni2 and patroni3, change bind_addr
# and advertise_addr to the appropriate node IP.
#
# This example does not enable Consul ACLs or TLS.
# Those security features should be configured before
# using a similar setup in production.