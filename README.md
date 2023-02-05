# strongswan-vpn-docker

A docker image for hosting a dockerized Strongswan VPN server

## Running

```bash
docker build strongswan-vpn:latest .
docker run --name vpn -d -e "VPN_DOMAIN_OR_IP=@vpn.yourdomain.com" \
    --net=host --cap-add NET_ADMIN strongswan-vpn:latest
```

The default CIDR range for connecting clients will be *10.13.37.0/24*, this can be changed by specifying `-e "VPN_CLIENT_SUBNET=<cidr>"` in the `docker run` command.

A default VPN user will be created with credentials `test:test`.

The IPSec CA certificate will be printed to stdout, to get it, run `docker logs vpn`.

**In some cases, a Docker service restart is needed in order for the clients to have internet connection when connected to the VPN server.**

### Additional settings

Firewall also needs to be setup on the host in order for the VPN server to work correctly.

Example for `uwf`:

```plaintext
# /etc/ufw/before.rules

# ...

# Swap the 10.13.37.0/24 if you defined you own CIDR range in the docker run command
# Swap the eth0 interface if your default network interface has different name

*nat
-A POSTROUTING -s 10.13.37.0/24 -o eth0 -m policy --pol ipsec --dir out -j ACCEPT
-A POSTROUTING -s 10.13.37.0/24 -o eth0 -j MASQUERADE
COMMIT

*mangle
-A FORWARD --match policy --pol ipsec --dir in -s 10.13.37.0/24 -o eth0 -p tcp -m tcp --tcp-flags SYN,RST SYN -m tcpmss --mss 1361:1536 -j TCPMSS --set-mss 1360
COMMIT

*filter
# ...

-A ufw-before-forward --match policy --pol ipsec --dir in --proto esp -s 10.13.37.0/24 -j ACCEPT
-A ufw-before-forward --match policy --pol ipsec --dir out --proto esp -d 10.13.37.0/24 -j ACCEPT
```

```plaintext
# /etc/ufw/sysctl.conf

# ...
# append to the end of the file
net/ipv4/ip_forward=1
net/ipv4/conf/all/accept_redirects=0
net/ipv4/conf/all/send_redirects=0
net/ipv4/ip_no_pmtu_disc=1
```

Then run:

```bash
ufw reload

# or if ufw was disabled

ufw enable
```
