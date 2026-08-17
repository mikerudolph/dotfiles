#!/usr/bin/env bash

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_eq() {
  local expected="$1" actual="$2" message="${3:-values differ}"
  [[ "$expected" == "$actual" ]] || fail "$message (expected '$expected', got '$actual')"
}

assert_file_contains() {
  grep -Fq "$2" "$1" || fail "$1 does not contain: $2"
}

new_sandbox() {
  mktemp -d "${TMPDIR:-/tmp}/dotfiles-test.XXXXXX"
}

