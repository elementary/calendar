include (Translations)

file (GLOB _datafiles "${CMAKE_CURRENT_SOURCE_DIR}/style/*")
install (FILES ${_datafiles} DESTINATION ${PKGDATADIR}/style)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/LocationMarker.svg DESTINATION ${PKGDATADIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/calendar-go-today.svg DESTINATION ${DATADIR}/icons/hicolor/scalable/actions)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/16/io.elementary.calendar.svg DESTINATION ${DATADIR}/icons/hicolor/16x16/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/24/io.elementary.calendar.svg DESTINATION ${DATADIR}/icons/hicolor/24x24/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/32/io.elementary.calendar.svg DESTINATION ${DATADIR}/icons/hicolor/32x32/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/48/io.elementary.calendar.svg DESTINATION ${DATADIR}/icons/hicolor/48x48/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/64/io.elementary.calendar.svg DESTINATION ${DATADIR}/icons/hicolor/64x64/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/128/io.elementary.calendar.svg DESTINATION ${DATADIR}/icons/hicolor/128x128/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/icons/symbolic/io.elementary.calendar-symbolic.svg DESTINATION ${DATADIR}/icons/hicolor/symbolic/apps)

install (CODE "execute_process (COMMAND gtk-update-icon-cache /usr/share/icons/hicolor)")

# We need to create two temporary desktop files in order to have all translations available.
configure_file (org.pantheon.maya.appdata.xml.in.in ${CMAKE_CURRENT_BINARY_DIR}/org.pantheon.maya.appdata.xml.in)
set (APP_NAME "Calendar")
configure_file (org.pantheon.maya.desktop.in.in ${CMAKE_CURRENT_BINARY_DIR}/org.pantheon.maya.desktop.in)
set (APP_NAME "Maya")
configure_file (org.pantheon.maya.desktop.in.in ${CMAKE_CURRENT_BINARY_DIR}/org.pantheon.maya-original.desktop.in)
if (BUILD_FOR_ELEMENTARY)
    configure_file_translation (${CMAKE_CURRENT_BINARY_DIR}/org.pantheon.maya.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/org.pantheon.maya.desktop ${CMAKE_SOURCE_DIR}/po/)
else ()
    configure_file_translation (${CMAKE_CURRENT_BINARY_DIR}/org.pantheon.maya-original.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/org.pantheon.maya.desktop ${CMAKE_SOURCE_DIR}/po/)
endif ()

configure_file_translation (${CMAKE_CURRENT_BINARY_DIR}/org.pantheon.maya.appdata.xml.in ${CMAKE_CURRENT_BINARY_DIR}/org.pantheon.maya.appdata.xml ${CMAKE_SOURCE_DIR}/po/)

install (FILES ${CMAKE_CURRENT_BINARY_DIR}/org.pantheon.maya.appdata.xml DESTINATION share/appdata)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/org.pantheon.maya.desktop DESTINATION share/applications)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/org.pantheon.maya-daemon.desktop DESTINATION share/applications)
