18.2.0 - 2020-10-23
=====================================================

* Add a button that allows to clear Delorean cache. That might be useful
  if Redis is used for caching.

18.1.3 - 2020-10-23
=====================================================

* Fix grid caching in cases the infinity grid was cached and then updated.

18.1.2 - 2020-10-22
=====================================================

* Change `has_mcfly` to `mcfly`
* Fix bug with `listeners` that caused custom `listeners` to be overwritten in grids.
* Fix `ServerTime` diagnostic.
* Fix `DelayedJobVersion` diagnostic in development mode.

18.1.1 - 2020-10-20
=====================================================

* Added `ObjectSizes` diagnostic that shows database object sizes.

18.1.0 - 2020-10-13
=====================================================

* Added test coverage to `Marty::SqlServer` module and improved behavior
  for EXEC calls that return rowsets.

18.0.2 - 2020-10-12
=====================================================

* Update how css is integrated into diagnostics and change style.
* Add help menu when bad diagnostics are entered.
* Add new marty config `diagnostic_directory` in order to allow application diagnostics to be initialized and appear in help menu.
* Updates `delayed_job_version` diagnostic to have spam protection.
* Removed `diagnostics.dl`

18.0.1 - 2020-10-09
=====================================================

* Feature fix for 16.9.0. Make Delayed Job's run as root functionality configurable.

18.0.0 - 2020-10-09
=====================================================

* Remove mini_racer dependency from the gemspec. Marty::Rules::Runtime would still require MiniRacer classes to be present if it's used.

17.5.0 - 2020-10-08
=====================================================

* Added test coverage to `Marty::SqlServer` module and improved behavior
  for EXEC calls that return rowsets.

17.4.0 - 2020-10-06
=====================================================

* Added `Marty::SqlServer` module to act as an interface for database connections
  to auxillary SQL Server systems.
* Added `Marty::RSpec::VcrSqlServer` to help stub requests going in and out of
  `Marty::SqlServer` connections.
* Added `.yardopts`.

17.3.0 - 2020-09-24
=====================================================

* Add a v0.1 V8 runtime to run JS packaged rules

17.2.0 - 2020-09-24
=====================================================

* Add an admin button to convert all DataGrids to strict_null_mode
* Add a 'ENFORCE_DATA_GRID_STRICT_NULL_MODE' flag to Marty::Config. If set to true it DG would require to be in strict_null_mode during the validation.

17.1.0 - 2020-09-23
=====================================================

* Added Zeitwerk initializer that resolves netzke-basepack and other issues.

17.0.0 - 2020-09-22
=====================================================

* Remove unused cache and PLV methods from `Marty::DataGrid`
* Remove Data Grid index models
* Refactor usage of `INDEX_MAP` in `Marty::DataGrid`

16.11.0 - 2020-09-03
=====================================================

* Change column type from VARCHAR to CITEXT for marty_users.login and add a unique index for it.

16.10.0 - 2020-08-18
=====================================================

* Refactor Cleaner to use a common maintenance window service.

16.9.0 - 2020-08-18
=====================================================

* Replace DELAYED_JOB_PARAMS with DELAYED_JOB_WORKERS to make it easier to
  ensure that monit can be synced with Marty to manage Delayed Job workers.
* Add sample script for monit config
* Add `Marty::DelayedJobWorkerReaperJob` to restart jobs regularly
* Various small fixes related to interacting with Delayed Job workers through
  the Marty UI

16.8.0 - 2020-07-16
=====================================================

* Add new diagnostic to check that server and database time are in sync.

16.7.0 - 2020-07-14
=====================================================

* Move `action_mailer` defaults into `Marty::Engine` for automatic
  initialization.

16.6.0 - 2020-07-10
=====================================================

* Fix the issue with latest delayed_cron_job gem versions.

16.5.1 - 2020-07-08
=====================================================

* There is a specific case with using send for DataGrids in Rules. Consider the following:
* DataGrid has attr `x`
* `x` is not passed to Rule and is not defined in the results section
* There is a default value for `x` defined in the rule Node code: `x =? nil`

We shouldn't pass `{ "x" => nil }` to the DG in that case, since it breaks our apps.
However passing it would make sense and we might want to do it in the future.

16.5.0 - 2020-07-07
=====================================================

* Use camelCase in JS code
* Use += 1 and -= 1 instead of ++ and -- in JS code

