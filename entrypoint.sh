#!/usr/bin/env bash
set -euxo pipefail

# Lookup the address of our syslog container, since HAProxy can't use hostnames
echo "Setting syslog address"
syslog_ip=${SYSLOG_IP:-$(dig +short syslog)}
sed -i "s/{{SYSLOG_IP}}/${syslog_ip}/g" /usr/local/etc/haproxy/haproxy.cfg

echo "Setting Varnish hostname"
varnish_hostname=${VARNISH_HOSTNAME:-varnish}
sed -i "s/{{VARNISH_HOSTNAME}}/${varnish_hostname}/g" /usr/local/etc/haproxy/haproxy.cfg

# use custom ssl certificates if they're supplied
if [ -f "/tokaido/config/tls/tls.key" ]; then
    echo "Using existing TLS certificate"    
    cat /tokaido/config/tls/tls.key /tokaido/config/tls/tls.crt > /tokaido/ssl/default.pem
    chmod 660 /tokaido/ssl/*
else
    echo "Creating TLS Certificate"
    tls_fqdn=${TLS_FQDN:-"*.local.tokaido.io"}
    openssl req -subj "/CN=${tls_fqdn}/O=Tokaido Hosting Platform./C=AU" -x509 -nodes -days 365 -newkey rsa:2048 -keyout /tokaido/ssl/default-ssl.key -out /tokaido/ssl/default-ssl.crt
    cat /tokaido/ssl/default-ssl.key /tokaido/ssl/default-ssl.crt > /tokaido/ssl/default.pem
    chmod 660 /tokaido/ssl/*
fi

echo "Starting HAProxy"
/usr/sbin/haproxy -f /usr/local/etc/haproxy/haproxy.cfg
