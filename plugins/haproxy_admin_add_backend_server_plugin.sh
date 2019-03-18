#!/bin/bash

# HAProxy Admin Socket #

export HAPROXY_ADMIN_SOCK=/mnt/export/netcrave_docker/var/run/haproxy/haproxy_admin.sock

# TODO 
#    | tr ':' ' ' \
#    | cat -n \
#    | awk '{print "set server socks5_be/socks5-proxy-"$1 " addr "$2" port "$3}' \
#    | sudo nc -U /mnt/export/netcrave_docker/var/run/haproxy/haproxy_admin.sock


function refresh_haproxy_backend() {
    echo "noop"
}
