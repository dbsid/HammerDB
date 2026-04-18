package require Pgtcl

proc db9_tpcc_connect {host port sslmode user password dbname} {
    set lda [pg_connect -conninfo [list host = $host port = $port sslmode = $sslmode user = $user password = $password dbname = $dbname]]
    pg_notice_handler $lda puts
    set result [pg_exec $lda "set CLIENT_MIN_MESSAGES TO 'ERROR'"]
    pg_result $result -clear
    return $lda
}

proc db9_exec_or_die {lda sql} {
    set result [pg_exec $lda $sql]
    if {[pg_result $result -status] ni {"PGRES_TUPLES_OK" "PGRES_COMMAND_OK"}} {
        set err [pg_result $result -error]
        pg_result $result -clear
        error $err
    }
    pg_result $result -clear
}

proc db9_apply_tpcc_function_overrides {host port sslmode user password dbname} {
    set lda [db9_tpcc_connect $host $port $sslmode $user $password $dbname]

    set sql(1) {DROP FUNCTION IF EXISTS public.neword(integer, integer, integer, integer, integer, integer)}
    set sql(2) {CREATE FUNCTION public.neword(integer, integer, integer, integer, integer, integer) RETURNS numeric AS '
DECLARE
no_w_id ALIAS FOR $1;
no_max_w_id ALIAS FOR $2;
no_d_id ALIAS FOR $3;
no_c_id ALIAS FOR $4;
no_o_ol_cnt ALIAS FOR $5;
no_d_next_o_id ALIAS FOR $6;
no_c_discount NUMERIC;
no_c_last VARCHAR;
no_c_credit VARCHAR;
no_d_tax NUMERIC;
no_w_tax NUMERIC;
no_o_all_local SMALLINT;
rbk SMALLINT;
no_ol_supply_w_id INTEGER;
no_ol_i_id INTEGER;
no_ol_quantity SMALLINT;
no_i_price NUMERIC(5,2);
no_s_quantity SMALLINT;
no_ol_amount NUMERIC(6,2);
no_s_dist_01 CHAR(24);
no_s_dist_02 CHAR(24);
no_s_dist_03 CHAR(24);
no_s_dist_04 CHAR(24);
no_s_dist_05 CHAR(24);
no_s_dist_06 CHAR(24);
no_s_dist_07 CHAR(24);
no_s_dist_08 CHAR(24);
no_s_dist_09 CHAR(24);
no_s_dist_10 CHAR(24);
no_ol_dist_info CHAR(24);
total_amount NUMERIC := 0;
BEGIN
no_o_all_local := 1;
SELECT c_discount, c_last, c_credit, w_tax
INTO no_c_discount, no_c_last, no_c_credit, no_w_tax
FROM customer, warehouse
WHERE warehouse.w_id = no_w_id AND customer.c_w_id = no_w_id AND customer.c_d_id = no_d_id AND customer.c_id = no_c_id;

UPDATE district
SET d_next_o_id = d_next_o_id + 1
WHERE d_id = no_d_id AND d_w_id = no_w_id
RETURNING d_next_o_id - 1, d_tax INTO no_d_next_o_id, no_d_tax;

INSERT INTO orders (o_id, o_d_id, o_w_id, o_c_id, o_entry_d, o_ol_cnt, o_all_local)
VALUES (no_d_next_o_id, no_d_id, no_w_id, no_c_id, current_timestamp, no_o_ol_cnt, no_o_all_local);

INSERT INTO new_order (no_o_id, no_d_id, no_w_id)
VALUES (no_d_next_o_id, no_d_id, no_w_id);

rbk := round(DBMS_RANDOM(1,100));
FOR loop_counter IN 1 .. no_o_ol_cnt
LOOP
IF ((loop_counter = no_o_ol_cnt) AND (rbk = 1))
THEN
no_ol_i_id := 100001;
ELSE
no_ol_i_id := round(DBMS_RANDOM(1,100000));
END IF;

IF ( round(DBMS_RANDOM(1,100)) > 1 )
THEN
no_ol_supply_w_id := no_w_id;
ELSE
no_o_all_local := 0;
no_ol_supply_w_id := 1 + MOD(CAST (no_w_id + round(DBMS_RANDOM(0,no_max_w_id-1)) AS INT), no_max_w_id);
END IF;

no_ol_quantity := round(DBMS_RANDOM(1,10));

SELECT i_price INTO no_i_price
FROM item
WHERE i_id = no_ol_i_id;

SELECT s_quantity, s_dist_01, s_dist_02, s_dist_03, s_dist_04, s_dist_05, s_dist_06, s_dist_07, s_dist_08, s_dist_09, s_dist_10
INTO no_s_quantity, no_s_dist_01, no_s_dist_02, no_s_dist_03, no_s_dist_04, no_s_dist_05, no_s_dist_06, no_s_dist_07, no_s_dist_08, no_s_dist_09, no_s_dist_10
FROM stock
WHERE s_i_id = no_ol_i_id AND s_w_id = no_ol_supply_w_id;

IF ( no_s_quantity > no_ol_quantity )
THEN
no_s_quantity := ( no_s_quantity - no_ol_quantity );
ELSE
no_s_quantity := ( no_s_quantity - no_ol_quantity + 91 );
END IF;

UPDATE stock
SET s_quantity = no_s_quantity
WHERE s_i_id = no_ol_i_id
AND s_w_id = no_ol_supply_w_id;

no_ol_amount := ( no_ol_quantity * no_i_price * ( 1 + no_w_tax + no_d_tax ) * ( 1 - no_c_discount ) );
total_amount := total_amount + no_ol_amount;

IF no_d_id = 1
THEN
no_ol_dist_info := no_s_dist_01;
ELSIF no_d_id = 2
THEN
no_ol_dist_info := no_s_dist_02;
ELSIF no_d_id = 3
THEN
no_ol_dist_info := no_s_dist_03;
ELSIF no_d_id = 4
THEN
no_ol_dist_info := no_s_dist_04;
ELSIF no_d_id = 5
THEN
no_ol_dist_info := no_s_dist_05;
ELSIF no_d_id = 6
THEN
no_ol_dist_info := no_s_dist_06;
ELSIF no_d_id = 7
THEN
no_ol_dist_info := no_s_dist_07;
ELSIF no_d_id = 8
THEN
no_ol_dist_info := no_s_dist_08;
ELSIF no_d_id = 9
THEN
no_ol_dist_info := no_s_dist_09;
ELSE
no_ol_dist_info := no_s_dist_10;
END IF;

INSERT INTO order_line (ol_o_id, ol_d_id, ol_w_id, ol_number, ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_dist_info)
VALUES (no_d_next_o_id, no_d_id, no_w_id, loop_counter, no_ol_i_id, no_ol_supply_w_id, no_ol_quantity, no_ol_amount, no_ol_dist_info);
END LOOP;

RETURN total_amount;

EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END;
' LANGUAGE 'plpgsql'}
    set sql(3) {DROP FUNCTION IF EXISTS public.delivery(integer, integer)}
    set sql(4) {CREATE FUNCTION public.delivery(integer, integer) RETURNS integer AS '
DECLARE
d_w_id ALIAS FOR $1;
d_o_carrier_id ALIAS FOR $2;
d_no_o_id INTEGER;
d_d_id SMALLINT;
d_c_id INTEGER;
d_ol_total NUMERIC;
BEGIN
FOR loop_counter IN 1 .. 10
LOOP
d_d_id := loop_counter;
SELECT no_o_id INTO d_no_o_id FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id ORDER BY no_o_id ASC LIMIT 1;
DELETE FROM new_order WHERE no_w_id = d_w_id AND no_d_id = d_d_id AND no_o_id = d_no_o_id;
SELECT o_c_id INTO d_c_id FROM orders WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND o_w_id = d_w_id;
UPDATE orders SET o_carrier_id = d_o_carrier_id WHERE o_id = d_no_o_id AND o_d_id = d_d_id AND o_w_id = d_w_id;
UPDATE order_line SET ol_delivery_d = current_timestamp WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id AND ol_w_id = d_w_id;
SELECT SUM(ol_amount) INTO d_ol_total FROM order_line WHERE ol_o_id = d_no_o_id AND ol_d_id = d_d_id AND ol_w_id = d_w_id;
UPDATE customer SET c_balance = COALESCE(c_balance,0) + COALESCE(d_ol_total,0) WHERE c_id = d_c_id AND c_d_id = d_d_id AND c_w_id = d_w_id;
END LOOP;
RETURN 1;
EXCEPTION
WHEN serialization_failure OR deadlock_detected OR no_data_found
THEN ROLLBACK;
END;
' LANGUAGE 'plpgsql'}
    set sql(5) {DROP FUNCTION IF EXISTS public.payment(integer, integer, integer, integer, integer, integer, numeric, varchar, varchar, numeric)}
    set sql(6) {CREATE FUNCTION public.payment(integer, integer, integer, integer, integer, integer, numeric, varchar, varchar, numeric) RETURNS INTEGER AS '
DECLARE
p_w_id ALIAS FOR $1;
p_d_id ALIAS FOR $2;
p_c_w_id ALIAS FOR $3;
p_c_d_id ALIAS FOR $4;
p_c_id_in ALIAS FOR $5;
byname ALIAS FOR $6;
p_h_amount ALIAS FOR $7;
p_c_last_in ALIAS FOR $8;
p_c_credit_in ALIAS FOR $9;
p_c_balance_in ALIAS FOR $10;
p_c_balance NUMERIC(12, 2);
p_c_credit CHAR(2);
p_c_last VARCHAR(16);
p_c_id INTEGER;
p_w_street_1 VARCHAR(20);
p_w_street_2 VARCHAR(20);
p_w_city VARCHAR(20);
p_w_state CHAR(2);
p_w_zip CHAR(9);
p_d_street_1 VARCHAR(20);
p_d_street_2 VARCHAR(20);
p_d_city VARCHAR(20);
p_d_state CHAR(2);
p_d_zip CHAR(9);
p_c_first VARCHAR(16);
p_c_middle CHAR(2);
p_c_street_1 VARCHAR(20);
p_c_street_2 VARCHAR(20);
p_c_city VARCHAR(20);
p_c_state CHAR(2);
p_c_zip CHAR(9);
p_c_phone CHAR(16);
p_c_since TIMESTAMP;
p_c_credit_lim NUMERIC(12, 2);
p_c_discount NUMERIC(4, 4);
tstamp TIMESTAMP;
p_d_name VARCHAR(11);
p_w_name VARCHAR(11);
p_c_new_data VARCHAR(500);
name_count SMALLINT;
target_offset INTEGER;
BEGIN
tstamp := current_timestamp;
p_c_id := p_c_id_in;
p_c_balance := p_c_balance_in;
p_c_last := p_c_last_in;
p_c_credit := p_c_credit_in;
UPDATE warehouse SET w_ytd = w_ytd + p_h_amount WHERE w_id = p_w_id RETURNING w_street_1, w_street_2, w_city, w_state, w_zip, w_name INTO p_w_street_1, p_w_street_2, p_w_city, p_w_state, p_w_zip, p_w_name;
UPDATE district SET d_ytd = d_ytd + p_h_amount WHERE d_w_id = p_w_id AND d_id = p_d_id RETURNING d_street_1, d_street_2, d_city, d_state, d_zip, d_name INTO p_d_street_1, p_d_street_2, p_d_city, p_d_state, p_d_zip, p_d_name;
IF ( byname = 1 ) THEN
  SELECT count(c_last) INTO name_count FROM customer WHERE c_last = p_c_last AND c_d_id = p_c_d_id AND c_w_id = p_c_w_id;
  target_offset := GREATEST(CAST(name_count/2 AS INT) - 1, 0);
  SELECT c_first, c_middle, c_id, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_since
  INTO p_c_first, p_c_middle, p_c_id, p_c_street_1, p_c_street_2, p_c_city, p_c_state, p_c_zip, p_c_phone, p_c_credit, p_c_credit_lim, p_c_discount, p_c_balance, p_c_since
  FROM customer WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_last = p_c_last ORDER BY c_first LIMIT 1 OFFSET target_offset;
  IF p_c_id IS NULL THEN
    SELECT c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_since
    INTO p_c_first, p_c_middle, p_c_last, p_c_street_1, p_c_street_2, p_c_city, p_c_state, p_c_zip, p_c_phone, p_c_credit, p_c_credit_lim, p_c_discount, p_c_balance, p_c_since
    FROM customer WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id_in;
    p_c_id := p_c_id_in;
  END IF;
ELSE
  SELECT c_first, c_middle, c_last, c_street_1, c_street_2, c_city, c_state, c_zip, c_phone, c_credit, c_credit_lim, c_discount, c_balance, c_since
  INTO p_c_first, p_c_middle, p_c_last, p_c_street_1, p_c_street_2, p_c_city, p_c_state, p_c_zip, p_c_phone, p_c_credit, p_c_credit_lim, p_c_discount, p_c_balance, p_c_since
  FROM customer WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id;
END IF;
IF p_c_credit = ''BC'' THEN
  UPDATE customer SET c_balance = p_c_balance - p_h_amount, c_data = substr ((p_c_id || '' '' || p_c_d_id || '' '' || p_c_w_id || '' '' || p_d_id || '' '' || p_w_id || '' '' || to_char (p_h_amount, ''9999.99'') || '' | '') || c_data, 1, 500)
  WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id RETURNING c_balance, c_data INTO p_c_balance, p_c_new_data;
ELSE
  UPDATE customer SET c_balance = p_c_balance - p_h_amount WHERE c_w_id = p_c_w_id AND c_d_id = p_c_d_id AND c_id = p_c_id RETURNING c_balance, '' '' INTO p_c_balance, p_c_new_data;
END IF;
INSERT INTO history (h_c_d_id, h_c_w_id, h_c_id, h_d_id,h_w_id, h_date, h_amount, h_data) VALUES (p_c_d_id, p_c_w_id, p_c_id, p_d_id, p_w_id, tstamp, p_h_amount, p_w_name || '' '' || p_d_name);
RETURN p_c_id;
EXCEPTION WHEN serialization_failure OR deadlock_detected OR no_data_found THEN ROLLBACK;
END;
' LANGUAGE 'plpgsql'}
    set sql(7) {DROP FUNCTION IF EXISTS public.ostat(integer, integer, integer, integer, varchar)}
    set sql(8) {CREATE FUNCTION public.ostat(integer, integer, integer, integer, varchar) RETURNS SETOF record AS '
DECLARE
os_w_id ALIAS FOR $1;
os_d_id ALIAS FOR $2;
os_c_id ALIAS FOR $3;
byname ALIAS FOR $4;
os_c_last ALIAS FOR $5;
out_os_c_id INTEGER;
out_os_c_last VARCHAR;
os_c_first VARCHAR;
os_c_middle VARCHAR;
os_c_balance NUMERIC;
os_o_id INTEGER;
os_entdate TIMESTAMP;
os_o_carrier_id INTEGER;
os_ol RECORD;
namecnt INTEGER;
target_offset INTEGER;
BEGIN
IF ( byname = 1 ) THEN
  SELECT count(c_id) INTO namecnt FROM customer WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id;
  IF ( MOD (namecnt, 2) = 1 ) THEN
    namecnt := (namecnt + 1);
  END IF;
  target_offset := CAST((namecnt/2) AS INTEGER);
  SELECT c_balance, c_first, c_middle, c_id
  INTO os_c_balance, os_c_first, os_c_middle, os_c_id
  FROM customer WHERE c_last = os_c_last AND c_d_id = os_d_id AND c_w_id = os_w_id ORDER BY c_first LIMIT 1 OFFSET target_offset;
  IF os_c_id IS NULL THEN
    SELECT c_balance, c_first, c_middle, c_last
    INTO os_c_balance, os_c_first, os_c_middle, os_c_last
    FROM customer WHERE c_id = $3 AND c_d_id = os_d_id AND c_w_id = os_w_id;
    os_c_id := $3;
  END IF;
ELSE
  SELECT c_balance, c_first, c_middle, c_last INTO os_c_balance, os_c_first, os_c_middle, os_c_last FROM customer WHERE c_id = os_c_id AND c_d_id = os_d_id AND c_w_id = os_w_id;
END IF;
SELECT o_id, o_carrier_id, o_entry_d INTO os_o_id, os_o_carrier_id, os_entdate FROM (SELECT o_id, o_carrier_id, o_entry_d FROM orders where o_d_id = os_d_id AND o_w_id = os_w_id and o_c_id=os_c_id ORDER BY o_id DESC) AS subquery LIMIT 1;
FOR os_ol IN SELECT ol_i_id, ol_supply_w_id, ol_quantity, ol_amount, ol_delivery_d, out_os_c_id, out_os_c_last, os_c_first, os_c_middle, os_c_balance, os_o_id, os_entdate, os_o_carrier_id FROM order_line WHERE ol_o_id = os_o_id AND ol_d_id = os_d_id AND ol_w_id = os_w_id LOOP RETURN NEXT os_ol; END LOOP;
EXCEPTION WHEN serialization_failure OR deadlock_detected OR no_data_found THEN ROLLBACK;
END;
' LANGUAGE 'plpgsql'}

    for { set i 1 } { $i <= [array size sql] } { incr i } {
        db9_exec_or_die $lda $sql($i)
    }

    pg_disconnect $lda
}

proc db9_check_tpcc_schema {host port sslmode user password dbname} {
    set lda [db9_tpcc_connect $host $port $sslmode $user $password $dbname]

    set expected_tables {customer district history item warehouse stock new_order orders order_line}
    set expected_functions {neword payment delivery ostat slev}

    set result [pg_exec $lda "select tablename from pg_tables where schemaname = 'public' order by tablename"]
    if {[pg_result $result -status] != "PGRES_TUPLES_OK"} {
        set err [pg_result $result -error]
        pg_result $result -clear
        error $err
    }
    set table_rows [pg_result $result -list]
    pg_result $result -clear
    foreach table $expected_tables {
        if {[lsearch -exact $table_rows $table] < 0} {
            error "missing table $table"
        }
    }

    set result [pg_exec $lda "select proname from pg_proc p join pg_namespace n on n.oid = p.pronamespace where n.nspname = 'public' and proname in ('neword','payment','delivery','ostat','slev') order by proname"]
    if {[pg_result $result -status] != "PGRES_TUPLES_OK"} {
        set err [pg_result $result -error]
        pg_result $result -clear
        error $err
    }
    set function_rows [pg_result $result -list]
    pg_result $result -clear
    foreach fn $expected_functions {
        if {[lsearch -exact $function_rows $fn] < 0} {
            error "missing function $fn"
        }
    }

    set result [pg_exec $lda "select count(*) from warehouse"]
    if {[pg_result $result -status] != "PGRES_TUPLES_OK"} {
        set err [pg_result $result -error]
        pg_result $result -clear
        error $err
    }
    pg_result $result -clear

    pg_disconnect $lda
}
