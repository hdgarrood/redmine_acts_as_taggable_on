#!/usr/bin/env bash
set -e

export redmine_acts_as_taggable_on_path="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
pushd "$redmine_acts_as_taggable_on_path"

export temp_redmine_path="`test/mk_temp_redmine.bash`"

test/bats/bin/bats test/test.bats

popd
