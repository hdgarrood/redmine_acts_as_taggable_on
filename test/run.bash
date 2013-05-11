#!/usr/bin/env bash
set -e

RAILS_ENV=development
export RAILS_ENV

redmine_acts_as_taggable_on_path="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
export redmine_acts_as_taggable_on_path
pushd "$redmine_acts_as_taggable_on_path" >/dev/null

temp_redmine_path="`test/mk_temp_redmine.bash`"
export temp_redmine_path

[ -f test/bats/bin/bats ] || git submodule update

test_status=0
test/bats/bin/bats test/test.bats || test_status=1

rm -rf "$temp_redmine_path"
popd >/dev/null

exit $test_status
