#!/bin/bash

##########################################################################
# redis install
##########################################################################

sudo add-apt-repository ppa:redislabs/redis
sudo apt-get update
sudo apt-get install redis

##########################################################################
# redis cluster val
##########################################################################

REDIS_IP_LIST=(192.168.0.1 192.168.0.2 192.168.0.3 192.168.0.4)
SERVER_COUNT=${#REDIS_IP_LIST[@]}
REPLICA_COUNT=1
readolny MASTER_PORT=7000

##########################################################################
# redis instance config
##########################################################################

mkrdir /cluster
cd /cluster
mkdir $MASTER_PORT
# Download the redis.conf after setting the directory
# cp downloaded path /cluster/$MASTER_PORT/redis.conf

for ((replica_index=1; replica_index<=REPLICA_COUNT; replica_index++))
do
    SLAVE_PORT=$((MASTER_PORT+replica_index))    
    mkdir $SLAVE_PORT
    # Download the redis.conf after setting the directory
    # cp downloaded path /cluster/$MASTER_PORT/redis.conf
done


##########################################################################
# run redis instance
##########################################################################

sudo redis-server /cluster/$MASTER_PORT/redis.conf &
redis-cli -p $MASTER_PORT FLUSHALL

for ((replica_index=1; replica_index<=REPLICA_COUNT; replica_index++))
do
    SLAVE_PORT=$((MASTER_PORT+replica_index))        
    sudo redis-server /cluster/$SLAVE_PORT/redis.conf &    
    redis-cli -p $SLAVE_PORT FLUSHALL
done


##########################################################################
# redis cluster setting
##########################################################################

redis-cli -p $MASTER_PORT --cluster create "${REDIS_IP_LIST[0]}":"$MASTER_PORT" "${REDIS_IP_LIST[1]}":"$MASTER_PORT" "${REDIS_IP_LIST[2]}":"$MASTER_PORT" "${REDIS_IP_LIST[3]}":"$MASTER_PORT"
for ip_index in ${!REDIS_IP_LIST[*]}
do
    MASTER_IP=${REDIS_IP_LIST[ip_index]}
    for ((replica_index=1; replica_index<=REPLICA_COUNT; replica_index++))
    do
      SLAVE_IP=${REDIS_IP_LIST[(ip_index+replica_index) % $SERVER_COUNT]}
      SLAVE_PORT=$((MASTER_PORT+replica_index))
      echo "MASTER_IP:$MASTER_IP, MASTER_PORT:$MASTER_PORT, SLAVE_IP:$SLAVE_IP, SLAVE_PORT:$SLAVE_PORT"
      redis-cli -p $MASTER_PORT --cluster add-node "$SLAVE_IP":"$SLAVE_PORT" "$MASTER_IP":"$MASTER_PORT" --cluster-slave --cluster-master-id \
          $(redis-cli -p $MASTER_PORT cluster nodes | grep "$MASTER_IP":"$MASTER_PORT" | grep master | awk '{print $1}')
    done
done