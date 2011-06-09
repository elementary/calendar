project (maya)
cmake_minimum_required (VERSION 2.8)


list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/vala)

#
# Base bits
#
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/maya")
set (GETTEXT_PACKAGE "maya")
set (RELEASE_NAME "Fast and connected.")
set (VERSION "0.2.0")
set (VERSION_INFO "Release")

#
# Niceties
#
set (ARCHIVE_NAME maya-${VERSION})
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
# config.h
#

configure_file (${CMAKE_SOURCE_DIR}/config.h.cmake ${CMAKE_BINARY_DIR}/config.h)
add_definitions(-include config.h)

#
# Data
#
file (GLOB _datafiles "${CMAKE_CURRENT_SOURCE_DIR}/data/style/*")
install (FILES ${_datafiles} DESTINATION ${PKGDATADIR}/style)

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/maya.desktop DESTINATION /usr/share/applications)

#
# i18n
#
find_package (Gettext REQUIRED)

add_custom_command (OUTPUT ${CMAKE_SOURCE_DIR}/po/maya.pot
        COMMAND xgettext -c --files-from ${CMAKE_SOURCE_DIR}/po/POTFILES.in --keyword=_ -o ${CMAKE_SOURCE_DIR}/po/maya.pot --no-wrap --no-location
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        )

if (${GETTEXT_FOUND} STREQUAL "TRUE")
        set (HAVE_GETTEXT true)
        file (GLOB _translations ${CMAKE_SOURCE_DIR}/po/*.po)
        GETTEXT_CREATE_TRANSLATIONS (${CMAKE_SOURCE_DIR}/po/${PROJECT_NAME}.pot
                ALL ${_translations})
endif (${GETTEXT_FOUND} STREQUAL "TRUE")

#
# Maya
#

set (MAYA_DEPS "gobject-2.0;glib-2.0;gio-2.0;gtk+-3.0;libgranite;gee-1.0")

find_package(PkgConfig)
pkg_check_modules(GLIB REQUIRED "glib-2.0 >= 2.26.0")
pkg_check_modules(GOBJECT REQUIRED "gobject-2.0 >= 2.26.0")
pkg_check_modules(GIO REQUIRED "gio-2.0 >= 2.26.0")
pkg_check_modules(GTK+ REQUIRED "gtk+-3.0 >= 3.0.8")
pkg_check_modules(GEE REQUIRED "gee-1.0")
pkg_check_modules(LIBGRANITE REQUIRED "libgranite")
pkg_check_modules(DEPS REQUIRED ${MAYA_DEPS})

add_definitions(${DEPS_CFLAGS})

link_libraries(${DEPS_LIBRARIES})

link_directories(${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.10.0" MINIMUM)

include(ValaPrecompile)
vala_precompile(VALA_C
    Maya/Maya.vala
    Maya/Dialogs/Event.vala
    Maya/Services/DateHandler.vala
    Maya/Services/Dexter.vala
    Maya/Widgets/Calendar/Calendar.vala
    Maya/Widgets/Calendar/CalendarView.vala
    Maya/Widgets/Calendar/Day.vala
    Maya/Widgets/Calendar/Header.vala
    Maya/Widgets/AgendaView.vala
    Maya/Widgets/DateSwitcher.vala
    Maya/Widgets/DateTimePicker.vala
    Maya/Widgets/GuestPicker.vala
    Maya/Widgets/MayaMenu.vala
    Maya/Widgets/MayaToolbar.vala
    Maya/Widgets/MayaWindow.vala
    Maya/Widgets/Sidebar.vala
    Maya/Widgets/Utilities.vala
PACKAGES
    gtk+-3.0
    gee-1.0
    granite
CUSTOM_VAPIS
    vapi/config.vapi
OPTIONS
    --thread
    )

add_definitions(${CFLAGS} -Wall -Winit-self -Wwrite-strings -Wunreachable-code -Wstrict-prototypes )
add_executable(maya ${VALA_C})

install(TARGETS maya RUNTIME DESTINATION bin)

#
# GSettings Schema
#
SET (MAYA_SCHEMAS "org.elementary.Maya.gschema.xml")

# Have an option to not install the schema into where GLib is
option (GSETTINGS_LOCALINSTALL "Install GSettings Schemas locally instead of to the GLib prefix" OFF)
if (GSETTINGS_LOCALINSTALL)
    SET (GSETTINGS_DIR "${CMAKE_INSTALL_PREFIX}/share/glib-2.0/schemas/")
else (GSETTINGS_LOCALINSTALL)
    execute_process (COMMAND ${PKG_CONFIG_EXECUTABLE} glib-2.0 --variable prefix OUTPUT_VARIABLE _glib_prefix OUTPUT_STRIP_TRAILING_WHITESPACE)
    SET (GSETTINGS_DIR "${_glib_prefix}/share/glib-2.0/schemas/")
endif (GSETTINGS_LOCALINSTALL)

# Run the validator and error if it fails
execute_process (COMMAND ${PKG_CONFIG_EXECUTABLE} gio-2.0 --variable glib_compile_schemas  OUTPUT_VARIABLE _glib_comple_schemas OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process (COMMAND ${_glib_comple_schemas} --dry-run --schema-file=${CMAKE_CURRENT_SOURCE_DIR}/${MAYA_SCHEMAS} ERROR_VARIABLE _schemas_invalid OUTPUT_STRIP_TRAILING_WHITESPACE)

if (_schemas_invalid)
  message (SEND_ERROR "Schema validation error: ${_schemas_invalid}")
endif (_schemas_invalid)

# Actually install and recomple schemas
message (STATUS "GSettings schemas will be installed into ${GSETTINGS_DIR}")
install (FILES ${MAYA_SCHEMAS} DESTINATION ${GSETTINGS_DIR} OPTIONAL)
install (CODE "message (STATUS \"Compiling GSettings schemas\")")
install (CODE "execute_process (COMMAND ${_glib_comple_schemas} ${GSETTINGS_DIR})")

