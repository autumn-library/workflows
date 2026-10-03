#!/usr/bin/env bats
# Доверенная публикация в release.yml: id-token конвейера вместо PUSH_TOKEN, пул по выбору.
# curl подменён заглушкой: на запрос id-token она отдаёт JSON, а аргументы каждого вызова
# пишет в файл call.N — call.0 это запрос id-token, call.1 это публикация.

load helpers/workflow

setup() {
  cd "$BATS_TEST_TMPDIR"
  mkdir bin
  cat > bin/curl <<'STUB'
#!/usr/bin/env bash
n=$(ls "$BATS_TEST_TMPDIR"/call.* 2>/dev/null | wc -l)
printf '%s\n' "$@" > "$BATS_TEST_TMPDIR/call.$n"
case "$*" in
  *token-request*) echo '{"value":"FAKE.ID.TOKEN"}' ;;
  *) echo '{"КодСостояние": 200, "Сообщение": "ok"}' ;;
esac
STUB
  chmod +x bin/curl
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  export ACTIONS_ID_TOKEN_REQUEST_URL="https://gh.example/token-request?api-version=2.0"
  export ACTIONS_ID_TOKEN_REQUEST_TOKEN="request-token"
  touch mylib-1.0.0.ospx
}

# Запускает шаг публикации; входы, переданные аргументами, перекрывают умолчания ниже.
publish() {
  run run_step release.yml build trusted_push "$@" \
    package_mask='mylib-*.ospx' hub_url=https://hub.example pool=default audience=
}

# Проверяет, что вызов curl номер $1 получил аргумент $2 целиком.
call_has() {
  grep -qxF -- "$2" "$BATS_TEST_TMPDIR/call.$1" \
    || { echo "вызов $1 без аргумента '$2':"; cat "$BATS_TEST_TMPDIR/call.$1" 2>/dev/null; return 1; }
}

# Проверяет, что шаг не вызвал curl ни разу.
no_calls() {
  ! ls "$BATS_TEST_TMPDIR"/call.* >/dev/null 2>&1
}

# Печатает значение по умолчанию входа $1 workflow release.yml.
input_default() {
  workflow_json release.yml | jq -r ".on.workflow_call.inputs.$1.default"
}

@test "доверенная публикация выключена по умолчанию, пул по умолчанию — default" {
  [ "$(input_default trusted_publishing)" = "false" ]
  [ "$(input_default pool)" = "default" ]
  [ "$(input_default hub_url)" = "https://hub.oscript.io" ]
  [ "$(input_default audience)" = "" ]
}

@test "публикует либо opm push с токеном, либо доверенный шаг — не оба" {
  [ "$(step_field release.yml build token_push if)" = '${{ !inputs.trusted_publishing }}' ]
  [ "$(step_field release.yml build trusted_push if)" = '${{ inputs.trusted_publishing }}' ]
}

@test "входы попадают в скрипт только через env — пул из workflow_dispatch не инъекция" {
  run step_script release.yml build trusted_push
  [ "$status" -eq 0 ]
  [[ "$output" != *'${{'* ]]
}

@test "публикует в пул default по полному адресу" {
  publish
  [ "$status" -eq 0 ]
  call_has 1 "https://hub.example/api/v1/pools/default/push"
  call_has 1 "OAUTH-TOKEN: FAKE.ID.TOKEN"
  call_has 1 "FILE-NAME: mylib-1.0.0.ospx"
  call_has 1 "CHANNEL: stable"
  call_has 1 "@mylib-1.0.0.ospx"
}

@test "id-token запрашивается с аудиторией = адрес хаба и маскируется в логе" {
  publish
  [ "$status" -eq 0 ]
  call_has 0 "$ACTIONS_ID_TOKEN_REQUEST_URL"
  call_has 0 "Authorization: bearer request-token"
  call_has 0 "audience=https://hub.example"
  [[ "$output" == *"::add-mask::FAKE.ID.TOKEN"* ]]
}

@test "явная аудитория уходит в запрос id-token" {
  publish audience=oshub-prod
  [ "$status" -eq 0 ]
  call_has 0 "audience=oshub-prod"
}

@test "выбранный пул — в адресе публикации" {
  publish pool=corp
  [ "$status" -eq 0 ]
  call_has 1 "https://hub.example/api/v1/pools/corp/push"
}

@test "пустой пул (запуск по релизу) — default" {
  publish pool=
  [ "$status" -eq 0 ]
  call_has 1 "https://hub.example/api/v1/pools/default/push"
}

@test "пробелы вокруг имени пула срезаются" {
  publish pool='  corp  '
  [ "$status" -eq 0 ]
  call_has 1 "https://hub.example/api/v1/pools/corp/push"
}

@test "хвостовой / адреса хаба срезается" {
  publish hub_url=https://hub.example/
  [ "$status" -eq 0 ]
  call_has 0 "audience=https://hub.example"
  call_has 1 "https://hub.example/api/v1/pools/default/push"
}

@test "недопустимое имя пула — отказ до любых запросов" {
  local bad
  for bad in 'a/b' 'x;id' '../x' '-x' '.x' 'a b'; do
    publish pool="$bad"
    [ "$status" -ne 0 ] || { echo "пул '$bad' принят"; return 1; }
    [[ "$output" == *"Недопустимое имя пула"* ]]
    no_calls || { echo "пул '$bad': запрос ушёл"; return 1; }
  done
}

@test "без permissions id-token: write — отказ с подсказкой" {
  unset ACTIONS_ID_TOKEN_REQUEST_URL
  publish
  [ "$status" -ne 0 ]
  [[ "$output" == *"id-token: write"* ]]
  no_calls
}

@test "по маске нет файла — отказ без публикации" {
  rm mylib-1.0.0.ospx
  publish
  [ "$status" -ne 0 ]
  [[ "$output" == *"найдено файлов: 0"* ]]
  no_calls
}

@test "по маске два файла — отказ без публикации" {
  touch mylib-1.0.1.ospx
  publish
  [ "$status" -ne 0 ]
  [[ "$output" == *"найдено файлов: 2"* ]]
  no_calls
}
