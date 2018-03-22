include (Translations)

# We need to create two temporary desktop files in order to have all translations available.
configure_file (io.elementary.calendar.appdata.xml.in.in ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.calendar.appdata.xml.in)
set (APP_NAME "Calendar")
configure_file (io.elementary.calendar.desktop.in.in ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.calendar.desktop.in)
set (APP_NAME "Maya")
configure_file (io.elementary.calendar.desktop.in.in ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.calendar-original.desktop.in)
if (BUILD_FOR_ELEMENTARY)
    configure_file_translation (${CMAKE_CURRENT_BINARY_DIR}/io.elementary.calendar.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.calendar.desktop ${CMAKE_SOURCE_DIR}/po/)
else ()
    configure_file_translation (${CMAKE_CURRENT_BINARY_DIR}/io.elementary.calendar-original.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.calendar.desktop ${CMAKE_SOURCE_DIR}/po/)
endif ()

configure_file_translation (${CMAKE_CURRENT_BINARY_DIR}/io.elementary.calendar.appdata.xml.in ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.calendar.appdata.xml ${CMAKE_SOURCE_DIR}/po/)

install (FILES ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.calendar.appdata.xml DESTINATION share/metainfo)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/io.elementary.calendar.desktop DESTINATION share/applications)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/io.elementary.calendar-daemon.desktop DESTINATION share/applications)
