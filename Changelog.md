2025.03.22, Version 5.8.4

LOW LEVEL CHANGES

* Update npm packages and dependencies to fix vulnerabilities

* Update bash shebang in shell scripts to use /usr/bin/env bash for cross-platform compatibility

* Add test infrastructure improvements with meteortesting:mocha package and chai dev dependency

* justdo-packages: Reorganize i18n configuration files (convert extra-i18n-instructions.txt to _i18n-conf.json)

* justdo-packages: grid-data: Fix a bug in bulkAddSibling that results in incorrect "order" in inserted tasks

* justdo-packages: Integration of justdo-ai-kit into the core packages with cleanup

* Developer experience improvements - Updated .cursorignore to exclude only .meteor/local 
  to allow agent to read project and package metadata

2025.03.05, Version 5.8.3

* Publish justdo_user_active_position.hide_user_active_position to user document #17978

Prepares for a new feature that lets environments show which users are online. This field
allows users to opt out of sharing their presence with others.

* Improvements to admin page #17980

2025.02.19, Version 5.8.2

* Improvements to admin page #17969

2025.02.14, Version 5.8.1

* Fix an issue with Chat's DM emails notifications #17962

* i18n parts of JustDo Chat that weren't yet #17963

* Fix wrong label presented in the search dropdown when results found in the
Notes field #17964

2025.02.07, Version 5.8.0

* Introduce JustDo direct messaging #17950

* Design touchups to the grid search dropdown #17951

* Add 'What's new' content for v5.8.0 #17954

LOW LEVEL CHANGES

* Migrated to Firebase Admin’s HTTP v1 messaging API #17952

2025.02.19, Version 5.8.2

* Improvements to admin page #17969

2025.02.14, Version 5.8.1

* Fix an issue with Chat's DM emails notifications #17962

* i18n parts of JustDo Chat that weren't yet #17963

* Fix wrong label presented in the search dropdown when results found in the
Notes field #17964

2025.02.07, Version 5.8.0

* Introduce JustDo direct messaging #17950

* Design touchups to the grid search dropdown #17951

* Add 'What's new' content for v5.8.0 #17954

LOW LEVEL CHANGES

* Migrated to Firebase Admin’s HTTP v1 messaging API #17952

2025.01.31, Version 5.7.2

* Introduce the ability to filter date fields without a value. Add the ability
to the built-in due-date, follow-up, private-follow-up, and custom fields of
type date #17947

2025.01.30, Version 5.7.1

First source-available release of justdo-web-app-ce 🎉
