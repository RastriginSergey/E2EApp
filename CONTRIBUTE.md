# Contributing to NexmoClient

The source code must be in *objective c* language, also objects/enums/protocols/etc start with *NXM* prefix.

Contribute to this repository by branching, and creating *pull requests* to merge you branch. Pull requests must satisfy a policy:
* Code review by a team member
* Validation build must pass (runs code analysis and some unit tests)
* Update **CHANGELOG.md** file

> When completing pull requests, we encourage to squash rather than merge, in order to keep a clean history tree. If you are using an integration branch, you can squash to the integration branch and merge from it to master.

Notes:
You need to explicitly add the team as reviewers, After the pull request is created the required reviewers aren't added automatically.
Only admin can merge pull request without someone to review it.

## Branch Structure
**master** - latest public release branch. We encourage merge here to keep its history.
**develop** - stable development branch. We encourage squashing here to keep its history nice and neat
**release** - release branch. We release our SDK only from here. Contributing directly to this branch (and by merging from develop) should be used for hot-fixes.
**feature/CSI_{NUM}_topic** - this is the naming scheme we use for private branches.
Repository Structure

>When using .gitignore, we prefer using as much specific files as possible. For example, to ignore auto generated files in a project, create a .gitignore in your project's directory, rather than editing the one in the repository's root. This way when we move project folders from place to place nothing breaks.

## Coding Style  
* Most importantly, match the existing code style as much as possible.
* Try to keep lines under 150 characters, if possible.




