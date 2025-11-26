# workflows

Набор типовых сборочных линий GitHub Actions для библиотек и приложений OneScript.

Во всех сборочных линиях используется локальная установка пакетов opm через `opm install --local`.  
Убедитесь, что рядом со скриптами запуска тестов (для `1testrunner`) или в каталоге тестов (для `OneUnit`) лежат файлы oscript.cfg с соответствующими настройками.  
Например, содержимое `oscript.cfg`, расположенного в каталоге `tasks`/`tests`:

```ini
lib.system=../oscript_modules
```

В репозитории есть теги и гарантируется обратная совместимость в пределах мажорной версии.  
Для оперативного получения новых фич нацеливайтесь на `@main`, для стабильных версий workflow - на последний мажорный тег - в данный момент `@v1`.

Для автообновления версий workflow рекомендуется использовать dependabot.  
Пример в репозитории autumn-library/annotations по [ссылке](https://github.com/autumn-library/annotations/blob/master/.github/dependabot.yml).

- [workflows](#workflows)
  - [Тестирование](#тестирование)
    - [Использование](#использование)
  - [Контроль качества (SonarQube + Coveralls)](#контроль-качества-sonarqube--coveralls)
    - [Использование](#использование-1)
  - [Публикация релиза](#публикация-релиза)
    - [Использование](#использование-2)

## Тестирование

Сборочная линия для выполнения тестирования библиотеки. Позволяет запустить матричную сборку на настраиваемом списке операционных систем (по умолчанию Windows, Ubuntu и macOS) на нескольких версиях движка OneScript. Поддерживается запуск из ветки, из pull request и ручной запуск из информации о конкретном workflow.

Файл workflow: [https://github.com/autumn-library/workflows/blob/main/.github/workflows/test.yml](https://github.com/autumn-library/workflows/blob/main/.github/workflows/test.yml)

Общие параметры:

| Имя параметра               | Описание                                                                                                                                                                                                                                                                                        | Значение по умолчанию                                 |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------- |
| oscript_version             | Версия движка в формате алиаса для [ovm](https://github.com/oscript-library/ovm). <br> Если имеет значение `default`, производится попытка вычисления версии среды на основании вызова метода ВерсияСреды() в packagedef. <br> Если вычислить версию не получается, используется версия stable. | `default`                                             |
| opm_version                 | Версия opm для установки (например, `1.1.0`). <br> Если не указано, устанавливается последняя версия без указания конкретной версии. <br> Используется для обеспечения совместимости с определенными версиями OneScript                                                                         |                                                       |
| additional_oscript_packages | Список дополнительных пакетов oscript для установки, разделенный пробелами                                                                                                                                                                                                                      |                                                       |
| dotnet_version              | Версия .NET для установки                                                                                                                                                                                                                                                                       |                                                       |
| build_package               | Выполнить сборку пакета перед выполнением тестов                                                                                                                                                                                                                                                | `false`                                               |
| os_versions                 | Список операционных систем для запуска тестов строкой в формате json-array                                                                                                                                                                                                                      | `["ubuntu-latest", "windows-latest", "macos-latest"]` |
| test_engine                 | Фреймворк который будет использован для тестирования, может быть одним из `1testrunner`, `oneunit`                                                                                                                                                                                              | `1testrunner`                                         |

Параметры для `1testrunner`

| Имя параметра    | Описание                      | Значение по умолчанию |
| ---------------- | ----------------------------- | --------------------- |
| test_script_path | Путь к скрипту запуска тестов | `./tasks/test.os`     |

Параметры для `OneUnit`

| Имя параметра        | Описание                                                                                | Значение по умолчанию |
| -------------------- | --------------------------------------------------------------------------------------- | --------------------- |
| oneunit_version      | Версия OneUnit в формате `0.3.0` которая будет установлена для проведения тестирования  |                       |
| test_dir_paths       | Пути к каталогам с тестами, разделённые запятыми, `tests, perf_tests`                   |                       |
| test_file_paths      | Пути к файлам тестов, разделённые запятыми, `Тест.os, Тест2.os`                         |                       |
| test_tags            | Список тегов для запуска, разделённые запятыми, `Повторяемый, Параметризованный`        |                       |
| test_default_timeout | Таймаут для выполнения каждого отдельного теста по умолчанию                            | `0` (неограниченно)   |
| test_log_mod         | Режим вывода логов тестирования                                                         | `tree`                |

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

Данный пример запустит задачу тестирования на операционных системах по умолчанию: Windows, Ubuntu и macOS. 
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

3) Запуск тестирования на определенных операционных системах

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
      os_versions: '["ubuntu-latest", "windows-latest"]'
```

Данный пример запустит задачу тестирования только на Ubuntu и Windows, исключив macOS.

4) Запуск тестирования только на одной операционной системе

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
      os_versions: '["ubuntu-latest"]'
```

Данный пример запустит задачу тестирования только на Ubuntu.

5) Запуск с совместимой версией OPM для старых версий OneScript

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
      oscript_version: "1.8.3"  # Старая версия OneScript
      opm_version: "1.1.0"     # Совместимая версия OPM
      os_versions: '["ubuntu-latest"]'
```

Данный пример запустит тестирование на Ubuntu с OneScript 1.8.3 и совместимой версией OPM 1.1.0 вместо последней версии, которая может требовать OneScript 1.8.4+.

6) Запуск тестов для разных версий OneScript с разными фреймворками тестирования

```yaml
name: Тестирование

on:
  push:
  pull_request:
  workflow_dispatch:

jobs:
  test:
    strategy:
      matrix:
        # Для 1.x запускаем 1testrunner
        oscript_version: ['default', 'lts-dev']
        test_engine: ['1testrunner']
        # Добавим тестирование на 2.0 с помощью OneUnit
        include:
          - oscript_version: 'dev'
            test_engine: 'oneunit'
    uses: autumn-library/workflows/.github/workflows/test.yml@main
    with:
      oscript_version: ${{ matrix.oscript_version }}
      test_engine: ${{ matrix.test_engine }}
```

В данном примере будет запущено тестирование на версиях OneScript `default` и `lts-dev` фреймворком `1testrunner`, а для версии `dev` фреймворком `OneUnit`

## Контроль качества (SonarQube + Coveralls)

Сборочная линия для выполнения анализа качества кода с помощью SonarQube и отправки данных о покрытии в [coveralls](https://coveralls.io).  
Поддерживается запуск из ветки, из pull request и ручной запуск из информации о конкретном workflow.  
> Анализ pull request из форков для задачи SonarQube пока не поддерживается.

Файл workflow: [https://github.com/autumn-library/workflows/blob/main/.github/workflows/sonar.yml](https://github.com/autumn-library/workflows/blob/main/.github/workflows/sonar.yml)

Параметры:

| Имя параметра               | Описание                                                                                                                                                                                                                                                                                         | Значение по умолчанию      |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------- |
| **github_repository**       | Репозиторий проекта в GitHub, для которого будет выполняться анализ, в формате `имя_владельца/название`                                                                                                                                                                                          |                            |
| oscript_version             | Версия движка в формате алиаса для [ovm](https://github.com/oscript-library/ovm). Если имеет значение `default`, производится попытка вычисления версии среды на основании вызова метода `ВерсияСреды()` в `packagedef`. <br> Если вычислить версию не получается, используется версия `stable`. | `default`                  |
| opm_version                 | Версия opm для установки (например, `1.1.0`). <br> Если не указано, устанавливается последняя версия без указания конкретной версии. <br> Используется для обеспечения совместимости с определенными версиями OneScript                                                                          |                            |
| additional_oscript_packages | Список дополнительных пакетов oscript для установки, разделенный пробелами                                                                                                                                                                                                                       |                            |
| sonar_host_url              | URL сервера SonarQube                                                                                                                                                                                                                                                                            | `https://sonar.openbsl.ru` |
| sonarqube                   | Флаг отправки результатов анализа на сервер SonarQube                                                                                                                                                                                                                                            | `true`                     |
| coveralls                   | Флаг отправки результатов покрытия на портал [coveralls](https://coveralls.io)                                                                                                                                                                                                                   | `false`                    |
| dotnet_version              | Версия .NET для установки                                                                                                                                                                                                                                                                        |                            |
| build_package               | Выполнить сборку пакета перед выполнением тестов                                                                                                                                                                                                                                                 | `false`                    |
| os_version                  | Операционная система для запуска контроля качества                                                                                                                                                                                                                                               | `ubuntu-latest`            |
| test_engine                 | Фреймворк который будет использован для тестирования, может быть одним из `1testrunner`, `oneunit`                                                                                                                                                                                               | `1testrunner`              |

Параметры для `1testrunner`

| Имя параметра    | Описание                      | Значение по умолчанию |
| ---------------- | ----------------------------- | --------------------- |
| test_script_path | Путь к скрипту запуска тестов | `./tasks/coverage.os`     |

Параметры для `OneUnit`

| Имя параметра        | Описание                                                                                | Значение по умолчанию |
| -------------------- | --------------------------------------------------------------------------------------- | --------------------- |
| oneunit_version      | Версия OneUnit в формате `0.3.0` которая будет установлена для проведения тестирования  |                       |
| test_dir_paths       | Пути к каталогам с тестами, разделённые запятыми, `tests, perf_tests`                   |                       |
| test_file_paths      | Пути к файлам тестов, разделённые запятыми, `Тест.os, Тест2.os`                         |                       |
| test_tags            | Список тегов для запуска, разделённые запятыми, `Повторяемый, Параметризованный`        |                       |
| test_default_timeout | Таймаут для выполнения каждого отдельного теста по умолчанию                            | `0` (неограниченно)   |
| test_log_mod         | Режим вывода логов тестирования                                                         | `tree`                |

Секреты:

| Имя секрета | Описание                                   | Обязательный |
| ----------- | ------------------------------------------ | ------------ |
| SONAR_TOKEN | Токен для авторизации на сервере SonarQube | Нет          |

### Использование

Для использования сборочной линии необходимо предварительно подготовить файл `sonar-project.properties` и расположить его в корне проекта.  
Сборочная линия ожидает, что в репозитории есть скрипт `tasks/coverage.os` (для фреймворка `1testrunner` или ничего не ожидает для фреймворка `OneUnit`), с помощью которого запускаются тесты со сбором покрытия, однако это можно переопределить.  
Если ваш сервер SonarQube требует авторизацию, то необходимо передать в workflow секрет `SONAR_TOKEN`.

```yaml
# С тестированием 1testrunner
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

```yaml
# С тестированием OneUnit
name: Контроль качества

on:
  push:
  pull_request:
  workflow_dispatch:

jobs:
  sonar:
    uses: autumn-library/workflows/.github/workflows/sonar.yml@main
    with:
      sonarqube: true
      github_repository: autumn-library/annotations # change me!
      oscript_version: 'dev'
      test_engine: 'oneunit'
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
| opm_version           | Версия opm для установки (например, "1.1.0"). Если не указано, устанавливается последняя версия без указания конкретной версии. Используется для обеспечения совместимости с определенными версиями OneScript |  |
| package_mask      | Файловая маска собранного пакета. Несмотря на необязательность параметра, рекомендуется его передавать до исправления ошибки в шаге публикации в хаб | *.ospx |
| dotnet_version        | Версия .NET для установки                                                                               |                                                                                         |
| os_version            | Операционная система для запуска релиза                                                                | ubuntu-latest                                                                           |

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
