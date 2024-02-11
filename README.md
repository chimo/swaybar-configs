# swaybar

Custom, `sh`-driven [swaybar](https://swaywm.org/).

I'm using this project as an excuse to learn things. As such, it's probably a
little bit of a mess and subject to change at any time.

One of the goals is to mostly use the tools available on a fresh Alpine Linux
install (Busybox) and keep the package requirements low.

A decent number of "blocks" rely on external services (location, weather, etc.).
Each block should have its own README with more information. Blocks aim to be
somewhat configurable (ex: custom endpoints for external services).

Note: The icons rely on the `font-awesome` package. I'd like to make that
optional in the future, however.

## Usage

In your sway config file (usually ~/.config/sway/config) point the
"status_command" property to main.sh, with the --json parameter like so:

```
bar {
    status_command '~/.config/sway/swaybar/main.sh --json'
}
```

At the moment, the blocks are hardcoded in main.sh in the `run_all()` function.
Add/remove them as you see fit. The number is the "refresh interval" in
seconds:

`run bluetooth.sh 600 "${protocol}" # Run the "bluetooth" block every 10mins`

## TODOs

* Make icons optional. Fallback on text when the convey information.
* Maybe a screenshot for the readme?
* inotifyd for ad-hoc refreshes, when possible?

