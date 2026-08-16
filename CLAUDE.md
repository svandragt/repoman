# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single Bash script, `repoman.sh`, that exports a directory tree of git repositories to a plain-text list and clones that list back on another machine. `README.md` explains the motivation: syncing a list of repos beats syncing the working copies themselves.

There is no build, no dependency manager, and no test suite. The whole program is `repoman.sh`; `README.md` is the user-facing documentation and must be updated alongside any change to flags, output format, or invocation.

## Architecture

Two modes, `_export` and `_import`, dispatched by the block at the bottom of the file:

1. A first argument that is an existing file means import, tty or not.
2. Otherwise stdin attached to a tty means export.
3. Otherwise import from stdin.

Export walks `find . -type d -name '.git' -prune`, and prints one line per repo as `relative/path=remote-url`, where the path is relative to `INVOKE_DIR` (the working directory captured at line 2). Import parses each line on the first `=` and runs `git clone REMOTE PRJ_DIR`, so the export format is also the import format — changing one side means changing both.

Repos with no remote print as a bare path with no `=`. Those lines are informational only; import rejects them as invalid entries. `-n` produces nothing but such lines, and `-a` mixes them with cloneable ones.

Option parsing lives inside `_export`, so the dispatch has to route any argument starting with `-` to export before it consults the tty. Without that branch, `repoman.sh -n | grep x` treats `-n` as an input filename.

The export loop is the right-hand side of a pipe, so it runs in a subshell — variables set inside it do not survive, and `exit` there won't stop the script.

## Testing a change

No harness exists. Verify by hand, and note that export needs a real tty, which the agent shell does not provide — wrap the call in `script` to get a pty:

```bash
script -qec "bash /path/to/repoman.sh -a" /dev/null
```

Build a fixture with `git init` in a couple of subdirectories, giving only one of them an `origin` remote, then check all of: default export, `-n`, `-a`, import from a file argument, import from a pipe, and `-h`.

## Style

Indentation is tabs. Errors go to stderr and the loops `continue` past a bad entry rather than aborting the run.
