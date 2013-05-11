#!/usr/bin/env bash
set -e

# makes a new Redmine installation in a temporary directory, using SQLite as
# the database.
make_temp_redmine() {
  temp_redmine=`mktemp -d /tmp/redmine_acts_as_taggable_on.tmp.XXXXXXXX`
  pushd "$temp_redmine"

  svn checkout http://svn.redmine.org/redmine/trunk redmine
  pushd redmine

  echo "development:
  adapter: sqlite3
  database: db/redmine.sqlite3" > config/database.yml

  bundle install
  rake generate_secret_token db:create db:migrate

  popd
  popd
}

make_temp_redmine >/dev/null
echo "$temp_redmine"
