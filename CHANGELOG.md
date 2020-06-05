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

