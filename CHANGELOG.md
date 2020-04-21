13.2.0 - 2020-04-21
=====================
* Patch Netzke components, so that they won't call model methods directly and use model_adapter instead.
* Pass model adapter to the forms from grid. Otherwise they might automatically find a different adapter based on model class.
* Add Marty::Grid::HashDataAdapter that allows to inherit from it and define only few specific methods that should return hashes instead of AR instances.

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

