# Исполнение run-скриптов шагов workflow вне GitHub Actions.
# Нужны yq (mikefarah, v4) и jq.

WORKFLOWS_DIR="${BATS_TEST_DIRNAME}/../.github/workflows"

# Печатает workflow в JSON.
#   $1 - файл workflow относительно .github/workflows
workflow_json() {
  yq -o=json '.' "$WORKFLOWS_DIR/$1"
}

# Печатает поле шага как текст.
#   $1 - файл workflow относительно .github/workflows
#   $2 - job
#   $3 - id шага
#   $4 - поле шага: run, if, ...
step_field() {
  workflow_json "$1" \
    | jq -er --arg job "$2" --arg id "$3" --arg field "$4" \
      '.jobs[$job].steps[] | select(.id == $id) | .[$field]' \
    || { echo "в $1 нет поля $4 у шага $2/$3" >&2; return 1; }
}

# Печатает run-скрипт шага.
#   $1, $2, $3 - как у step_field
step_script() {
  step_field "$1" "$2" "$3" run
}

# Исполняет run-скрипт шага в текущем каталоге, как раннер: bash -eo pipefail.
# Переменные из env workflow, job'а и шага экспортируются; значение, где после подстановки
# входов осталось выражение (например, ${{ secrets.* }}), не экспортируется.
# Выходы шага пишутся в $GITHUB_OUTPUT, их читает step_output.
#   $1, $2, $3 - как у step_field
#   далее      - входы workflow вида имя=значение, подставляются вместо ${{ inputs.имя }};
#                если имя передано дважды, действует первое значение
# Неподставленное выражение в самом скрипте — ошибка: иначе в bash уехал бы ${{ }}.
run_step() {
  local file="$1" job="$2" id="$3" script name value
  script=$(step_script "$file" "$job" "$id") || return 1
  shift 3

  script=$(render "$script" "$@")
  if [[ "$script" == *'${{'* ]]; then
    echo "в скрипте остались неподставленные выражения:" >&2
    grep -o '\${{[^}]*}}' <<<"$script" >&2
    return 1
  fi

  while IFS= read -r name; do
    value=$(render "$(step_env "$file" "$job" "$id" | jq -r --arg name "$name" '.[$name]')" "$@")
    [[ "$value" == *'${{'* ]] || export "$name=$value"
  done < <(step_env "$file" "$job" "$id" | jq -r 'keys[]')

  : > "$(output_file)"
  GITHUB_OUTPUT="$(output_file)" bash --noprofile --norc -eo pipefail -c "$script"
}

# Окружение шага: env workflow, поверх него env job'а, поверх — env шага.
step_env() {
  workflow_json "$1" | jq --arg job "$2" --arg id "$3" \
    '(.env // {}) + (.jobs[$job].env // {})
     + (.jobs[$job].steps[] | select(.id == $id) | .env // {})
     | map_values(tostring)'
}

# Подставляет входы имя=значение вместо ${{ inputs.имя }} в тексте $1.
render() {
  local text="$1" pair
  shift
  for pair in "$@"; do
    text="${text//"\${{ inputs.${pair%%=*} }}"/${pair#*=}}"
  done
  printf '%s' "$text"
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
