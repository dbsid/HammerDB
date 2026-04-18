dbset db pg
dbset bm TPC-C
source [file join [file dirname [info script]] db9_runtime_overrides.tcl]
set db9_host 127.0.0.1
set db9_port 5543
set db9_sslmode disable
set db9_superuser admin
set db9_superuserpass admin
set db9_dbase tpcc_db9
diset connection pg_host 127.0.0.1
diset connection pg_port 5543
diset connection pg_sslmode disable
diset tpcc pg_count_ware 1
diset tpcc pg_num_vu 1
diset tpcc pg_superuser admin
diset tpcc pg_superuserpass admin
diset tpcc pg_defaultdbase postgres
diset tpcc pg_user tpcc_db9
diset tpcc pg_pass tpcc_db9
diset tpcc pg_dbase tpcc_db9
diset tpcc pg_storedprocs false
buildschema
db9_apply_tpcc_function_overrides $db9_host $db9_port $db9_sslmode $db9_superuser $db9_superuserpass $db9_dbase
exit
