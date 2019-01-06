FROM debian:stable-slim
ENV DEBIAN_FRONTEND noninteractive
COPY config/haproxy.cfg /usr/local/etc/haproxy/haproxy.cfg
COPY config/503-error.http /usr/local/etc/haproxy/503-error.http
COPY entrypoint.sh /usr/local/bin/entrypoint.sh


RUN apt-get update  \
    && apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \	    
        apt-transport-https \
        ca-certificates \
        curl \
        debian-archive-keyring \
        gnupg \
        lsb-release \
        netcat \
        rsync \
        telnet \
        vim \
        wget \
        dnsutils \            
    && groupadd -g 1002 haproxy  \
    && useradd -s /sbin/nologin -g haproxy -u 1001 tok  \            
    && sh -c "echo deb http://httpredir.debian.org/debian stretch-backports main | sed 's/\(.*\)-sloppy \(.*\)/&\n\1 \2/' | tee /etc/apt/sources.list.d/backports.list" \
    && apt-get update \
    && apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" -t $(lsb_release -sc)-backports \
        haproxy=1.8.\* \
    && usermod -u 1005 -g haproxy haproxy \
    && mkdir -p /tokaido/ssl \
    && chmod 770 /tokaido/ssl/ \
    && chown haproxy:haproxy /tokaido/ssl/ \
    && chown haproxy:haproxy /usr/local/bin/entrypoint.sh \	
	&& chmod 750 /usr/local/bin/entrypoint.sh \
    && chown -R haproxy:haproxy /usr/local/etc/haproxy \
    && find /usr/local/etc/haproxy -type f -print0 | xargs -0 chmod 660 \
    && find /usr/local/etc/haproxy -type d -print0 | xargs -0 chmod 770 

USER haproxy
EXPOSE 8080
EXPOSE 8443
CMD ["/usr/local/bin/entrypoint.sh"]

