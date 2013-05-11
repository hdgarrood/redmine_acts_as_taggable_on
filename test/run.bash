#!/usr/bin/env bash
set -e

export RAILS_ENV=development

export redmine_acts_as_taggable_on_path="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
pushd "$redmine_acts_as_taggable_on_path" >/dev/null

export temp_redmine_path="`test/mk_temp_redmine.bash`"
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
