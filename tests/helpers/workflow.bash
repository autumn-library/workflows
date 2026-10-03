# Исполнение run-скриптов шагов workflow вне GitHub Actions.
# Нужны yq (mikefarah, v4) и jq.

WORKFLOWS_DIR="${BATS_TEST_DIRNAME}/../.github/workflows"

# Печатает run-скрипт шага.
#   $1 - файл workflow относительно .github/workflows
#   $2 - job
#   $3 - id шага
step_script() {
  local script
  script=$(yq -o=json '.' "$WORKFLOWS_DIR/$1" \
    | jq -er --arg job "$2" --arg id "$3" '.jobs[$job].steps[] | select(.id == $id) | .run') \
    || { echo "в $1 нет шага $2/$3" >&2; return 1; }
  printf '%s\n' "$script"
}

# Исполняет run-скрипт шага в текущем каталоге, как раннер: bash -eo pipefail.
# Выходы шага пишутся в $GITHUB_OUTPUT, их читает step_output.
#   $1, $2, $3 - как у step_script
#   далее      - входы workflow вида имя=значение, подставляются вместо ${{ inputs.имя }}
# Подстановка, для которой значение не передано, — ошибка: иначе в bash уехал бы ${{ }}.
run_step() {
  local script pair name
  script=$(step_script "$1" "$2" "$3") || return 1
  shift 3
  for pair in "$@"; do
    name="${pair%%=*}"
    script="${script//"\${{ inputs.$name }}"/${pair#*=}}"
  done
  if [[ "$script" == *'${{'* ]]; then
    echo "в скрипте остались неподставленные выражения:" >&2
    grep -o '\${{[^}]*}}' <<<"$script" >&2
    return 1
  fi

  : > "$(output_file)"
  GITHUB_OUTPUT="$(output_file)" bash --noprofile --norc -eo pipefail -c "$script"
}

# Печатает значение выхода шага из $GITHUB_OUTPUT.
#   $1 - имя выхода
step_output() {
  sed -n "s/^$1=//p" "$(output_file)"
}

# run исполняет шаг в подоболочке, поэтому путь не экспортируется, а вычисляется заново.
output_file() {
  echo "$BATS_TEST_TMPDIR/github_output"
}

# Пишет packagedef в текущий каталог: имя, версия пакета и, если передана, версия среды.
#   $1 - версия пакета
#   $2 - версия среды (необязательно)
packagedef() {
  {
    echo 'Описание.Имя("my-lib")'
    echo "        .Версия(\"$1\")"
    [ -n "${2:-}" ] && echo "        .ВерсияСреды(\"$2\")"
    echo '        .ЗависитОт("asserts")'
  } > packagedef
}
