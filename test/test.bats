#!/usr/bin/env bats

load test_helpers

# make tests transactional
setup() {
  pushd "$temp_redmine_path/redmine"
  db_query "SAVEPOINT pre_test"
  cp db/schema.rb db/schema.rb.bak
}

teardown() {
  rm -rf plugins/*
  mv db/schema.rb.bak db/schema.rb
  db_query "ROLLBACK TO SAVEPOINT pre_test"
  popd
}

@test "migrates upwards" {
  mk_redmine_plugin "foo"
  db_table_exists 'tags'
  db_table_exists 'taggings'
}
