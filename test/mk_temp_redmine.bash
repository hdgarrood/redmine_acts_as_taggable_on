#!/usr/bin/env bash
set -e

# makes a temporary Redmine installation in ./redmine, using SQLite as the
# database.
mk_temp_redmine_function() {
  svn checkout http://svn.redmine.org/redmine/trunk redmine
  cd redmine

  echo "development:
  adapter: sqlite3
  database: db/redmine.sqlite3" > config/database.yml

  bundle install
  rake generate_secret_token
  rake db:migrate
}

temp_redmine=`mktemp -d /tmp/redmine_acts_as_taggable_on.tmp.XXXXXXXX`
pushd "$temp_redmine" >/dev/null
mk_temp_redmine_function >/dev/null
popd >/dev/null

unset -f mk_temp_redmine_function
echo $temp_redmine
