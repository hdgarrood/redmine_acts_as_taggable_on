#!/usr/bin/env bash
set -e

# if --verbose is given, output logging info to stdout. Otherwise, to /dev/null
if [ "$1" = "--verbose" ]; then
  shift
  mk_temp_redmine_out="/dev/fd/2"
else
  mk_temp_redmine_out="/dev/null"
fi

# makes a new Redmine installation in a temporary directory, using SQLite as
# the database.
branch="$1"
[ -z "$branch" ] && branch="trunk"

# for branches which have slashes in them, like tags/2.3.0
branch_filename="${branch//\//-}"
temp_redmine=`mktemp -d /tmp/redmine_acts_as_taggable_on.$branch_filename.XXXXXXX`
cd "$temp_redmine"

svn checkout "http://svn.redmine.org/redmine/$branch" redmine \
  > "$mk_temp_redmine_out"
cd redmine

echo "production:
  adapter: sqlite3
  database: db/redmine.sqlite3" > config/database.yml

bundle install \
  --without="development test rmagick ldap mysql postgresql" \
  --gemfile="$PWD/Gemfile" \
  --binstubs \
  > "$mk_temp_redmine_out"

rake db:create db:migrate > "$mk_temp_redmine_out"

echo "$temp_redmine"
