#!/bin/bash
#################### Variables ####################
mysql_user="mydb_slave_user"    
mysql_password="mydb_slave_pwd" 
root_password="root_supersecret"

master_container=mysql_master
slave_containers=(mysql_slave mysql_slave2)
all_containers=("$master_container" "${slave_containers[@]}")

retry_duration=5

#################### Functions ####################
# Get docker ip
docker-ip() {
    docker inspect --format '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$@"
}

#################### docker-compose ####################
docker-compose down
rm -rf ./master/data/* ./slave/data/* ./slave2/data/*
docker-compose build
docker-compose up -d

#################### Servers init ####################
for container in "${all_containers[@]}";do
  until docker exec $container sh -c 'export MYSQL_PWD='$root_password'; mysql -u root -e ";"'
  do
      echo "Wait $container connection ${retry_duration}s and retry......"
      sleep $retry_duration
  done
done

#################### Master Setup ####################
priv_stmt='GRANT REPLICATION SLAVE ON *.* TO "'$mysql_user'"@"%" IDENTIFIED BY "'$mysql_password'"; FLUSH PRIVILEGES;'

docker exec $master_container sh -c "export MYSQL_PWD='$root_password'; mysql -u root -e '$priv_stmt'"

# get master status
MS_STATUS=`docker exec $master_container sh -c 'export MYSQL_PWD='$root_password'; mysql -u root -e "SHOW MASTER STATUS"'`

# binlog File example: mysql-bin.000004
CURRENT_LOG=`echo $MS_STATUS | awk '{print $6}'`
# binlog Position example: 1429
CURRENT_POS=`echo $MS_STATUS | awk '{print $7}'`

#################### Slaves Setup ####################
start_slave_stmt="CHANGE MASTER TO
        MASTER_HOST='$(docker-ip $master_container)',
        MASTER_USER='$mysql_user',
        MASTER_PASSWORD='$mysql_password',
        MASTER_LOG_FILE='$CURRENT_LOG',
        MASTER_LOG_POS=$CURRENT_POS;"
start_slave_cmd='export MYSQL_PWD='$root_password'; mysql -u root -e "'
start_slave_cmd+="$start_slave_stmt"
start_slave_cmd+='START SLAVE;"'

for slave in "${slave_containers[@]}";do
  docker exec $slave sh -c "$start_slave_cmd"
  docker exec $slave sh -c "export MYSQL_PWD='$root_password'; mysql -u root -e 'SHOW SLAVE STATUS \G'"
done

echo -e "\033[42;34m finish success !!! \033[0m"
