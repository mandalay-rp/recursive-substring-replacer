# replace.sh

Read this in [Russian](README.ru.md)

A Bash script for **recursive string replacement** inside text files within a directory.

- Replaces a literal substring (all regex metacharacters are escaped automatically)
- Skips binary and empty files
- Leaves untouched any file without matches (fast pre-check via `grep -F`)
- Supports dry-run, backups, first-occurrence-only replacement, and case-insensitive mode
- Works with GNU sed (Linux) and BSD sed (macOS)
- Excludes `.git` by default

## Requirements

- `bash` 4+
- `find`, `grep` (GNU or BSD)
- `sed` (GNU or BSD)
- The `-i` flag (case-insensitive) requires **GNU sed**

## Installation

```bash
git clone <repo-url> replace
cd replace
chmod +x replace.sh
```

Or just copy `replace.sh` somewhere convenient and make it executable:

```bash
chmod +x replace.sh
```

## Usage

```bash
./replace.sh [-d DIR] [-n] [-b] [-f] [-i] "what" "with what"
```

| Option | Description |
|--------|-------------|
| `-d DIR` | Directory to process (default: current) |
| `-n` | Dry-run: only show files that would be changed |
| `-b` | Keep backup copies next to each file (`.bak` suffix) |
| `-f` | Replace only the first occurrence per file (default: all) |
| `-i` | Case-insensitive search (requires GNU sed) |
| `-h` | Show help |

## Examples

Dry run — preview what would be changed:

```bash
./replace.sh -n -d ./src "foo" "bar"
```

Replace with `.bak` backups:

```bash
./replace.sh -b -d ./src "foo" "bar"
```

Replace only the first occurrence per file:

```bash
./replace.sh -f -d ./src "foo" "bar"
```

Case-insensitive (GNU sed):

```bash
./replace.sh -i -d ./docs "hello" "world"
```

## How it works

1. The search string is treated as **literal**: characters like `\ . * [ ] ^ $ /` are escaped.
2. In the replacement string, `\`, `/`, and `&` are escaped.
3. Each file is pre-checked with `grep -F`:
   - binary and empty files are skipped;
   - files without matches are not rewritten.
4. The replacement is done via `sed -i` with automatic GNU/BSD syntax detection.
5. On completion, a summary is printed: how many files were changed and skipped.

## Limitations

- Only a **single literal substring** is supported — regular expressions are not.
- Binary files are never modified.
- The `.git` directory is excluded; you can add more exclusions (e.g. `node_modules`) in the `find` call inside the script.
- The `-i` flag (case-insensitive) is not supported on BSD sed (macOS).

## License

MIT (or your own).
