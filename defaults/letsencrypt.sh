#!/bin/bash
echo "cronjob running at "$(date)
if [ -f "/config/keys/fullchain.pem" ]; then
  EXP=$(date -d "`openssl x509 -in /config/keys/fullchain.pem -text -noout|grep "Not After"|cut -c 25-`" +%s)
  DATENOW=$(date -d "now" +%s)
  DAYS_EXP=$(( ( $EXP - $DATENOW ) / 86400 ))
  if [[ $DAYS_EXP -gt 30 ]]; then
    echo "Existing certificate is still valid for another $DAYS_EXP day(s); skipping renewal."
    exit 0
  else
    echo "Renewing certificate that is older than 60 days"
  fi
else
  echo "Generating server certificate for the first time"
fi
  
for job in $(echo $SUBDOMAINS | tr "," " "); do
  export SUBDOMAINS2="$SUBDOMAINS2 -d "$job"."$URL""
done
cd /config/letsencrypt
./letsencrypt-auto certonly --renew-by-default --webroot -w /config/www/ --email $EMAIL --agree-tos -d $URL $SUBDOMAINS2
echo "Reloading web server"
service nginx reload
