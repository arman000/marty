Things that may affect how independent Marty can be as a gem:

* It requires a database.yml file for testing purposes.
  For now that file refers to a postgresql instance but maybe it should be
  a sqlite db instead
* There was a `rake db:create` required in the dummy app directory
* It depends on the Mcfly gem?
* PostingType and Posting tables both need to be pre-seeded to operate correctly.
* verify if migrations in the dummy test job are done correctly and that migrations
  in the top level directory match. Are the test job ones supposed to come from
  those top-level ones?
* User model tests shouldn't rely on `User.last` as an alternate user type.

## Things pulled from Gemini:

* `load_script_bodies` and `load_a_script` went into `spec/support/script_helpers.rb` from `app/controllers/gemini/application_controller.rb` - for api and promise model specs
* `app/models/gemini/helper.rb` (came from same place in Gemini) - for promise model specs
