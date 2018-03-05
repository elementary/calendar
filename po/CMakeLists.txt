include (Translations)
add_translations_directory (${GETTEXT_PACKAGE})
add_translations_catalog (${GETTEXT_PACKAGE}
    ../src
    ../plugins
    ../core
    ../daemon
    DESKTOP_FILES
        ${CMAKE_BINARY_DIR}/data/org.pantheon.maya.desktop.in
        ${CMAKE_BINARY_DIR}/data/org.pantheon.maya-original.desktop.in
    APPDATA_FILES
        ${CMAKE_BINARY_DIR}/data/org.pantheon.maya.appdata.xml.in
)
