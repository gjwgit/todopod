# ToDoPod Change Log

Noted below are the high level changes for the app.  Each update
includes a short user-oriented description, version number, date, and
developer.

You can run the app in your
[**browser**](https://todopod.solidcommunity.au) or else download and
install locally the latest version from the [Solid Community
AU](https://solidcommunity.au) or directly:

+ **Android** as
[apk](https://solidcommunity.au/installers/todopod.apk) or
[aab](https://solidcommunity.au/installers/todopod.aab);
+ **GNU/Linux** as
[deb](https://solidcommunity.au/installers/todopod_amd64.deb) or
[snap](https://solidcommunity.au/installers/todopod_amd64.snap) or
[zip](https://solidcommunity.au/installers/todopod-linux.zip);
+ **macOS** as
[dmg](https://solidcommunity.au/installers/todopod-macos.dmg) or
[zip](https://solidcommunity.au/installers/todopod-macos.zip);
+ **Windows** as
[exe](https://solidcommunity.au/installers/todopod-windows-inno.exe)
or [zip](https://solidcommunity.au/installers/todopod-windows.zip).

Contributions are welcome. Visit
[github](https://github.com/gjwgit/todopod) to submit an issue or, even
better, fork the repository yourself, update the code, and submit a
Pull Request. Coding documentation is
[available](https://solidcommunity.au/docs/todopod/).

We make this project available for free so if you appreciate the app
then please show some ❤️ and tap on the star at
[GitHub](https://github.com/gjwgit/todopod) to support our work.

This app is authored by [Graham
Williams](https://togaware.com/Graham.Williams.html).

## 1.0 New Secure Key Handling

+ Reorganise EDIT TASK layout for Mark as done and Duration [1.0.26 20260809 gjw]
+ Add a set due today button to the task list [1.0.25 20260808 gjw]
+ Keep the window open when a save fails on close [1.0.24 20260808 gjw]
+ Report failed task saves instead of failing silently [1.0.23 20260808 gjw]
+ Wait for in-flight Pod writes before closing [1.0.22 20260808 gjw]
+ Prompt to save unsaved task on window close [1.0.21 20260808 gjw]
+ Fix drag to reorder skipping adjacent moves [1.0.20 20260808 gjw]
+ Use softer snackbar colours and update tooltips [1.0.19 20260729 gjw]
+ Remember order for OVERDUE [1.0.18 20260728 gjw]
+ Add task counts to TASKS screen [1.0.17 20260726 gjw]
+ Add OVERDUE screen [1.0.16 20260726 gjw]
+ Update to latest solidui with cached profile [1.0.15 20260718 gjw]
+ BACKUP -> Export [1.0.14 20260717 gjw]
+ OIDC update for chrome/web [1.0.13 20260713 tonypioneer]
+ Updated oidc and appid handling [1.0.12 20260710 gjw]
+ Add emacs_text_field bug fix for web [1.0.11 20260707 gjw]
+ Update soludui/solidpod dependencies [1.0.10 20260703 gjw]
+ HOME -> TASKS [1.0.9 20260628 gjw]
+ HOME -> ABOUT and TASKS -> HOME [1.0.8 20260623 gjw]
+ Restore refresh button [1.0.7 20260620 gjw]
+ Ensure busy animation on startup [1.0.6 20260619 gjw]
+ Add a refresh button [1.0.5 20260619 gjw]
+ HOME uses markdown now [1.0.4 20260614 gjw]
+ Updated HOME messaging [1.0.3 20260613 gjw]
+ ADD TASK button for KANBAN page [1.0.2 20260612 gjw]
+ Sorting added to KANBAN [1.0.1 20260612 gjw]
+ Update solid_auth to fix token refresh bug [1.0.0 20260612 gjw]

## 0.1 Basic Functionality

+ Add SAVE to PDF VIEW in BACKUP [0.1.48 20260612 gjw]
+ Kanban based on CONTEXT as well as PRIORITY [0.1.47 20260612 gjw]
+ NEW TASK auto decide on priority based on date [0.1.46 20260612 gjw]
+ Refine PDF generation [0.1.45 20260611 gjw]
+ SAVE button enabled on change [0.1.44 20260611 gjw]
+ Reorganise IMPORT/EXPORT as BACKUP [0.1.43 20260611 gjw]
+ Updated solidui menus to bottom [0.1.42 20260606 gjw]
+ DONE will markup any notes [0.1.41 20260602 gjw]
+ ENTER in TITLE of NEW TASK will now ADD ATSK [0.1.40 20260528 gjw]
+ Add README to ABOUT [0.1.39 20260526 gjw]
+ Restructure main/app/app_scafffold/home [0.1.38 20260521 gjw]
+ Restructure to one file per function/class [0.1.37 20260521 gjw]
+ Bug fix when DONE from Kanban and Planner [0.1.36 20260521 gjw]
+ Change menu ordering - Done is lower [0.1.35 20260519 gjw]
+ Add a delete button to augment swipe to delete [0.1.34 20260519 gjw]
+ Updated emacs. Kanban moves on short tap [0.1.33 20260514 gjw]
+ Support emacs in NOTES like diarypod [0.1.32 20260503 gjw]
+ Date picker is not barier dismissable [0.1.31 20260503 gjw]
+ Remove item ttile tooltip and add an info button [0.1.30 20260501 gjw]
+ Migrate to latest solidui with server list [0.1.29 20260501 gjw]
+ Add window title [0.1.28 20260430 gjw]
+ Default new task to priority B and due today [0.1.27 20260430 gjw]
+ Add a TODAY button to the PLANNER [0.1.26 20260427 gjw]
+ Add Kanban and Planner [0.1.25 20260427 gjw]
+ Import/Export Done.txt and JSON for backup [0.1.24 20260423 gjw]
+ Update tooltip for tasks with no notes [0.1.23 20260420 gjw]
+ Ensure bullets render in tootlips [0.1.22 20260420 gjw]
+ Remove Floating add button. Update tooltips. [0.1.21 20260420 gjw]
+ Floating + add search as default title [0.1.20 20260417 gjw]
+ Add a DONE checkbox in the EDIT dialog [0.1.19 20260414 gjw]
+ Bug fix on dragging items when list is filtered [0.1.18 20260413 gjw]
+ Support export to PDF [0.1.17 20260413 gjw]
+ Search allows tags and project/context [0.1.16 20260413 gjw]
+ Avoid dismissing editable popups [0.1.15 20260412 gjw]
+ Colour code late entries [0.1.14 20260412 gjw]
+ Support dark/light theme [0.1.13 20260410 gjw]
+ Project and context default focus to the text field [0.1.12 20260407 gjw]
+ Secondary sort by due date then alphabetic [0.1.11 20260407 gjw]
+ Add tooltips [0.1.10 20260406 gjw]
+ Bug fix reorder function [01.9 20260406 gjw]
+ All search bar text as new task title [0.1.8 20260406 gjw]
+ Tap on a DONE item to view it [0.1.7 20260402 gjw]
+ Support delete task with a swipe [0.1.6 20260402 gjw]
+ Allow items to be ordered/moved [0.1.5 20260402 gjw]
+ Catch unsaved edits [0.1.4 20260401 gjw]
+ Support a NOTE field for entries [0.1.3 20260401 gjw]
+ Autocomplete ptoject/context [0.1.2 20260401 gjw]
+ Support basic import of Todo.txt [0.1.1 20260327 gjw]
+ Initial template app [0.1.0 20260327 gjw]
