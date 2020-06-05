# Repoman

Repoman is a script to export and import a list of git repositories using an intermediate `repoman.def` file.

When exporting, Repoman scans the working directory for .git folders and save its relative path with the git remote.

When importing, repoman will restore this directory structure and clone each repository.

# Why use this

It's bad practice to use cloud sync solutions to sync working copies (https://git.seveas.net/how-to-back-up-a-git-repository.html).

Repoman helps you work on the same projects on multiple devices, by syncing `repoman.def` instead.
