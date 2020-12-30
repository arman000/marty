[![Build Status](https://travis-ci.org/arman000/marty.svg)](https://travis-ci.org/arman000/marty)
# Marty

Marty is a framework for viewing and reporting on versioned data.
Marty provides its own scripting environment.  Scripts can also be
verioned.  RESTful APIs are provided for accessing and executing
vesioned scripts.

Marty also provides user authentication and session support.
Currently, only LDAP-based authentication is supported.  There's also
support for role-based authorization.

# Rake tasks

The Marty framework provides several rake tasks to manage its database tables
and delorean scripts.

To create the correct migrations for a Marty-based application (see below for
getting the internal dummy application to work):

```bash
rake marty:install:migrations
```

The Marty database needs to be seeded with specific configuration
information. Before running your Marty application for the first time you will
need to run:

```bash
rake marty:seed
```

If you are using Delorean scripts in your application you can load them
with a rake task. By default these scripts will be picked up from
`app/delorean_scripts`. To load scripts:

```bash
rake marty:load_scripts
```

You can override the default directory by setting the `LOAD_DIR` environment
variable:

```bash
LOAD_DIR=<delorean script directory> marty:load_scripts
```

To delete scripts:

``` bash
rake marty:delete_scripts
```

# Scheduled Job

To use scheduled background jobs, add to `config/application.rb`:

```bash
config.active_job.queue_adapter = :delayed_job
```

## Using Monit to keep background jobs alive

To have monit keep track of background jobs run a bash script to configure
monit after deployment. An example script is provided in `.application-scripts`

## Marty SqlServers

Marty comes with support for using the ActiveRecord SQL Server adapter. To use
this functionality you will need:

- A `config/sql_servers.yml` file that specifies your endpoint configurations,
similar to `config/database.yml`
- Create an initializer that:
  - requires the needed files with `require 'marty/sql_servers'`
  - connects on startup with `Marty::SqlServers.generate_database_connections!`

*note* The ActiveRecord SQL Server adapter will escape queries and stored
procedure variables by default.

*note* The ActiveRecord SQL Server adapter enforces that all XML is sent
as UTF-16 Little Endian. You will want to remove the instructions on XML or
ensure that they are UTF-16 LE.

# Dummy Application & Testing

Make sure that extjs is installed (or symbolically linked) in the
dummy app at spec/dummy/public.

Docker doesn't support symlinks, so in order to run it in Docker you will have to copy extjs files.

```bash
cp -r PATH/TO/YOUR/EXTJS/FILES spec/dummy/public/extjs
```

You can run it with Docker:

```bash
make app-initialise-docker
make app-start
```

To run tests:

```bash
make app-bash
HEADLESS=true rspec
```

You can also use docker for running Postgres and Redis only:

```bash
cp spec/dummy/config/database.yml.db_in_docker.example spec/dummy/config/database.yml

make db-start
make db-stop
```

Postgres container would listen to 3030 port

To run without Docker:

Marty currently only runs with PostgreSQL. To be able to run the tests
you will first need to create a `database.yml` file in `spec/dummy/config`.
You can use the example file by doing:

```bash
cp spec/dummy/config/database.yml.example spec/dummy/config/database.yml
```

To initialize the dummy application for a demo run:

```bash
bundle install
bundle exec rake db:create db:migrate db:seed app:marty:load_scripts
cd spec/dummy
bundle exec rails s
```

Or, to run the application with the job workers running:

```bash
bundle install
bundle exec rake db:create db:migrate db:seed app:marty:load_scripts
cd spec/dummy
gem install foreman
foreman start
```

The Marty dummy app should now be accessible in your browser:
`localhost:3000`

You can log in using `marty` as both user and password.

To create the test database in prepartion to run your tests:

```bash
RAILS_ENV=test bundle exec rake db:create
```

Then to run the tests:

```bash
bundle exec rspec
```
## Test Isolation Support

To make it easier to run tests in CI pipelines, Marty comes with a functionality
that can make recordings of external calls which can be replayed during tests.

To use this `RequestRecording` functionality you will need to do the following:

- Include `gem 'vcr'` and `gem 'webmock'` in your gemfile
- Require the desired files in your RSpec configuration
  - `Marty::Gem.require_file!('spec/support/request_recording')` for HTTP requests
  - `Marty::Gem.require_file!('spec/support/request_recording/sql_server')` for SQL Server requests
- When running a test that connects to an external service, first run the test
  in an environment with connectivity and enable "Recording Mode" by setting
  the environment variable `MARTY_RSPEC_RECORD=true`
- Should you need to regenerate a test recording, the same environment variable
  can be used to update test recordings.

# History & Status

Marty was originally part of a much larger project internal to
PennyMac.  We have split Marty from its original home with the goal of
making it generally available as a platform for working with versioned
data and scripts. However, some rspec and cucumber tests are still in
the parent and have yet to be ported. Also, documentation is sorely
lacking. Hopefully, this will be rectified soon.

# WIP Documentation

## Reports in Delorean

Reports are the interface inside marty for users to submit data to processes
as well as export data. To create a report you will need to create a Delorean
script with the following conditions:

- The script name must end in _report, e.g. example_report.dl
- In a node inside the above script, define the following:
  - title: The display title for the report in the UI
  - form: A list of fields that will be mapped to any paramters in your node.
  - result: This is the value returned after running the report
  - optional
    - roles: provide a list of roles that have access to execute the report.
    - format: provide the format for the report result. This will default to json.

An exmaple node would be, which would belong in `example_report.dl`
```ruby
ExmapleExtract:
    title   = "My Example Report"
    roles   = ['admin', 'user_manager']
    raw     = # some logic to do things goes here
    result  = Marty::Helper.to_csv(raw)
    form    = []
    format  = "csv"
```
