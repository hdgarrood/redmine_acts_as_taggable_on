#!/usr/bin/env bats

load test_helpers

setup() {
  pushd "$temp_redmine_path/redmine"
  cp db/redmine.sqlite3 db/redmine.sqlite3.bak
  cp db/schema.rb db/schema.rb.bak
}

teardown() {
  rm -rf plugins/*
  mv db/schema.rb.bak db/schema.rb
  mv db/redmine.sqlite3.bak db/redmine.sqlite3
  popd
}

@test "migrates upwards" {
  mk_foo_plugin
  rake redmine:plugins:migrate

  db_table_exists 'tags'
  db_table_exists 'taggings'
}
