phpMyAdmin
http://localhost:9080/index.php

ProxSql WebUi:
https://localhost:6080/
statadmin:statadmin

If You get error:

mysql -u admin -padmin -h 127.0.0.1 -P6032
mysql -h proxysql -P 6032 -P6032 -u root -proot_supersecret
mysql -h proxysql -P 6032 -P6032 -u radmin -pradmin

set mysql-set_query_lock_on_hostgroup=0;
load mysql variables to runtime;
save mysql variables to disk;
