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