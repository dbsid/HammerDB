# db9 Compatibility Notes

This fork carries a minimal PostgreSQL compatibility layer for running
HammerDB `TPROC-C` and `TPROC-H` against both:

- db9
- PostgreSQL 18.3

## Design

The fork does not add a separate db9 driver.

Instead, the PostgreSQL implementation auto-detects db9 by checking whether
`select version()` contains `db9-server`, and only then enables db9-specific
fallbacks.

Current db9-specific fallbacks:

- use `CREATE ROLE ... WITH LOGIN PASSWORD ...` and `ALTER ROLE ... WITH
  PASSWORD ...` during PostgreSQL schema bootstrap
- avoid fragile `SELECT EXISTS(...)` result-shape assumptions in schema checks
- tolerate missing `pg_stat_database` by treating server-side TPM as
  unavailable instead of aborting immediately
- use a db9-compatible alias for the `ostat` prepared statement result shape

## Suggested TPROC-C Mode For db9

Use:

- `pg_storedprocs=false`

Reason:

- db9 local compatibility already reaches successful `TPROC-C buildschema` in
  non-stored-procedure mode
- stored-procedure mode still depends on broader PL/pgSQL parity

## Example db9 Scripts

See:

- [`scripts/tcl/postgres/tprocc/pg_tprocc_db9_nosp_buildschema.tcl`](/Users/chenhuansheng/Documents/GitHub/dbsid/HammerDB/scripts/tcl/postgres/tprocc/pg_tprocc_db9_nosp_buildschema.tcl)
- [`scripts/tcl/postgres/tprocc/pg_tprocc_db9_nosp_checkschema.tcl`](/Users/chenhuansheng/Documents/GitHub/dbsid/HammerDB/scripts/tcl/postgres/tprocc/pg_tprocc_db9_nosp_checkschema.tcl)
- [`scripts/tcl/postgres/tprocc/pg_tprocc_db9_nosp_run.tcl`](/Users/chenhuansheng/Documents/GitHub/dbsid/HammerDB/scripts/tcl/postgres/tprocc/pg_tprocc_db9_nosp_run.tcl)

## Example PostgreSQL 18.3 Scripts

See:

- [`scripts/tcl/postgres/tprocc/pg_tprocc_pg18_buildschema.tcl`](/Users/chenhuansheng/Documents/GitHub/dbsid/HammerDB/scripts/tcl/postgres/tprocc/pg_tprocc_pg18_buildschema.tcl)
- [`scripts/tcl/postgres/tprocc/pg_tprocc_pg18_checkschema.tcl`](/Users/chenhuansheng/Documents/GitHub/dbsid/HammerDB/scripts/tcl/postgres/tprocc/pg_tprocc_pg18_checkschema.tcl)
- [`scripts/tcl/postgres/tprocc/pg_tprocc_pg18_run.tcl`](/Users/chenhuansheng/Documents/GitHub/dbsid/HammerDB/scripts/tcl/postgres/tprocc/pg_tprocc_pg18_run.tcl)

Equivalent `TPROC-H` scripts are provided under:

- [`scripts/tcl/postgres/tproch`](/Users/chenhuansheng/Documents/GitHub/dbsid/HammerDB/scripts/tcl/postgres/tproch)

## Known Remaining Gaps

The fork improves db9 compatibility materially, but db9 is not yet feature
equivalent with PostgreSQL 18.3.

Known remaining gaps from local validation include:

- some `TPROC-C` checkschema assumptions in HammerDB Tcl still need db9-shaped
  handling
- `pg_stat_database` is still absent on db9, so server-side TPM is degraded to
  a fallback path
- some `TPC-C` / `TPC-H` query shapes may still hit parser or catalog
  compatibility gaps inside db9
