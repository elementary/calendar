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
set (VERSION "0.2")
set (VERSION_INFO "Release")

list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

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

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/maya.desktop DESTINATION "${CMAKE_INSTALL_PREFIX}/share/applications")

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
find_package(PkgConfig)
pkg_check_modules(DEPS REQUIRED libecal-1.2>=3.2.0 gobject-2.0 glib-2.0 gio-2.0 gtk+-3.0 granite libical gee-1.0)

add_definitions(${DEPS_CFLAGS})

link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.10.0" MINIMUM)

# Maya/Widgets/Calendar/EventsList.vala
# Maya/Widgets/Calendar/Event.vala

include(ValaPrecompile)
vala_precompile(VALA_C
    Maya/Maya.vala
    Maya/MayaSettings.vala
    Maya/SavedState.vala
    Maya/Dialogs/Event.vala
    Maya/Services/Contractor.vala
    Maya/Services/DateHandler.vala
    Maya/Services/Dexter.vala
    Maya/Widgets/Calendar/Calendar.vala
    Maya/Widgets/Calendar/CalendarView.vala
    Maya/Widgets/Calendar/Day.vala
    Maya/Widgets/Calendar/Header.vala
    Maya/Widgets/Calendar/Weeks.vala
    Maya/Widgets/AgendaView.vala
    Maya/Widgets/ContractorButtonWithMenu.vala
    Maya/Widgets/DateSwitcher.vala
    Maya/Widgets/DateTimePicker.vala
    Maya/Widgets/MayaMenu.vala
    Maya/Widgets/MayaToolbar.vala
    Maya/Widgets/MayaWindow.vala
    Maya/Widgets/Sidebar.vala
    Maya/Widgets/Utilities.vala
    Maya/Events/Backend.vala
PACKAGES
    gtk+-3.0
    granite
    gee-1.0
    libecalendar-1.2
    libedataserver-1.2
    libical
CUSTOM_VAPIS
    vapi/config.vapi
OPTIONS
    --thread
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi/
    )

add_definitions(${CFLAGS} -Wall -Winit-self -Wwrite-strings -Wunreachable-code -Wstrict-prototypes )
add_executable(maya ${VALA_C})

install(TARGETS maya RUNTIME DESTINATION bin)

#
# GSettings Schema
#
include(GSettings)
add_schema("org.elementary.Maya.gschema.xml")

