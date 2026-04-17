dbset db pg
dbset bm TPC-C
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
exit
