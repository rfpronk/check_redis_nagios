# check_redis_nagios

A Nagios/Icinga check for Redis using Ruby. Supports TLS.

## Usage
```
Usage: ./check_redis.rb <options>
    -H, --host [HOSTNAME]            Hostname (Default: "localhost")
    -p, --port [PORT]                Port (Default: "6379")
    -P, --password [PASSWORD]        Password (Default: blank)
    -S, --sentinel [MASTER]          Connect to Sentinel and ask for MASTER
    -T, --tls                        Connect to Redis using SSL/TLS
    -C, --ca [CA_FILE]               Verify servers against given CA when using -T (use system default trusted certs when not specified)
    -r, --replicas [COUNT]           Minimum connected replicas for a master (Default: 1)
    -h, --help                       Show this message
```
