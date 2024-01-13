# workflows

Набор типовых сборочных линий GitHub Actions для библиотек и приложений OneScript.

Во всех сборочных линиях используется локальная установка пакетов opm через `opm install --local`. Убедитесь, что рядом со скриптами запуска тестов лежат файлы oscript.cfg с соответствующими настройками. 
Например, содержимое `oscript.cfg`, расположенного в каталоге `tasks`:

```ini
lib.system=../oscript_modules
```

В репозитории есть теги и гарантируется обратная совместимость в пределах мажорной версии. 
Для оперативного получения новых фич нацеливайтесь на `@main`, для стабильных версий workflow - на последний мажорный тег - в данный момент `@v1`.

Для автообновления версий workflow рекомендуется использовать dependabot. Пример в репозитории autumn-library/annotations: https://github.com/autumn-library/annotations/blob/test-oscript-version/.github/dependabot.yml

- [workflows](#workflows)
  - [Тестирование](#тестирование)
    - [Использование](#использование)
  - [Контроль качества (SonarQube)](#контроль-качества-sonarqube)
    - [Использование](#использование-1)

## Тестирование

Сборочная линия для выполнения тестирования библиотеки. Позволяет запустить матричную сборку на Windows, Ubuntu и macOS на нескольких версиях движка OneScript. Поддерживается запуск из ветки, из pull request и ручной запуск из информации о конкретном workflow.

Файл workflow: [https://github.com/autumn-library/workflows/blob/main/.github/workflows/test.yml](https://github.com/autumn-library/workflows/blob/main/.github/workflows/test.yml)

Параметры:

| Имя параметра    | Описание                                                                  | Значение по умолчанию                                                                   |
| ---------------- | ------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| oscript_version  | Версия движка в формате алиаса для https://github.com/oscript-library/ovm | Значение параметра метода ВерсияСреды в packagedef или `stable` в случае его отсутствия |
| test_script_path | Путь к скрипту запуска тестов                                             | ./tasks/test.os                                                                         |

### Использование

1) Запуск тестирования:

```yaml
name: Тестирование

on:
  push:
  pull_request:
  workflow_dispatch:

jobs:
  test:
    uses: autumn-library/workflows/.github/workflows/test.yml@v1
``` 

Данный пример запустит задачу тестирования на трех операционных системах: Windows, Ubuntu и macos. 
Если в файле packagedef вашей библиотеки есть вызов метода "ВерсияСреды", то будет взято значение из параметра метода. Если вызов ВерсияСреды отсутствует, то запуск тестирования будет проводиться на версии stable. 

При необходимости можно явно указать версию OneScript в параметре `oscript_version`:

```yaml
...
    uses: autumn-library/workflows/.github/workflows/test.yml@v1 
    with:
      oscript_version: dev
```

2) Запуск на нескольких версиях oscript в режиме матричной сборки

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

## Контроль качества (SonarQube)

Сборочная линия для выполнения анализа качества кода с помощью SonarQube. Поддерживается запуск из ветки, из pull request и ручной запуск из информации о конкретном workflow. Анализ pull request из форков пока не поддерживается.

Файл workflow: [https://github.com/autumn-library/workflows/blob/main/.github/workflows/sonar.yml](https://github.com/autumn-library/workflows/blob/main/.github/workflows/sonar.yml)

Параметры:

| Имя параметра         | Описание                                                                                                | Значение по умолчанию                                                                   |
| --------------------- | ------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| **github_repository** | Репозиторий проекта в GitHub, для которого будет выполняться анализ, в формате "имя_владельца/название" |                                                                                         |
| oscript_version       | Версия движка в формате алиаса для https://github.com/oscript-library/ovm                               | Значение параметра метода ВерсияСреды в packagedef или `stable` в случае его отсутствия |
| test_script_path      | Путь к скрипту запуска тестов                                                                           | ./tasks/coverage.os                                                                     |
| sonar_host_url        | URL сервера SonarQube                                                                                   | https://sonar.openbsl.ru                                                                |

Секреты:

| Имя секрета | Описание                                   | Обязательный |
| ----------- | ------------------------------------------ | ------------ |
| SONAR_TOKEN | Токен для авторизации на сервере SonarQube | Нет          |

### Использование


```yaml
name: Контроль качества

on:
  push:
  pull_request:
  workflow_dispatch:

jobs:
  sonar:
    uses: autumn-library/workflows/.github/workflows/sonar.yml@v1
    with:
      github_repository: autumn-library/annotations # change me!
    secrets:
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```
