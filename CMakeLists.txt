cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.8)
project (io.elementary.calendar C)

#
# Base bits
#
include (GNUInstallDirs)
set (EXEC_NAME ${CMAKE_PROJECT_NAME})
set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
set (VERSION "0.4.2.1")
set (PLUGIN_DIR ${CMAKE_INSTALL_FULL_LIBDIR}/${CMAKE_PROJECT_NAME}/plugins)
set (CORE_LIBRARY_NAME libelementary-calendar)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
add_definitions ("-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\"")

# Comment this out to enable C compiler warnings
add_definitions (-w)

set (APP_NAME "Calendar")

#
# Niceties
#

add_custom_target (uninstall "${CMAKE_COMMAND}" -P
  "${CMAKE_SOURCE_DIR}/cmake/uninstall.cmake")

#
# Maya
#

set (CORE_PACKAGES
    gee-0.8
    gio-2.0
    granite
    gtk+-3.0
    libecal-1.2
    libedataserver-1.2
    libedataserverui-1.2
    libical
    libsoup-2.4
    gmodule-2.0
)

set (CORE_PKG
    gobject-2.0
    gthread-2.0
    glib-2.0
    gio-2.0
    gee-0.8
    gtk+-3.0>=3.22
    granite>=0.5
    libedataserver-1.2
    libecal-1.2>=3.8.0
    libedataserverui-1.2
    libical
    gmodule-2.0
)

set (DEPS_PACKAGES
    ${CMAKE_PROJECT_NAME}
    ${CORE_PACKAGES} # this is needed until we provide a ${CORE_LIBRARY_NAME}.deps file
    champlain-gtk-0.12
    champlain-0.12
    clutter-1.0
    clutter-gtk-1.0
    geocode-glib-1.0
    folks
)

set (DEPS_PKG
    champlain-gtk-0.12
    champlain-0.12
    clutter-1.0
    geocode-glib-1.0
    clutter-gtk-1.0
    folks
)

set (BASIC_VALAC_OPTIONS
  --vapidir=${CMAKE_SOURCE_DIR}/vapi
  --target-glib=2.32
  --thread
)

set (GLOBAL_VALAC_OPTIONS
  ${BASIC_VALAC_OPTIONS}
  --vapidir=${CMAKE_BINARY_DIR}/core
)

find_package (PkgConfig)
pkg_check_modules (CORE REQUIRED ${CORE_PKG})
pkg_check_modules (DEPS REQUIRED ${DEPS_PKG})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.40.4" MINIMUM)
include (ValaPrecompile)

add_subdirectory (po)
add_subdirectory (data)
add_subdirectory (core)
include_directories (${CMAKE_BINARY_DIR}/core)
set (DEPS_LIBRARIES ${DEPS_LIBRARIES} ${CORE_LIBRARY_NAME})
add_subdirectory (src)
add_subdirectory (daemon)
add_subdirectory (plugins)
add_subdirectory (schemas)
