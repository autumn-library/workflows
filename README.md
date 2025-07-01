# workflows

Набор типовых сборочных линий GitHub Actions для библиотек и приложений OneScript.

Во всех сборочных линиях используется локальная установка пакетов opm через `opm install --local`. Убедитесь, что рядом со скриптами запуска тестов лежат файлы oscript.cfg с соответствующими настройками. 
Например, содержимое `oscript.cfg`, расположенного в каталоге `tasks`:

```ini
lib.system=../oscript_modules
```

В репозитории есть теги и гарантируется обратная совместимость в пределах мажорной версии. 
Для оперативного получения новых фич нацеливайтесь на `@main`, для стабильных версий workflow - на последний мажорный тег - в данный момент `@v1`.

Для автообновления версий workflow рекомендуется использовать dependabot. Пример в репозитории autumn-library/annotations по [ссылке](https://github.com/autumn-library/annotations/blob/master/.github/dependabot.yml).

- [workflows](#workflows)
  - [Тестирование](#тестирование)
    - [Использование](#использование)
  - [Контроль качества (SonarQube + Coveralls)](#контроль-качества-sonarqube--coveralls)
    - [Использование](#использование-1)
  - [Публикация релиза](#публикация-релиза)
    - [Использование](#использование-2)

## Тестирование

Сборочная линия для выполнения тестирования библиотеки. Позволяет запустить матричную сборку на Windows, Ubuntu и macOS на нескольких версиях движка OneScript. Поддерживается запуск из ветки, из pull request и ручной запуск из информации о конкретном workflow.

Файл workflow: [https://github.com/autumn-library/workflows/blob/main/.github/workflows/test.yml](https://github.com/autumn-library/workflows/blob/main/.github/workflows/test.yml)

Параметры:

| Имя параметра               | Описание                                                                                                                                                                                                                                                                       | Значение по умолчанию |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------- |
| oscript_version             | Версия движка в формате алиаса для https://github.com/oscript-library/ovm. Если имеет значение `default`, производится попытка вычисления версии среды на основании вызова метода ВерсияСреды() в packagedef. Если вычислить версию не получается, используется версия stable. | default               |
| test_script_path            | Путь к скрипту запуска тестов                                                                                                                                                                                                                                                  | ./tasks/test.os       |
| additional_oscript_packages | Список дополнительных пакетов oscript для установки, разделенный пробелами                                                                                                                                                                                                     |                       |
| dotnet_version              | Версия .NET для установки                                                                                                                                                                                                                                                      |                       |

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
        oscript_version: ['default', 'stable', 'dev']
    uses: autumn-library/workflows/.github/workflows/test.yml@v1
    with:
      oscript_version: ${{ matrix.oscript_version }}
```

Данный пример запустит задачу на трех операционных системах с тремя разными версиями oscript - 1.8.4 (так как она указана в packagedef), последней релизной версии и последней ночной сборке.

## Контроль качества (SonarQube + Coveralls)

Сборочная линия для выполнения анализа качества кода с помощью SonarQube и отправки данных о покрытии в [coveralls](https://coveralls.io). Поддерживается запуск из ветки, из pull request и ручной запуск из информации о конкретном workflow. Анализ pull request из форков для задачи SonarQube пока не поддерживается.

Файл workflow: [https://github.com/autumn-library/workflows/blob/main/.github/workflows/sonar.yml](https://github.com/autumn-library/workflows/blob/main/.github/workflows/sonar.yml)

Параметры:

| Имя параметра               | Описание                                                                                                                                                                                                                                                                       | Значение по умолчанию    |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------ |
| **github_repository**       | Репозиторий проекта в GitHub, для которого будет выполняться анализ, в формате "имя_владельца/название"                                                                                                                                                                        |                          |
| oscript_version             | Версия движка в формате алиаса для https://github.com/oscript-library/ovm. Если имеет значение `default`, производится попытка вычисления версии среды на основании вызова метода ВерсияСреды() в packagedef. Если вычислить версию не получается, используется версия stable. | default                  |
| test_script_path            | Путь к скрипту запуска тестов                                                                                                                                                                                                                                                  | ./tasks/coverage.os      |
| additional_oscript_packages | Список дополнительных пакетов oscript для установки, разделенный пробелами                                                                                                                                                                                                     |                          |
| sonar_host_url              | URL сервера SonarQube                                                                                                                                                                                                                                                          | https://sonar.openbsl.ru |
| sonarqube                   | Флаг отправки результатов анализа на сервер SonarQube                                                                                                                                                                                                                          | true                     |
| coveralls                   | Флаг отправки результатов покрытия на портал [coveralls](https://coveralls.io)                                                                                                                                                                                                 | false                    |
| dotnet_version              | Версия .NET для установки                                                                                                                                                                                                                                                      |                          |

Секреты:

| Имя секрета | Описание                                   | Обязательный |
| ----------- | ------------------------------------------ | ------------ |
| SONAR_TOKEN | Токен для авторизации на сервере SonarQube | Нет          |

### Использование

Для использования сборочной линии необходимо предварительно подготовить файл `sonar-project.properties` и расположить его в корне проекта. Сборочная линия ожидает, что в репозитории есть скрипт `tasks/coverage.os`, с помощью которого запускаются тесты со сбором покрытия, однако это можно переопределить. Если ваш сервер SonarQube требует авторизацию, то необходимо передать в workflow секрет `SONAR_TOKEN`.

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

### Отключение анализа SonarQube

По умолчанию анализ SonarQube включён, однако это можно изменить, выставив свойство `sonarqube: false`.

### Интеграция с Coveralls

Перед выполнением первого анализа добавьте свой проект в сервис [coveralls](https://coveralls.io). Выставьте флаг `coveralls: true` и дождитесь результатов анализа.

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
      coveralls: true
    secrets:
      SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

## Публикация релиза

Сборочная линия для сборки и публикации пакета библиотеки в артефакты и хаб пакетов https://hub.oscript.io. Поддерживается автоматический запуск при публикации GitHub Release и ручной запуск из информации о конкретном workflow.

Файл workflow: [https://github.com/autumn-library/workflows/blob/main/.github/workflows/release.yml](https://github.com/autumn-library/workflows/blob/main/.github/workflows/release.yml)

Параметры:

| Имя параметра         | Описание                                                                                                | Значение по умолчанию                                                                   |
| --------------------- | ------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| oscript_version       | Версия движка в формате алиаса для https://github.com/oscript-library/ovm. Если имеет значение `default`, производится попытка вычисления версии среды на основании вызова метода ВерсияСреды() в packagedef. Если вычислить версию не получается, используется версия stable. | default |
| package_mask      | Файловая маска собранного пакета. Несмотря на необязательность параметра, рекомендуется его передавать до исправления ошибки в шаге публикации в хаб | *.ospx |
| dotnet_version        | Версия .NET для установки                                                                               |                                                                                         |

Секреты:

| Имя секрета | Описание                                      | Обязательный |
| ----------- | --------------------------------------------- | ------------ |
| PUSH_TOKEN  | GitHub токен для публикации релизов в хаб opm | Нет          |

### Использование

Для использования сборочной линии необходимо создать новый релиз на вкладке GitHub Releases. Если ваш хаб пакетов использует токен для проверки прав на публикацию (hub.oscript.io использует), то необходимо передать в workflow секрет `PUSH_TOKEN`.

```yaml
name: Публикация релиза

on:
  release:
    types:
      - published
  workflow_dispatch:

jobs:
  release:
    uses: autumn-library/workflows/.github/workflows/release.yml@v1
    with:
      package_mask: "annotations-*.ospx" # change me!
    secrets:
      PUSH_TOKEN: ${{ secrets.PUSH_TOKEN }}
```
