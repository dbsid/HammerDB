dbset db pg
dbset bm TPC-C
diset connection pg_host 127.0.0.1
diset connection pg_port 5432
diset connection pg_sslmode disable
diset tpcc pg_superuser postgres
diset tpcc pg_superuserpass postgres
diset tpcc pg_defaultdbase postgres
diset tpcc pg_user tpcc_pg18
diset tpcc pg_pass tpcc_pg18
diset tpcc pg_dbase tpcc_pg18
diset tpcc pg_storedprocs true
checkschema
exit
