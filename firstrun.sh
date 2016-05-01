#!/bin/bash

export HOME="/root"
service nginx stop

if [[ $(cat /etc/timezone) != $TZ ]] ; then
  echo "Setting the correct time"
  echo "$TZ" > /etc/timezone
  dpkg-reconfigure -f noninteractive tzdata
fi

mkdir -p /config/nginx/site-confs /config/www /config/log/nginx /config/etc/letsencrypt

if [ ! -f "/config/nginx/nginx.conf" ]; then
  echo "Copying the default nginx.conf"
  cp /defaults/nginx.conf /config/nginx/nginx.conf
else
  echo "Using existing nginx.conf"
fi

if [ ! -f "/config/nginx/site-confs/default" ]; then
  echo "Copying the default site config"
  cp /defaults/default /config/nginx/site-confs/default
else
  echo "Using existing site config"
fi

if [[ $(find /config/www -type f | wc -l) -eq 0 ]]; then
  echo "Copying the default landing page"
  cp /defaults/index.html /config/www/index.html
else
  echo "Using existing landing page"
fi

if [ ! -f "/config/nginx/jail.local" ]; then
  echo "Copying the default jail.local"
  cp /defaults/jail.local /config/nginx/jail.local
else
  echo "Using existing jail.local"
fi

rm -f /etc/nginx/nginx.conf
ln -s /config/nginx/nginx.conf /etc/nginx/nginx.conf

rm -r /etc/letsencrypt
ln -s /config/etc/letsencrypt /etc/letsencrypt
rm /config/keys
ln -s /config/etc/letsencrypt/live/"$URL" /config/keys

if [ ! -z $SUBDOMAINS ]; then
  echo "SUBDOMAINS entered, processing"
  for job in $(echo $SUBDOMAINS | tr "," " "); do
    export SUBDOMAINS2="$SUBDOMAINS2 -d "$job"."$URL""
  done
  echo "Sub-domains processed are:" $SUBDOMAINS2
  echo -e "SUBDOMAINS2=\"$SUBDOMAINS2\" URL=\"$URL\"" > /defaults/domains.conf
else
  echo "No subdomains defined"
  echo -e "URL=\"$URL\"" > /defaults/domains.conf
fi

if [ ! -f "/config/nginx/dhparams.pem" ]; then
  echo "Creating DH parameters for additional security. This may take a very long time. There will be another message once this process is completed"
  openssl dhparam -out /config/nginx/dhparams.pem "$DHLEVEL"
  echo "DH parameters successfully created - " $DHLEVEL "bits"
else
  echo "Using existing DH parameters"
fi

chown -R nobody:users /config
/defaults/letsencrypt.sh
service nginx start
