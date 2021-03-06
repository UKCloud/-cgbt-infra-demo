global
        log /dev/log    local0
        log /dev/log    local1 notice
        stats socket /var/run/haproxy.sock mode 600 level admin
        stats timeout 2m
        chroot /var/lib/haproxy
        user haproxy
        group haproxy
        daemon
        tune.ssl.default-dh-param 2048

defaults
        log     global
        mode    http
        option  httplog
        option  dontlognull
        option  forwardfor
        option  http-server-close
        # contimeout 5000
        # clitimeout 50000
        # srvtimeout 50000
        timeout connect 5000
        timeout client 50000
        timeout server 50000

frontend http
        bind ${IPADDRESS}:80
 
        http-request add-header X-Proto https if { ssl_fc }
        reqadd X-Forwarded-Proto:\ https  if { ssl_fc }
        reqadd X-Forwarded-Proto:\ http  if !{ ssl_fc }

        default_backend webservers

backend webservers
${BACKEND_LIST}