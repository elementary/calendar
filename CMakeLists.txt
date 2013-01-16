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
set (VERSION "0.1")
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

install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/maya-calendar.desktop DESTINATION "${CMAKE_INSTALL_PREFIX}/share/applications")

#
# i18n
#
find_package (Gettext REQUIRED)

add_custom_command (OUTPUT ${CMAKE_SOURCE_DIR}/po/maya.pot
        COMMAND xgettext -c --files-from ${CMAKE_SOURCE_DIR}/po/POTFILES.in --keyword=_ -o ${CMAKE_SOURCE_DIR}/po/maya.pot --no-wrap --no-location
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        )

if (GETTEXT_FOUND)
	message(STATUS GETTEXT_FOUND = ${GETTEXT_FOUND})
        set (HAVE_GETTEXT true)
        file (GLOB _translations ${CMAKE_SOURCE_DIR}/po/*.po)
        GETTEXT_CREATE_TRANSLATIONS (${CMAKE_SOURCE_DIR}/po/${PROJECT_NAME}.pot
                ALL ${_translations})
endif (GETTEXT_FOUND)

#
# Maya
#
find_package(PkgConfig)
pkg_check_modules(DEPS REQUIRED libecal-1.2>=3.2.0 gobject-2.0 glib-2.0 gio-2.0 gtk+-3.0 gthread-2.0 granite libical gee-1.0)

add_definitions(${DEPS_CFLAGS})

link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.15.1" MINIMUM)

# Maya/Widgets/Calendar/EventsList.vala
# Maya/Widgets/Calendar/Event.vala

include(ValaPrecompile)
vala_precompile(VALA_C
    Maya/Application.vala
    Maya/Model/CalendarModel.vala
    Maya/Model/SourceManager.vala
    Maya/Services/Contractor.vala
    Maya/Services/Dexter.vala
    Maya/Settings/MayaSettings.vala
    Maya/Settings/SavedState.vala
    Maya/Settings/LanguagesFormat.vala
    Maya/Utils.vala
    Maya/View/Sidebar/AgendaView.vala
    Maya/View/Sidebar/Sidebar.vala
    Maya/View/Sidebar/SourceWidget.vala
    Maya/View/Sidebar/EventWidget.vala
    Maya/View/Grid/CalendarView.vala
    Maya/View/Grid/GridDay.vala
    Maya/View/Grid/Grid.vala
    Maya/View/Grid/EventButton/EventButton.vala
    Maya/View/Grid/EventButton/MultiDayEventButton.vala
    Maya/View/Grid/EventButton/SingleDayEventButton.vala
    Maya/View/Grid/WeekLabels.vala
    Maya/View/Grid/Header.vala
    Maya/View/Grid/VAutoHider.vala
    Maya/View/EventDialog.vala
    Maya/View/MayaMenu.vala
    Maya/View/MayaToolbar.vala
    Maya/View/SourceSelector.vala
    Maya/View/Widgets/ContractorButtonWithMenu.vala
    Maya/View/Widgets/DateSwitcher.vala
    Maya/View/Widgets/DateTimePicker.vala
    Maya/View/Widgets/Postler/GuestEntry.vala
    Maya/View/Widgets/Postler/FlowBox.vala
    Maya/View/Widgets/Postler/Contact.vala
PACKAGES
    gconf-2.0
    gee-1.0
    gio-2.0
    granite
    gtk+-3.0
    libecalendar-1.2
    libedataserver-1.2
    libical
    libsoup-2.4
CUSTOM_VAPIS
    vapi/config.vapi
OPTIONS
    --thread
    --vapidir=${CMAKE_CURRENT_SOURCE_DIR}/vapi/
    --define=USE_GRANITE_DECORATED_WINDOW
    )

add_definitions(${CFLAGS} -Wall -Winit-self -Wwrite-strings -Wunreachable-code -Wstrict-prototypes )
add_executable(maya-calendar ${VALA_C})

install(TARGETS maya-calendar RUNTIME DESTINATION bin)

#
# GSettings Schema
#
include(GSettings)
add_schema("org.pantheon.Maya.gschema.xml")

