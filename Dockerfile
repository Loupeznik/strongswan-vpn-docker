FROM ubuntu:rolling

WORKDIR /opt/vpn

RUN apt update && apt upgrade -y
RUN apt install -y strongswan strongswan-pki libcharon-extra-plugins libcharon-extauth-plugins libstrongswan-extra-plugins libtss2-tcti-tabrmd0

VOLUME /etc

ENV VPN_DOMAIN_OR_IP=127.0.0.1
ENV VPN_CLIENT_SUBNET=10.13.37.0/24

EXPOSE 500/udp
EXPOSE 4500/udp

COPY ./docker-entrypoint.sh .

ENTRYPOINT ["bash", "docker-entrypoint.sh"]
