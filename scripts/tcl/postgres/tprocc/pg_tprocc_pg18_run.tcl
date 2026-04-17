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
diset tpcc pg_driver timed
diset tpcc pg_total_iterations 100000
diset tpcc pg_rampup 1
diset tpcc pg_duration 1
diset tpcc pg_allwarehouse true
diset tpcc pg_timeprofile true
loadscript
vuset vu 1
vucreate
vurun
vudestroy
exit
