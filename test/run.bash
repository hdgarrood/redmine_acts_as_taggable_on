#!/usr/bin/env bash
set -e

# Run all the tests on a specific branch of Redmine.
run_tests_on_branch() {
  temp_redmine_path="$(test/mk_temp_redmine.bash "$1")"
  if [ "$?" -ne 0 ]; then
    echo "failed to create temporary redmine on $1: cancelling these tests"
    return 1
  fi

  export temp_redmine_path

  [ -f test/bats/bin/bats ] || git submodule update

  local test_status=0
  test/bats/bin/bats test/test.bats || test_status=1

  if [ "$test_status" -eq 1 ]; then
    echo "Some tests failed on $1. You can inspect the tree at $temp_redmine_path"
  else
    rm -rf "$temp_redmine_path"
  fi

  temp_redmine_path=""
  return $test_status
}

RAILS_ENV="production"
export RAILS_ENV

redmine_acts_as_taggable_on_path="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
export redmine_acts_as_taggable_on_path
pushd "$redmine_acts_as_taggable_on_path" >/dev/null

# branches should be a space-separated string of repo paths to check out.
# We don't use an array because they're difficult to export.
[ -z "$branches" ] && branches="tags/2.3.1"
test_status=0

for branch in $branches; do
  echo    "testing on: $branch"
  echo -n "============"
  # make the underline the same length as the title
  echo ${branch//?/=}

  run_tests_on_branch "$branch" || test_status=1
  echo
done

popd >/dev/null
exit $test_status
