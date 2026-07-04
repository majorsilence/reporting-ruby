# Majorsilence Reporting — Ruby Wrappers

Three wrappers are provided for generating reports from Ruby. Pick the one that matches how you deploy the reporting engine:

| Wrapper | Mechanism | Requires |
|---|---|---|
| `Report` | subprocess → RdlCmd (.NET DLL) | .NET runtime on the host |
| `ReportAot` | subprocess → RdlCmd (self-contained or AOT binary) | nothing extra |
| `ReportNative` | in-process Fiddle FFI → rdlnative shared library | nothing extra |

**Ruby 3.0 or later** is recommended (`# frozen_string_literal: true` is used throughout; `Fiddle` is part of the standard library).

---

## Installation

Install from [RubyGems](https://rubygems.org/gems/majorsilence_reporting):

```bash
gem install majorsilence_reporting
```

Or add it to your `Gemfile`:

```ruby
gem 'majorsilence_reporting'
```

The gem itself has no runtime dependencies -- it uses the Ruby standard library only (`fiddle`, `fileutils`, `tempfile`). You still need one of the RdlCmd/rdlnative artifacts described below, matching the wrapper you choose.

---

## Setup

### Install Ruby

- **Linux (Debian/Ubuntu):**
  ```bash
  sudo apt-get update && sudo apt-get install -y ruby
  ruby --version
  ```
- **macOS** (via Homebrew):
  ```bash
  brew install ruby
  ruby --version
  ```
- **Windows** — download the installer from [rubyinstaller.org](https://rubyinstaller.org/) or use winget:
  ```powershell
  winget install RubyInstallerTeam.Ruby
  ruby --version
  ```

### Install dependencies

```bash
bundle install
```

This installs `minitest` (needed only for running the test suite). The three wrappers themselves have no gem dependencies — they use the Ruby standard library only (`fiddle`, `fileutils`, `tempfile`).

### Use without Bundler

```ruby
$LOAD_PATH.unshift '/path/to/reporting-ruby/lib'
require 'majorsilence_reporting'       # loads all three wrappers
# or load individually:
require 'majorsilence_reporting/report'
require 'majorsilence_reporting/report_aot'
require 'majorsilence_reporting/report_native'
```

---

## Option 1 — `Report` (subprocess, .NET runtime required)

Use this when you have the .NET runtime installed on the host and want to run `RdlCmd.dll` through `dotnet`.

```ruby
require 'majorsilence_reporting/report'

rpt = Report.new(
  '/path/to/report.rdl',
  '/path/to/RdlCmd.dll',
  'dotnet'                 # path_to_dotnet — omit when using a native exe on Windows
)
rpt.set_connection_string('Data Source=/path/to/northwindEF.db')
rpt.set_parameter('Country', 'Germany')

# Export to a file
rpt.export('pdf', '/tmp/output.pdf')

# Export to memory (binary String for pdf/tif/rtf; UTF-8 String for text formats)
data = rpt.export_to_memory('pdf')
```

### Windows

```ruby
rpt = Report.new(
  'C:\reports\report.rdl',
  'C:\RdlCmd\RdlCmd.exe'
)
```

---

## Option 2 — `ReportAot` (subprocess, no runtime required)

Use this with an AOT-compiled or self-contained RdlCmd binary. No `path_to_dotnet` argument — the binary runs directly.

Download the appropriate binary from the release:
- `majorsilence-reporting-rdlcmd-aot-linux.zip` → `linux-x64/` or `linux-arm64/`
- `majorsilence-reporting-rdlcmd-aot-osx.zip` → `osx-x64/` or `osx-arm64/`
- `majorsilence-reporting-rdlcmd-aot-windows.zip` → `win-x64/` or `win-arm64/`

Or use the self-contained (non-AOT) build from `majorsilence-reporting-rdlcmd-self-contained.zip`.

```ruby
require 'majorsilence_reporting/report_aot'

rpt = ReportAot.new(
  '/path/to/report.rdl',
  '/path/to/RdlCmd'   # RdlCmd.exe on Windows
)
rpt.set_connection_string('Data Source=/path/to/northwindEF.db')
rpt.set_parameter('Country', 'Germany')

rpt.export('pdf', '/tmp/output.pdf')
data = rpt.export_to_memory('xlsx')
```

On Linux/macOS, make the binary executable:

```bash
chmod +x /path/to/RdlCmd
```

---

## Option 3 — `ReportNative` (in-process Fiddle FFI, no subprocess)

Use this for the lowest overhead: the reporting engine runs inside the Ruby process via `Fiddle`. No subprocess is spawned, no .NET runtime is required.

Download the native shared library from the release (`majorsilence-reporting-rdlnative-linux.zip`, `-osx.zip`, or `-windows.zip`) and extract it. The directory will contain the shared library and all its sibling libraries.

| Platform | Library filename |
|---|---|
| Linux | `librdlnative.so` |
| macOS | `librdlnative.dylib` |
| Windows | `rdlnative.dll` |

```ruby
require 'majorsilence_reporting/report_native'

# Load once per process — pass the full path to the shared library.
lib = RdlLibrary.load('/path/to/librdlnative.so')

rpt = ReportNative.new(lib, '/path/to/report.rdl')
rpt.set_connection_string('Data Source=/path/to/northwindEF.db')
rpt.set_parameter('Country', 'Germany')

# Export to a file
rpt.export('pdf', '/tmp/output.pdf')

# Export to memory — returns a binary String
data = rpt.export_to_memory('pdf')
```

On Linux, pre-load the library directory before starting Ruby:

```bash
export LD_LIBRARY_PATH=/path/to/rdlnative-dir:$LD_LIBRARY_PATH
ruby your_script.rb
```

---

## Supported export formats

| Format | Description | `Report` | `ReportAot` / `ReportNative` |
|---|---|---|---|
| `pdf` | PDF (default) | ✓ | ✓ |
| `csv` | Comma-separated values | ✓ | ✓ |
| `xlsx` | Excel workbook | ✓ | ✓ |
| `xlsx_table` | Excel workbook (table style) | | ✓ |
| `xml` | XML | ✓ | ✓ |
| `rtf` | Rich Text Format | ✓ | ✓ |
| `tif` | TIFF image | ✓ | ✓ |
| `tifb` | TIFF image (black & white) | | ✓ |
| `html` | HTML | ✓ | ✓ |
| `mht` | MHTML | | ✓ |

An unrecognised format string defaults to `pdf`.

---

## Running the tests

The test suite (`test/test_report_native.rb`) covers `ReportNative`. It uses Minitest and requires a published `rdlnative` shared library; tests are skipped automatically if `RDLNATIVE_LIB` is not set.

```bash
# Build the native library first (from the main Reporting repo)
dotnet publish RdlNative -c Release-DrawingCompat -r linux-x64 -f net10.0 \
    --self-contained true -p:PublishAot=true \
    -o /tmp/rdlnative-pub

# Run tests (set REPORTING_REPO_ROOT to the Reporting repo clone)
RDLNATIVE_LIB=/tmp/rdlnative-pub/librdlnative.so \
REPORTING_REPO_ROOT=/path/to/Reporting \
    ruby test/test_report_native.rb
```

On macOS replace `linux-x64` with `osx-arm64` (or `osx-x64`) and `librdlnative.so` with `librdlnative.dylib`.

---

## Examples

See the `Examples/` subdirectory for runnable scripts:

- `test1.rb` — basic PDF export to file
- `test2-parameters.rb` — passing report parameters
- `test3-streaming.rb` — exporting to memory for streaming responses
- `test4-export-multiple-formats.rb` — exporting the same report to several formats
- `test5-set-data-from-code.rb` — supplying dataset rows from code instead of a database

---

## Releasing (maintainers)

Releases are published to [RubyGems](https://rubygems.org/gems/majorsilence_reporting) by `.github/workflows/publish.yml` using [Trusted Publishing](https://guides.rubygems.org/trusted-publishing/) (OIDC) -- no API key is stored in this repo.

One-time setup on rubygems.org, under Profile -> Trusted publishers (or "Pending trusted publishers" before the gem's first release):

| Field | Value |
|---|---|
| Gem name | `majorsilence_reporting` |
| Repository owner | `majorsilence` |
| Repository name | `reporting-ruby` |
| Workflow filename | `publish.yml` |
| Environment | `release` |

To cut a release:

```bash
# Bump the version
$EDITOR lib/majorsilence_reporting/version.rb

git commit -am "Release vX.Y.Z"
git tag vX.Y.Z
git push origin main --tags
```

Pushing the `vX.Y.Z` tag triggers the workflow, which runs the test suite and then uses [`rubygems/release-gem`](https://github.com/rubygems/release-gem) to build and push the gem.
