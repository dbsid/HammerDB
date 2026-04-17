dbset db pg
dbset bm TPC-H
diset connection pg_host 127.0.0.1
diset connection pg_port 5543
diset connection pg_sslmode disable
diset tpch pg_scale_fact 1
diset tpch pg_num_tpch_threads 1
diset tpch pg_tpch_superuser admin
diset tpch pg_tpch_superuserpass admin
diset tpch pg_tpch_defaultdbase postgres
diset tpch pg_tpch_user tpch_db9
diset tpch pg_tpch_pass tpch_db9
diset tpch pg_tpch_dbase tpch_db9
checkschema
exit
