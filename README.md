# Calendar
[![l10n](https://l10n.elementary.io/widgets/calendar/-/svg-badge.svg)](https://l10n.elementary.io/projects/calendar)

![Screenshot](data/screenshot.png?raw=true)

## Building and Installation

You'll need the following dependencies:

* libadwaita-1-dev >= 1.0.0
* libecal1.2-dev
* libedataserver1.2-dev >= 3.45.1
* libedataserverui4-dev >= 3.46.4
* libfolks-dev
* libgee-0.8-dev
* libgeocode-glib-dev
* libgeoclue-2-dev
* libglib2.0-dev
* libgranite-7-dev >= 7.7.0
* libgtk-4-dev >= 4.12
* libical-dev
* libportal-dev
* libportal-gtk4-dev
* libshumate-dev
* meson
* valac

Run `meson build` to configure the build environment. Change to the build directory and run `ninja` to build

    meson build --prefix=/usr
    cd build
    ninja

To install, use `ninja install`, then execute with `io.elementary.calendar`

    sudo ninja install
    io.elementary.calendar
