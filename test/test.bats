#!/usr/bin/env bats

load test_helpers

# make tests transactional
setup() {
  db_query "SAVEPOINT pre_test"
  cp db/schema.rb db/schema.rb.bak
}

teardown() {
  db_query "ROLLBACK TO SAVEPOINT pre_test"
  mv db/schema.rb.bak db/schema.rb
  rm -rf plugins/*
}

@test "migrates upwards" {
  mk_redmine_plugin "foo"
  db_table_exists 'tags'
  db_table_exists 'taggings'
}
