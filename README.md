# workflows

Набор типовых сборочных линий GitHub Actions для библиотек и приложений OneScript.

Во всех сборочных линиях используется локальная установка пакетов opm через `opm install --local`. Убедитесь, что рядом со скриптами запуска тестов лежат файлы oscript.cfg с соответствующими настройками. 
Например, содержимое `oscript.cfg`, расположенного в каталоге `tasks`:

```ini
lib.system=../oscript_modules
```

## Тестирование

Сборочная линия для выполнения тестирования библиотеки. Позволяет запустить матричную сборку на Windows, Ubuntu и macOS на нескольких версиях движка OneScript. Поддерживается запуск из ветки, из pull request и ручной запуск из информации о конкретном workflow.

Файл workflow: [https://github.com/autumn-library/workflows/blob/main/.github/workflows/test.yml](https://github.com/autumn-library/workflows/blob/main/.github/workflows/test.yml)

Параметры:

| Имя параметра | Описание | Значение по умолчанию |
| --- | --- | --- |
| **oscript_version** | Версия движка в формате алиаса для https://github.com/oscript-library/ovm |  |
| test_script_path | Путь к скрипту запуска тестов | ./tasks/test.os |

### Использование

1) Запуск на нескольких версиях oscript в режиме матричной сборки

```yaml
name: Тестирование

on:
  push:
  pull_request:
  workflow_dispatch:

jobs:
  test:
    strategy:
      fail-fast: false
      matrix:
        oscript_version: ['1.8.4', 'stable', 'dev']
    uses: autumn-library/workflows/.github/workflows/test.yml@v1
    with:
      oscript_version: ${{ matrix.oscript_version }}
```

Данный пример запустит задачу на трех операционных системах с тремя разными версиями oscript - 1.8.4, последней релизной версии и последней ночной сборке.

2) Запуск на единственной версии оскрипта можно проводить как в режиме матричной сборки, указав только одно значение в oscript_version, так и с помощью облегчённой сборочной линии:

```yaml
name: Тестирование

on:
  push:
  pull_request:
  workflow_dispatch:

jobs:
  test:
    uses: autumn-library/workflows/.github/workflows/test.yml@v1
    with:
      oscript_version: stable
```
