include (Translations)

file (GLOB _datafiles "${CMAKE_CURRENT_SOURCE_DIR}/data/style/*")
install (FILES ${_datafiles} DESTINATION ${PKGDATADIR}/style)

# We need to create two temporary desktop files in order to have all translations available.
configure_file (maya-calendar.appdata.xml.in.in ${CMAKE_CURRENT_BINARY_DIR}/maya-calendar.appdata.xml.in)
set (APP_NAME "Calendar")
configure_file (maya-calendar.desktop.in.in ${CMAKE_CURRENT_BINARY_DIR}/maya-calendar.desktop.in)
set (APP_NAME "Maya")
configure_file (maya-calendar.desktop.in.in ${CMAKE_CURRENT_BINARY_DIR}/maya-calendar-original.desktop.in)
if (BUILD_FOR_ELEMENTARY)
    configure_file_translation (${CMAKE_CURRENT_BINARY_DIR}/maya-calendar.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/maya-calendar.desktop ${CMAKE_SOURCE_DIR}/po/)
else ()
    configure_file_translation (${CMAKE_CURRENT_BINARY_DIR}/maya-calendar-original.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/maya-calendar.desktop ${CMAKE_SOURCE_DIR}/po/)
endif ()

configure_file_translation (${CMAKE_CURRENT_BINARY_DIR}/maya-calendar.appdata.xml.in ${CMAKE_CURRENT_BINARY_DIR}/maya-calendar.appdata.xml ${CMAKE_SOURCE_DIR}/po/)

install (FILES ${CMAKE_CURRENT_BINARY_DIR}/maya-calendar.appdata.xml DESTINATION share/appdata)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/maya-calendar.desktop DESTINATION share/applications)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/maya-calendar-daemon.desktop DESTINATION share/applications)
