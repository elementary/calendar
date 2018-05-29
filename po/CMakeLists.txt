include (Translations)
add_translations_directory (${GETTEXT_PACKAGE})
add_translations_catalog (${GETTEXT_PACKAGE}
    ../src
    ../plugins
    ../core
    ../daemon
    DESKTOP_FILES
        ${CMAKE_BINARY_DIR}/data/${CMAKE_PROJECT_NAME}.desktop.in
        ${CMAKE_BINARY_DIR}/data/${CMAKE_PROJECT_NAME}-original.desktop.in
    APPDATA_FILES
        ${CMAKE_BINARY_DIR}/data/${CMAKE_PROJECT_NAME}.appdata.xml.in
)
