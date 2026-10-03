#!/usr/bin/env bats
# Шаг extract_version в sonar.yml: версия пакета для sonar.projectVersion.

load helpers/workflow

setup() {
  cd "$BATS_TEST_TMPDIR"
}

@test "версия пакета берётся из Версия() в packagedef" {
  packagedef 1.2.3
  run run_step sonar.yml sonar extract_version
  [ "$status" -eq 0 ]
  [ "$(step_output version)" = "1.2.3" ]
}

@test "ВерсияСреды() не путается с версией пакета" {
  packagedef 1.2.3 1.9.2
  run run_step sonar.yml sonar extract_version
  [ "$status" -eq 0 ]
  [ "$(step_output version)" = "1.2.3" ]
}
