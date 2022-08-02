#!/bin/bash

echo "[INFO] Creating DKIM keys"

export DKIM_SELECTOR

ADD_DOMAINS=${ADD_DOMAINS:-}

OPENDKIM_KEY_LENGTH=${OPENDKIM_KEY_LENGTH:-1024}
DKIM_KEY_LENGTH=${DKIM_KEY_LENGTH:-$OPENDKIM_KEY_LENGTH}
DKIM_SELECTOR=${DKIM_SELECTOR:-mail}

# DKIM KEYS
# ---------------------------------------------------------------------------------------------

# Add domains from ENV DOMAIN and ADD_DOMAINS
domains=(${DOMAIN})
domains+=(${ADD_DOMAINS//,/ })  

# Set umask so that we can delete keys from the host (add/remove domains)
old_umask=$(umask)
umask 002

for domain in "${domains[@]}"; do

  mkdir -p /var/mail/vhosts/"$domain"
  mkdir -p /var/mail/dkim/"$domain"

  if [ -f /var/mail/opendkim/"$domain"/mail.private ]; then
    echo "[INFO] Found an old OPENDKIM keys, migrating files to the new location"
    mv /var/mail/opendkim/"$domain"/mail.private /var/mail/dkim/"$domain"/mail.private.key
    mv /var/mail/opendkim/"$domain"/mail.txt /var/mail/dkim/"$domain"/mail.public.key
    rm -rf /var/mail/opendkim/"$domain"
    rmdir --ignore-fail-on-non-empty /var/mail/opendkim
  elif [ -f /var/mail/dkim/"$domain"/private.key ]; then
    echo "[INFO] Found an old DKIM keys, migrating files to the new location"
    mv /var/mail/dkim/"$domain"/private.key /var/mail/dkim/"$domain"/mail.private.key
    mv /var/mail/dkim/"$domain"/public.key /var/mail/dkim/"$domain"/mail.public.key
  fi
  if [ ! -f /var/mail/dkim/"$domain"/"$DKIM_SELECTOR".private.key ]; then
    echo "[INFO] Creating DKIM keys for domain $domain"
    rspamadm dkim_keygen \
      --selector="$DKIM_SELECTOR" \
      --domain="$domain" \
      --bits="$DKIM_KEY_LENGTH" \
      --privkey=/var/mail/dkim/"$domain"/"$DKIM_SELECTOR".private.key \
      > /var/mail/dkim/"$domain"/"$DKIM_SELECTOR".public.key

      chown -R _rspamd:_rspamd /var/mail/dkim/"$domain"/
  else
    echo "[INFO] Found DKIM key pair for domain $domain - skip creation"
  fi

done

umask $old_umask