16.4.0 - 2020-07-02
=====================================================

* Add comments to grids.
One comment per row
The column on the right of the grid's view/edit window is the one with comments.
Users can not add a column to the right of the one with comments.

16.3.0 - 2020-06-24
=====================================================

* Add ActionMailer defaults to be used by Marty applications through ENV
  variables.

16.2.0 - 2020-06-29
=====================================================

* Change `perform` to `perform_now` when running scheduled jobs in order to be
  able to utilize callbacks.
* Change verbiage of "Schedule Job's Log" to "Scheduled Jobs Log".

16.1.0 - 2020-06-09
=====================================================
* Adds a column `run_by` to Marty::Promise that shows what job runner ran the promise. Takes the value from `job.locked_by` column.

16.0.0 - 2020-06-05
=====================================================
* Fully remove PG support for DataGrids
* Drop DataGrid indices tables
* Drop DG related PG functions
* Would break the migrations that use marty/db/sql/...

15.1.1 - 2020-06-04
=====================================================
* In ruby regexes ^ and $ means beginning and end of line, not the whole string, which makes it unsafe in case if someone passed multiline string.
Use \A and \z instead.

15.1.0 - 2020-05-29
=====================================================
* Disable actions in Reporting view if no report is selected.

* Add opt-in ability to validate report's fields by setting `validate_form = true` in report's Delorean node.
Set `allow_empty = false` in the field's node to make it required.

* Add a Report that evaluates DataGrid by passing it the parameters from the JSON field.

15.0.0 - 2020-05-28
=====================================================
* Stop using separate grids column in our rules and use results instead. That would allow to compute grid name dynamically and simplify things in general.

```ruby
grids:
  adjustment = My Grid
  breakeven = My Breakeven Grid

results:
  res = adjustment_grid_result
```

Users will have to use something like that:

```ruby
results:
  adjustment_grid = "My Grid"
  breakeven_grid = "My Breakeven Grid"
  res = adjustment_grid_result
```

We should update our rules in the migration. We still display grids fields and columns, so that users can view older rules correctly. However Marty won't allow to create/update rule that has grids in the grids field.

If grid name is static, Marty would still validate its presence in the Marty::DataGrids table.

14.7.0 - 2020-05-26
=====================================================
* Add NULL support for numranges and intranges in DataGrids

14.6.0 - 2020-05-26
=====================================================
* Allow matching of the typed characters at any position in the values in comboboxes.

To opt out please use: `editor_config[:any_match] = false` in columns and `self.any_match = false` in fields.

14.5.0 - 2020-05-21
=====================================================
* Allow disabling multirecord editing in grids by setting multi_edit to false.

Enable multiselect for Gemini Rules' views and disable multiediting. For testing purposes, it would be convenient if user could delete multiple rules at once.

14.4.0 - 2020-05-18
=====================================================
* Use Rails.application.config.marty instead of ENV vars in Marty code.

Having one centralized structure with all application configs seems to
be more convenient than having ENV checks all over our code.

14.2.0 - 2020-05-05
=====================================================
* Treating passed nil to data grids in the same way as missing attribute
broke our lookups. Roll that change back. With this change, the behavior
would be the following:

In non strict null mode:
missing attribute matches everything
passed nil matches only wildcard keys (empty keys)

In strict_null_mode:
missing attribute matches only NULLs and wildcard keys
passed nil matches only NULLs and wildcard keys

14.2.0 - 2020-05-05
=====================================================
* Adds `Marty::Diagnostic::Version.git_tag` method that is used in diags and can be redifined in Marty apps.

14.1.0 - 2020-05-01
=====================
* Add cleaner service and migration. The job is disabled by default.

In monkey.rb override `CLASSES_TO_CLEAN` with the desired classes to be scanned/cleaned.

14.0.0 - 2020-04-28
=====================================================
* Adds NULL support for data grid matchers:
Adds strict_null_mode field to Marty::DataGrids
In non strict mode passed nil attribute is now treated the same way is missing: it matches everything.
All existing grids are in non strict_null_mode by default
In strict mode it would only match wildcards and keys with NULL value
NULL can be combined with other values in array

* DataGrid's PLPGSQL lookups are no longer supported

13.2.0 - 2020-04-30
=====================
* Add PDF content type handling

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

