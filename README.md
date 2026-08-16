# Repoman

Repoman is a script to export and import a list of git repositories.

> Use repoman to generate a list of - and clone - multiple repositories with one command.

It's very useful if you work with the same projects from multiple pcs (laptop/desktop for example). Syncing git projects via dropbox etc is fragile, instead sync the output of `repoman`.

## Usage

### Export Mode
When run without input, repoman scans the working directory for .git folders and echoes its relative path with the git remote. You can save this into a file.

Parameters:
- No parameter (default): Only list repositories that have a remote configured
- `-n`, `--no-remote`: Only list repositories that don't have a remote configured
- `-a`, `--all`: List all repositories (both with and without remotes)
- `-x`, `--exclude`: Skip repositories at the given path or below it. Repeat the option to exclude more than one.
- `-h`, `--help`: Show help information

The exclude pattern is a path relative to the working directory, and it can be a glob. Quote globs so the shell passes them through:

```bash
repoman.sh -x work -x 'tmp*' > repos.txt
```

### Import Mode
Pass a list as a file argument, or pipe it in, and Repoman clones the repositories into this directory structure:

```bash
repoman.sh repoman.lst
cat repoman.lst | repoman.sh
```

Lines without a remote (the output of `-n`, and part of the output of `-a`) can't be cloned. Repoman reports them as invalid entries and carries on.

## Why use this

It's bad practice to use cloud sync solutions to sync working copies (https://git.seveas.net/how-to-back-up-a-git-repository.html).

Repoman helps you work on the same projects on multiple devices, by syncing an intermediate file.


## Installation

There are two ways:

1. Only `repoman.sh` is needed. Save it into your path, so you can run it from any location. 
2. If you want to benefit from updates, clone this repository, and [create a symbolic link](https://duckduckgo.com/?t=ffab&q=create+symbolic+link&ia=web).

In either case, make the script executable via `chmod +x repoman.sh`.


## Examples

Export:
```bash
$ repoman.sh | tee repoman.lst
vagrant.local=https://github.com/Chassis/Chassis.git
vagrant.local/content/plugins/404-fallback=https://github.com/svandragt/404-fallback.git
Taskfile=git@github.com:svandragt/Taskfile.git
freshcookies=git@github.com:svandragt/freshcookies.git
repoman=https://github.com/svandragt/repoman.git

$ ls *.lst
repoman.lst
```

Import:

```bash
$ cat repoman.lst | repoman.sh

⏳ Cloning vagrant.local
Cloning into 'vagrant.local'...
remote: Enumerating objects: 1447, done.
remote: Counting objects: 100% (1447/1447), done.
remote: Compressing objects: 100% (1270/1270), done.
remote: Total 22211 (delta 276), reused 503 (delta 165), pack-reused 20764
Receiving objects: 100% (22211/22211), 54.67 MiB | 2.79 MiB/s, done.
Resolving deltas: 100% (15016/15016), done.

⏳ Cloning vagrant.local/content/plugins/404-fallback
Cloning into 'vagrant.local/content/plugins/404-fallback'...
remote: Enumerating objects: 7, done.
remote: Counting objects: 100% (7/7), done.
remote: Compressing objects: 100% (7/7), done.
remote: Total 7 (delta 0), reused 7 (delta 0), pack-reused 0
Receiving objects: 100% (7/7), 5.90 KiB | 5.90 MiB/s, done.

⏳ Cloning Taskfile
Cloning into 'Taskfile'...
remote: Enumerating objects: 17, done.
remote: Counting objects: 100% (17/17), done.
remote: Compressing objects: 100% (15/15), done.
remote: Total 47 (delta 2), reused 17 (delta 2), pack-reused 30
Receiving objects: 100% (47/47), 11.05 KiB | 5.53 MiB/s, done.
Resolving deltas: 100% (10/10), done.

⏳ Cloning freshcookies
Cloning into 'freshcookies'...
remote: Enumerating objects: 6, done.
remote: Counting objects: 100% (6/6), done.
remote: Compressing objects: 100% (6/6), done.
remote: Total 24 (delta 1), reused 0 (delta 0), pack-reused 18
Receiving objects: 100% (24/24), 6.43 KiB | 6.43 MiB/s, done.
Resolving deltas: 100% (8/8), done.

⏳ Cloning repoman
Cloning into 'repoman'...
remote: Enumerating objects: 7, done.
remote: Counting objects: 100% (7/7), done.
remote: Compressing objects: 100% (6/6), done.
remote: Total 7 (delta 0), reused 4 (delta 0), pack-reused 0
Receiving objects: 100% (7/7), done.

$ ls -d */
Taskfile      freshcookies  repoman       vagrant.local
```
