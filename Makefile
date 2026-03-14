.PHONY: install
install:
	gem install bundler
	bundle install

.PHONY: dev
dev:
	rails s

.PHONY: db-create
db-create:
	rails db:create

.PHONY: db-migrate
db-migrate:
	rails db:migrate

.PHONY: db-drop
db-drop:
	rails db:drop

.PHONY: rubocop
rubocop:
	./bin/rubocop

.PHONY: rubocop-fix
rubocop-fix:
	./bin/rubocop -A
