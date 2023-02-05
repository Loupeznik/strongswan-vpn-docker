#!/usr/bin/env bash

INITFILE=".ipsec-initialized"

if [ ! -f "$INITFILE" ]; then

  mkdir -p /opt/pki/{cacerts,certs,private}

  pki --gen --type rsa --size 4096 --outform pem > /opt/pki/private/ca-key.pem
  pki --self --ca --lifetime 3650 --in /opt/pki/private/ca-key.pem \
    --type rsa --dn "CN=$VPN_DOMAIN_OR_IP VPN ROOT CERT" --outform pem \
    > /opt/pki/cacerts/ca-cert.pem

  pki --gen --type rsa --size 4096 --outform pem > /opt/pki/private/server-key.pem
  pki --pub --in /opt/pki/private/server-key.pem --type rsa | pki --issue --lifetime 1825 \
    --cacert /opt/pki/cacerts/ca-cert.pem \
    --cakey /opt/pki/private/ca-key.pem \
    --dn "CN=$VPN_DOMAIN_OR_IP" --san $VPN_DOMAIN_OR_IP \
    --flag serverAuth --flag ikeIntermediate --outform pem > /opt/pki/certs/server-cert.pem

  cp -r /opt/pki/* /etc/ipsec.d/

  rm /etc/ipsec.conf

  tee -a /etc/ipsec.conf > /dev/null <<EOT
  config setup
      charondebug="ike 1, knl 1, cfg 0"
      uniqueids=no

  conn ikev2-vpn
      auto=add
      compress=no
      type=tunnel
      keyexchange=ikev2
      fragmentation=yes
      forceencaps=yes
      dpdaction=clear
      dpddelay=300s
      rekey=no
      left=%any
      leftid=$VPN_DOMAIN_OR_IP
      leftcert=server-cert.pem
      leftsendcert=always
      leftsubnet=0.0.0.0/0
      right=%any
      rightid=%any
      rightauth=eap-mschapv2
      rightsourceip=$VPN_CLIENT_SUBNET
      rightdns=8.8.8.8,8.8.4.4
      rightsendcert=never
      eap_identity=%identity
      ike=chacha20poly1305-sha512-curve25519-prfsha512,aes256gcm16-sha384-prfsha384-ecp384,aes256-sha1-modp1024,aes128-sha1-modp1024,3des-sha1-modp1024!
      esp=chacha20poly1305-sha512,aes256gcm16-ecp384,aes256-sha256,aes256-sha1,3des-sha1!
  EOT

  tee -a /etc/ipsec.secrets > /dev/null <<EOT
  : RSA "server-key.pem"
  test : EAP "test"
  EOT

  echo "Printing root CA certificate"
  cat /etc/ipsec.d/cacerts/ca-cert.pem

fi

echo "Starting IPSec"

ipsec start --nofork
