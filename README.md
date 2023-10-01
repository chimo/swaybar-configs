# swaybar

## TODOs

Readme:

* Explain what this is, "documentation"

General:

* Make icons optional, replace with text when disabled (or font missing)
* Think about moving cooldown functionality to `cron`  
  main.sh should still execute blocks if state files aren't there
* inotifyd for ad-hoc refreshes, when possible?

libs/check-for-updates:

* split os-specific things into their own files
* dist-upgrade for the host
* consider splitting host vs. container into separate "blocks" since the host
  may not be running containers at all, the contianer "block" should be optional
* share common code between host and container "blocks"

