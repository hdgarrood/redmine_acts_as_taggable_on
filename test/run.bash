#!/usr/bin/env bash
set -e

# Run all the tests on a specific branch of Redmine.
run_tests_on_branch() {
  local temp_redmine_path="$($redmine_acts_as_taggable_on_path/test/mk_temp_redmine.bash "$1")"
  if [ "$?" -ne 0 ] || [ -z "$temp_redmine_path" ]; then
    echo "failed to create temporary redmine on $1: cancelling these tests"
    return 1
  fi

  export temp_redmine_path
  cd "$temp_redmine_path/redmine"

  local test_status=0
  "$redmine_acts_as_taggable_on_path/test/bats/bin/bats" \
    "$redmine_acts_as_taggable_on_path/test/test.bats" || test_status=1

  # avoid 'error retrieving current directory' during the next test
  cd /tmp

  if [ "$test_status" -eq 1 ]; then
    echo "Some tests failed on $1. You can inspect the tree at $temp_redmine_path"
  else
    rm -rf "$temp_redmine_path"
  fi

  return $test_status
}

export RAILS_ENV="production"

# these are needed on Travis CI
export BUNDLE_GEMFILE=""
export PATH="./bin:$PATH"

redmine_acts_as_taggable_on_path="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
export redmine_acts_as_taggable_on_path

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

exit $test_status
