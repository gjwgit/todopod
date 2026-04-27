# Todo Pod - A Secure, Private, Sharable Todot.txt List

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

[![GitHub](https://img.shields.io/badge/GitHub-Repository-blue?logo=github)](https://github.com/gjwgit/todopod)
[![GitHub License](https://img.shields.io/github/license/gjwgit/todopod)](https://raw.githubusercontent.com/gjwgit/todopod/dev/LICENSE)
[![Flutter Version](https://img.shields.io/badge/dynamic/yaml?url=https://raw.githubusercontent.com/gjwgit/todopod/master/pubspec.yaml&query=$.version&label=version)](https://github.com/gjwgit/todopod/blob/dev/CHANGELOG.md)
[![Last Updated](https://img.shields.io/github/last-commit/gjwgit/todopod?label=last%20updated)](https://github.com/gjwgit/todopod/commits/dev/)
[![GitHub commit activity (dev)](https://img.shields.io/github/commit-activity/w/gjwgit/todopod/dev)](https://github.com/gjwgit/rattle/commits/dev/)
[![GitHub Issues](https://img.shields.io/github/issues/gjwgit/todopod)](https://github.com/gjwgit/todopod/issues)

[Todopod](https://gjwgit.github.io/todopod/) manages your tasks with
all data securely and privately stored encrypted on your own personal
online data store (Pod) hosted on a Solid Server. The app implemented
at [Togaware](https://togaware.com) by [Graham
Williams](https://togaware.com/Graham.Williams.html) pair coding with
[Claude Code](https://claude.com/product/claude-code).

We make this project available for free so if you appreciate the app
then please show some ❤️ and tap on the star at
[GitHub](https://github.com/gjwgit/todopod) to support our work.

The latest version of the app can be run online at
[todopod.solidcommunity.au](https://todopod.solidcommunity.au) with no
installation required though requiring a Bluelink login, or downloaded
and installed for your platform from the [Solid Community
AU](https://solidcommunity.au) repository:

<!-- markdownlint-disable MD036 -->
+ **Web**
  [solidcommunity](https://todopod.solidcommunity.au/);
+ **Android**
  [aab](https://solidcommunity.au/installers/todopod.aab) or
  [apk](https://solidcommunity.au/installers/todopod.apk);
+ **GNU/Linux**
  [deb](https://solidcommunity.au/installers/todopod_amd64.deb) or
  [snap](https://solidcommunity.au/installers/todopod_amd64.snap) or
  [zip](https://solidcommunity.au/installers/todopod-linux.zip);
+ **macOS**
  [dmg](https://solidcommunity.au/installers/todopod-macos.dmg) or
  [zip](https://solidcommunity.au/installers/todopod-macos.zip);
+ **Windows**
  [inno](https://solidcommunity.au/installers/todopod-windows-inno.exe) or
  [zip](https://solidcommunity.au/installers/todopod-windows.zip).

[Installation
details](https://github.com/gjwgit/todopod/blob/dev/installers/README.md)
are available for all platforms.

Contributions are welcome. Visit
[github](https://github.com/gjwgit/todopod) to submit an issue or,
even better, fork the repository yourself, update the code, and submit
a Pull Request. The app is implemented in
[Flutter](https://flutter.dev) using
[solidui](https://pub.dev/packages/solidui). Thanks.

## Introduction

Todo Pod is a Solid Flutter app to manage todo lists based on the
todo.txt format for importing and exporting lists. Each item has a
title, notes, priority (A=now, B=today, C=this week, D=next week,
E=later, and F=parked), together with optional due date, duration
optional, project (to collect together related tasks), and a context
(where the task is to be undertaken). You can view your tasks in an
ordered list, a kanban board, or as a planner/calendar.

Task list view:

![List](./assets/screenshots/list_view.png)

New tasks are added by a tap of the `+` in the SEARCH bar or by typing
ENTER in the SEARCH bar whereby the text typed there becomes the title
of the new task.

![Add a new task](./assets/screenshots/add_task_compuvault.png)

After we save the task it is added to our TASK LIST.

![Add a new task](./assets/screenshots/task_list_compuvault.png)

Hover over a task to view the task details.

![Add a new task](./assets/screenshots/task_list_hover.png)

Tap on a task to edit the task.

Drag the right hand clasp to reorder a task.

Drag a task to the left to delete.

Kanban view:

![](./assets/screenshots/kanban_view.png)

Planner view:

![Planner](./assets/screenshots/planner_view.png)
