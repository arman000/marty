14.0.0 - 2020-04-28
=====================================================
* Adds NULL support for data grid matchers:
Adds strict_null_mode field to Marty::DataGrids
In non strict mode passed nil attribute is now treated the same way is missing: it matches everything.
All existing grids are in non strict_null_mode by default
In strict mode it would only match wildcards and keys with NULL value
NULL can be combined with other values in array

* DataGrid's PLPGSQL lookups are no longer supported

13.1.0 - 2020-04-14
=====================
* Use ruby for Marty::DataGrid lookups. That gives a small performance boost and simplifies the code.

Use `Rails.application.config.marty.data_grid_plpg_lookups = true` if
you want to continue using PLPG for lookups. That can be deprecated in
future

13.0.2 - 2020-04-14
=================
* Use VARCHAR without size limit instead of recently added TEXT columns, since default field for TEXT column is textarea.

13.0.1 - 2020-04-14
=================
* Add missing index by `posting_type` for `marty_postings` table.

13.0.0 - 2020-04-13
======================

* All VARCHAR column types changed to TEXT

* Added schema linter

12.0.0 - 2020-04-02
=================
* Marty::PostingType converted to PgEnum. AR methods (find_by, all, etc...) will no longer work.

