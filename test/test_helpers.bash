#!/usr/bin/env bash

# Creates a redmine plugin, assuming the current directory is the redmine root.
mk_redmine_plugin() {
  case $1 in
    foo)  _mk_foo_plugin;;
    *)    echo "mk_redmine_plugin: unknown plugin $2" >&2; return 1;;
  esac
}

# A plugin using the gem properly.
_mk_foo_plugin() {
  mkdir plugins/redmine_foo
  cd plugins/redmine_foo

  echo "gem 'redmine_acts_as_taggable_on',
  :path => '$redmine_acts_as_taggable_on_path'" > Gemfile

  echo "require 'redmine_acts_as_taggable_on/initialize'
Redmine::Plugin.register :redmine_foo { requires_acts_as_taggable_on }" \
    > init.rb

  mkdir -p db/migrate
  echo "class AddTagsAndTaggings < RedmineActsAsTaggableOn::Migration; end" \
    > db/migrate/001_add_tags_and_taggings.rb

  bundle

  cd ../..
}

db_query() {
  # use -init to ensure ~/.sqliterc isn't read
  sqlite3 -init "" db/redmine.sqlite3 "$1"
}

db_table_exists() {
  db_query "SELECT 'it exists'
  FROM sqlite_master
  WHERE type='table' AND name='$1'" | grep 'it exists' >/dev/null
}
