#!/usr/bin/env bats
# Шаг extract_oscript_version: какую версию OneScript ставить. Шаг повторён в трёх workflow,
# и каждый тест проверяет все три копии.

load helpers/workflow

STEPS=("release.yml build" "test.yml build" "sonar.yml test")

setup() {
  cd "$BATS_TEST_TMPDIR"
}

# Прогоняет шаг каждого workflow и сверяет выход version.
#   $1 - ожидаемая версия
#   $2 - значение входа oscript_version
expect_version() {
  local entry
  for entry in "${STEPS[@]}"; do
    read -r file job <<<"$entry"
    run run_step "$file" "$job" extract_oscript_version "oscript_version=$2"
    [ "$status" -eq 0 ] || { echo "$file: шаг упал: $output"; return 1; }
    [ "$(step_output version)" = "$1" ] \
      || { echo "$file: version='$(step_output version)', ожидалось '$1'"; return 1; }
  done
}

@test "default берёт версию из ВерсияСреды() в packagedef" {
  packagedef 1.2.3 1.9.2
  expect_version 1.9.2 default
}

@test "default без ВерсияСреды() в packagedef — stable" {
  packagedef 1.2.3
  expect_version stable default
}

@test "default без packagedef — stable" {
  expect_version stable default
}

@test "явная версия используется как есть, packagedef не читается" {
  packagedef 1.2.3 1.9.2
  expect_version dev dev
}
