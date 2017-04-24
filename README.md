# Calendar
[![l10n](https://l10n.elementary.io/widgets/calendar/-/svg-badge.svg)](https://l10n.elementary.io/projects/calendar)

## Building and Installation

You'll need the following dependencies:

* cmake
* libchamplain-0.12-dev
* libchamplain-gtk-0.12-dev
* libclutter-1.0-dev
* libecal1.2-dev
* libedataserverui1.2-dev
* libfolks-dev
* libgee-0.8-dev
* libgeocode-glib-dev
* libglib2.0-dev
* libgranite-dev
* libgtk-3-dev
* libical-dev
* libnotify-dev
* valac

It's recommended to create a clean build environment

    mkdir build
    cd build/
    
Run `cmake` to configure the build environment and then `make` to build

    cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    make
    
To install, use `make install` then execute with `maya-calendar`

    sudo make install
    maya-calendar
