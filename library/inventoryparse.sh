#!/bin/bash

# Usage: JOB_NAME=prometheus ./inventoryparse.sh eminxd embixd
#- replace eminxd and embixd with groups

INVENTORY_PATH=${INVENTORY_PATH:-"../inventory"}
CONFIG_PATH=${CONFIG_PATH:-"../roles/prometheus/files/prometheus-config.yml"}
TARGET=${GROUP:-"application_servers"}
JOB_NAME=${JOB_NAME:-"prometheus"}
EXPORTER_PORT=${EXPORTER_PORT:-"9100"}

if [ ! -z JOB_NAME ]; then

# Ensure file containing prometheus inventory is empty and create the prometheus config
echo > $CONFIG_PATH
echo \
"scrape_configs:
- job_name: $JOB_NAME
  scrape_interval: 10s
  scrape_timeout:  10s
  static_configs:
  - targets:
" > $CONFIG_PATH

# Create ARRAY of inventory IPS
GROUP_IPS=()
for GROUP in "$@"
do
  GROUP_IPS+=($(ansible -m debug -a "msg={{ansible_ssh_host|default('MISSING')}}" $TARGET \
  -i $INVENTORY_PATH/$GROUP \
  --one-line  2>/dev/null | grep -Eo "([0-9]{1,3}[\.]){3}[0-9]{1,3}"))
done

# Echo the Arrays into the promtheus config
ARRAY_LENGTH=${#GROUP_IPS[@]}
for (( i = 0; i < $ARRAY_LENGTH; i++ )); do
  echo  -e "    - \"${GROUP_IPS[$i]}:${EXPORTER_PORT}\"\n" >> $CONFIG_PATH
done


fi
