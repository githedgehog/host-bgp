FROM quay.io/frrouting/frr:10.5.0

COPY hostbgp-config.sh /usr/local/bin/hostbgp-config.sh
RUN chmod +x /usr/local/bin/hostbgp-config.sh

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

COPY daemons /etc/frr/daemons
COPY vtysh.conf /etc/frr/vtysh.conf

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD []
