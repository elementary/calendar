include (Translations)

# We need to create two temporary desktop files in order to have all translations available.
configure_file (${CMAKE_PROJECT_NAME}.appdata.xml.in.in ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.appdata.xml.in)
set (APP_NAME "Calendar")
configure_file (${CMAKE_PROJECT_NAME}.desktop.in.in ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.desktop.in)
set (APP_NAME "Maya")
configure_file (${CMAKE_PROJECT_NAME}.desktop.in.in ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}-original.desktop.in)
if (BUILD_FOR_ELEMENTARY)
    configure_file_translation (${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.desktop ${CMAKE_SOURCE_DIR}/po/)
else ()
    configure_file_translation (${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}-original.desktop.in ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.desktop ${CMAKE_SOURCE_DIR}/po/)
endif ()

configure_file_translation (${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.appdata.xml.in ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.appdata.xml ${CMAKE_SOURCE_DIR}/po/)

install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.appdata.xml DESTINATION share/metainfo)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.desktop DESTINATION share/applications)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}-daemon.desktop DESTINATION share/applications)
