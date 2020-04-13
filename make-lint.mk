lint:
	make lint-ruby
	make lint-js
	make lint-schema

lint-fix:
	make lint-ruby-fix
	make lint-js-fix

lint-ruby:
	bundle exec rubocop

lint-ruby-fix:
	bundle exec rubocop -a

lint-js:
	yarn lint

lint-js-fix:
	yarn lint-fix

lint-schema:
	yarn lint-schema
