# GitHub Actions Workflows for OneScript Libraries

This repository contains a collection of reusable GitHub Actions workflows designed for OneScript libraries and applications. The workflows provide standardized build, test, and deployment processes.

**ALWAYS reference these instructions first and fallback to search or bash commands only when you encounter unexpected information that does not match the information here.**

## Working Effectively

### Repository Structure and Purpose
- This repository contains ONLY reusable GitHub Actions workflows (`.github/workflows/*.yml`)
- All workflows use `workflow_call` trigger - they are designed to be called by other repositories
- NO builds, tests, or application code exist in this repository itself
- The workflows are used by OneScript libraries like `autumn-library/annotations`

### Validation Commands
- **YAML Linting**: `yamllint .github/workflows/*.yml` - validates workflow syntax (expect style warnings about line length and whitespace, but no syntax errors)
- **Workflow Structure Check**: `grep -n "workflow_call" .github/workflows/*.yml` - confirms all workflows are reusable
- **No Build Required**: This repository does not require building, testing, or running any application code
- **No Tests to Run**: There are no unit tests or integration tests in this repository  
- **NEVER try to run**: `opm install`, `oscript`, `npm install`, `dotnet build`, or similar build commands - they are not applicable
- **Expected yamllint output**: Warnings about document-start, line-length, trailing-spaces are normal and acceptable

### Workflow Types Available
1. **Testing** (`.github/workflows/test.yml`): Matrix testing on Windows, Ubuntu, macOS with multiple OneScript versions
2. **Quality Control** (`.github/workflows/sonar.yml`): SonarQube analysis and Coveralls coverage reporting  
3. **Release** (`.github/workflows/release.yml`): Package building and publishing to oscript hub
4. **Documentation** (`.github/workflows/deploy-docs.yml`): Documentation deployment trigger

### Timing Expectations - CRITICAL
**NEVER CANCEL BUILDS OR TESTS** in workflows that use these:
- OneScript installation: 2-5 minutes
- `opm install -l --dev`: 5-15 minutes depending on dependencies
- Test execution: 5-30 minutes depending on test suite size
- SonarQube analysis: 10-20 minutes
- Package builds: 2-10 minutes
- **ALWAYS set timeouts to 60+ minutes** for any workflow job that runs these operations

## Common Workflow Usage Patterns

### Example Repository Structure (e.g., autumn-library/annotations)
```
packagedef              # OneScript package definition with ВерсияСреды()
tasks/
  ├── test.os           # Test execution script  
  ├── coverage.os       # Coverage collection script
  └── oscript.cfg       # lib.additional=../oscript_modules
.github/workflows/
  ├── test.yml          # Uses: autumn-library/workflows/.github/workflows/test.yml@v1
  ├── sonar.yml         # Uses: autumn-library/workflows/.github/workflows/sonar.yml@v1
  └── release.yml       # Uses: autumn-library/workflows/.github/workflows/release.yml@v1
```

### Typical Workflow Implementation
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
      oscript_version: default
      os_versions: '["ubuntu-latest", "windows-latest", "macos-latest"]'
```

## Validation Scenarios

### When Making Changes to Workflows
1. **YAML Syntax**: Always run `yamllint .github/workflows/*.yml` and fix any syntax errors (style warnings are acceptable)
2. **Test in Real Repository**: Create a test branch in `autumn-library/annotations` and update workflow reference to test changes
3. **Verify Matrix Builds**: Ensure workflows run successfully on all target OS platforms (Windows, Ubuntu, macOS)
4. **Check OneScript Versions**: Test with `default`, `stable`, and `dev` OneScript versions
5. **Manual Testing Scenarios**:
   - Run `opm install -l --dev` to install dependencies
   - Execute `oscript tasks/test.os` to run tests
   - Verify `oscript tasks/coverage.os` generates coverage reports
   - Check package builds with `opm build .`

### Critical Validation Requirements
- **NEVER CANCEL** long-running operations - OneScript builds can take 30+ minutes
- **Test Timeout Settings**: Always verify timeout values are 60+ minutes for build steps
- **Cross-Platform Compatibility**: Test workflows on Windows, Ubuntu, and macOS
- **Dependency Installation**: Verify `opm install -l --dev` completes successfully

### Common Issues and Solutions
1. **"File not found: tasks/test.os"**: Consumer repository needs to create test scripts in tasks/ directory
2. **"ВерсияСреды method not found"**: packagedef must include `.ВерсияСреды("version")` call for `oscript_version: default`
3. **"Permission denied: hub.oscript.io"**: Release workflow needs `PUSH_TOKEN` secret for package publishing
4. **Long build times**: Expected behavior - OneScript dependency installation takes 15-30 minutes, NEVER cancel
5. **Matrix build failures**: Check OS-specific paths and line endings, verify OneScript version compatibility

### Testing Workflow Changes
1. **Local YAML validation**: `yamllint .github/workflows/test.yml` (fix syntax errors, ignore style warnings)
2. **Reference test repository**: Use `autumn-library/annotations` or similar for end-to-end testing
3. **Version testing strategy**:
   ```yaml
   # Test with your branch first
   uses: your-username/workflows/.github/workflows/test.yml@your-branch
   # Then test with main
   uses: autumn-library/workflows/.github/workflows/test.yml@main
   ```

## Key Workflow Parameters

### Universal Parameters (All Workflows)
- `oscript_version`: OneScript version (`default`, `stable`, `dev`, or specific version)
- `additional_oscript_packages`: Space-separated list of extra packages to install
- `dotnet_version`: .NET version for mixed-language projects
- `build_package`: Whether to run `opm build .` before tests

### Test Workflow Specific
- `test_script_path`: Path to test script (default: `./tasks/test.os`)
- `os_versions`: JSON array of OS versions (default: `["ubuntu-latest", "windows-latest", "macos-latest"]`)

### Quality Control Workflow Specific  
- `github_repository`: Required - repository name in "owner/name" format
- `test_script_path`: Coverage script path (default: `./tasks/coverage.os`)
- `sonar_host_url`: SonarQube server URL (default: `https://sonar.openbsl.ru`)
- `sonarqube`: Enable/disable SonarQube analysis (default: `true`)
- `coveralls`: Enable/disable Coveralls reporting (default: `false`)

### Release Workflow Specific
- `package_mask`: File pattern for built packages (default: `*.ospx`)

## Common File Locations and Content

### packagedef File Structure
```
Описание.Имя("package-name")
        .Версия("1.0.0")
        .ВерсияСреды("1.9.2")  // Used by workflows when oscript_version="default"
        .ВключитьФайл("src")
        .ВключитьФайл("tasks")
        .РазработкаЗависитОт("1testrunner")
        .РазработкаЗависитОт("coverage")
```

### tasks/oscript.cfg
```ini
lib.additional=../oscript_modules
```

### Required Test Scripts
- `tasks/test.os`: Basic test runner using 1testrunner
- `tasks/coverage.os`: Test runner with coverage collection using coverage package

## Dependabot Configuration
- Always include `.github/dependabot.yml` for automatic workflow updates
- Use `package-ecosystem: "github-actions"` to keep workflow versions current
- Target versioned releases (`@v1`) for stability, `@main` for latest features

## Version Strategy
- **Stable**: Use `@v1` tags for production repositories
- **Development**: Use `@main` for testing new features
- **Backward Compatibility**: Guaranteed within major versions
- **Updates**: Use dependabot for automatic version updates