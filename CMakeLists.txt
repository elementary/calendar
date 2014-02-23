project (maya)
cmake_minimum_required (VERSION 2.8)


list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/vala)

#
# Base bits
#
include (GNUInstallDirs)
set (DATADIR "${CMAKE_INSTALL_FULL_DATAROOTDIR}")
set (SRC_TARGET ${CMAKE_PROJECT_NAME}-calendar)
set (PKGDATADIR "${DATADIR}/${SRC_TARGET}")
set (GETTEXT_PACKAGE "maya")
set (APP_NAME "Maya")
set (RELEASE_NAME "Fast and connected.")
set (VERSION "0.2.2")
set (VERSION_INFO "Release")
set (PLUGIN_DIR ${CMAKE_INSTALL_FULL_LIBDIR}/${CMAKE_PROJECT_NAME}/plugins)

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
add_definitions ("-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\"")

# Comment this out to enable C compiler warnings
add_definitions (-w)

option (BUILD_SHARED_LIBS "Switch between shared and static libraries" ON)

if (BUILD_SHARED_LIBS)
    message("-- Shared libraries enabled")
else ()
    message("-- Shared libraries disabled")
endif ()

#
# Niceties
#
set (ARCHIVE_NAME ${SRC_TARGET}-${VERSION})
add_custom_target (dist
    COMMAND bzr export --root=${ARCHIVE_NAME} ${CMAKE_BINARY_DIR}/${ARCHIVE_NAME}.tar.bz2
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )

add_custom_target (distcheck
    COMMAND cd ${CMAKE_BINARY_DIR}
    && rm -rf ${ARCHIVE_NAME}
    && tar xf ${ARCHIVE_NAME}.tar.bz2
    && mkdir ${ARCHIVE_NAME}/build
    && cd ${ARCHIVE_NAME}/build
    && cmake -DCMAKE_INSTALL_PREFIX=../install -DGSETTINGS_LOCALINSTALL=ON .. -DCMAKE_MODULE_PATH=/usr/share/cmake
    && make -j8
    && make -j8 install
    && make check
    )
add_dependencies(distcheck dist)

add_custom_target (uninstall "${CMAKE_COMMAND}" -P
  "${CMAKE_SOURCE_DIR}/cmake/uninstall.cmake")

#
# Data
#
file (GLOB _datafiles "${CMAKE_CURRENT_SOURCE_DIR}/data/style/*")
install (FILES ${_datafiles} DESTINATION ${PKGDATADIR}/style)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/${SRC_TARGET}.desktop DESTINATION "${DATADIR}/applications")

#
# i18n
#

add_subdirectory(po)

#
# Maya
#

set (DEPS_PACKAGES
    gconf-2.0
    gee-0.8
    gio-2.0
    granite
    gtk+-3.0
    libecalendar-1.2
    libedataserver-1.2
    libical
    libsoup-2.4
    libpeas-1.0
)

set (DEPS_PKG
    gobject-2.0
    gthread-2.0
    glib-2.0
    gio-2.0
    gee-0.8
    gtk+-3.0>=3.10
    granite
    libecal-1.2>=3.8.0
    libical
    libpeas-1.0
)

set (GLOBAL_VALAC_OPTIONS
    --define=USE_GRANITE_DECORATED_WINDOW
    --target-glib=2.32
    --thread
    --vapidir=${CMAKE_BINARY_DIR}/src
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
)

find_package (PkgConfig)
pkg_check_modules (DEPS REQUIRED ${DEPS_PKG})

find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.22.0" MINIMUM)
include (ValaPrecompile)

add_subdirectory (src)
add_subdirectory (plugins)
add_subdirectory (schemas)