# Calendar
[![l10n](https://l10n.elementary.io/widgets/calendar/-/svg-badge.svg)](https://l10n.elementary.io/projects/calendar)

![Screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* libchamplain-0.12-dev
* libchamplain-gtk-0.12-dev
* libclutter-1.0-dev
* libecal1.2-dev
* libedataserverui1.2-dev
* libfolks-dev
* libgee-0.8-dev
* libgeocode-glib-dev
* libglib2.0-dev
* libgranite-dev >= 5.2.0
* libgtk-3-dev
* libical-dev
* libnotify-dev
* meson
* valac

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `io.elementary.calendar`

    sudo ninja install
    io.elementary.calendar
