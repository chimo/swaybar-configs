# updates

Displays the number of pending updates of running LXD containers, as well as
the host machine (Alpine Linux host only).

Note: displaying host updates relies on `apk update` being run, somehow (e.g.:
via `cron`). This script essentially just does `apk list -u | wc -l`.

Depends on `lxd`, `apk`.

