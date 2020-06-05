# Repoman

Repoman is a script to export and import a list of git repositories using an intermediate `repoman.lst` file.

When exporting, Repoman scans the working directory for .git folders and save its relative path with the git remote.

When importing, repoman will restore this directory structure and clone each repository.

# Why use this

It's bad practice to use cloud sync solutions to sync working copies (https://git.seveas.net/how-to-back-up-a-git-repository.html).

Repoman helps you work on the same projects on multiple devices, by syncing `repoman.lst` instead.

# Examples

Export
```bash
$ repoman.sh export
vagrant.local=https://github.com/Chassis/Chassis.git
vagrant.local/content/plugins/404-fallback=https://github.com/svandragt/404-fallback.git
Taskfile=git@github.com:svandragt/Taskfile.git
freshcookies=git@github.com:svandragt/freshcookies.git
repoman=https://github.com/svandragt/repoman.git
```

```bash
$ repoman.sh import

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

$ ls
Taskfile      freshcookies  repoman       repoman.lst   vagrant.local
```
