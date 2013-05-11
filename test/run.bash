#!/usr/bin/env bash
set -e

RAILS_ENV=development
export RAILS_ENV

redmine_acts_as_taggable_on_path="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
export redmine_acts_as_taggable_on_path
pushd "$redmine_acts_as_taggable_on_path" >/dev/null

temp_redmine_path="`test/mk_temp_redmine.bash`"
export temp_redmine_path
pushd "$redmine_acts_as_taggable_on_path" >/dev/null
[ -f test/bats/bin/bats ] || git submodule update

test_status=0
test/bats/bin/bats test/test.bats || test_status=1

rm -rf "$temp_redmine_path"
popd >/dev/null

if [ "$test_status" -ne 0 ]; then
    echo "test output was:"
    cat /tmp/bats.*.out
fi

exit $test_status
