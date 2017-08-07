#!/bin/sh

# Update directory permissions, if owned by root (bind-mounting breaks without this)
# https://github.com/hashicorp/docker-consul/pull/22 , https://github.com/hashicorp/docker-consul/issues/20
if [ "$(stat -c %u /consul/data)" = '0' ]; then
  chown consul:consul /consul/data
fi
if [ "$(stat -c %u /consul/config)" = '0' ]; then
  chown consul:consul /consul/config
fi

LOCAL_DNS="$(hostname).$CS_CLUSTER_ID.containership"
FOLLOWERS_DNS="followers.$CS_CLUSTER_ID.containership"

LOCAL_IP=$(drill $LOCAL_DNS @127.0.0.1 | grep "$LOCAL_DNS.\s*60" | awk '{print $5}')
CONSUL_OPTS="-bind=$LOCAL_IP"

PEER_IPS=$(drill $FOLLOWERS_DNS @127.0.0.1 | grep "$FOLLOWERS_DNS.\s*60" | awk '{print $5}')
PEERS=0
for ip in $PEER_IPS; do
  PEERS=$((PEERS+1))
  if [ $ip != $LOCAL_IP ]
  then
    CONSUL_OPTS="$CONSUL_OPTS -retry-join $ip"
  fi
done

CONSUL_OPTS="$CONSUL_OPTS -bootstrap-expect=$PEERS"

CONSUL_DC=${CONSUL_DC:-$CS_CLUSTER_ID}
CONSUL_OPTS="$CONSUL_OPTS -dc=$CONSUL_DC"

HTTP_PORT="${HTTP_PORT:-8314}"
CONSUL_OPTS="$CONSUL_OPTS -http-port=$HTTP_PORT"

if [ $CONSUL_UI == "true" ]
then
  CONSUL_OPTS="$CONSUL_OPTS -client=$LOCAL_IP -ui"
fi

/usr/local/bin/docker-entrypoint.sh agent -server $CONSUL_OPTS
