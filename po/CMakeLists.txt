include (Translations)
add_translations_directory (${GETTEXT_PACKAGE})
add_translations_catalog (${GETTEXT_PACKAGE}
    ../src
    ../plugins
    ../core
    ../daemon
    DESKTOP_FILES
        ${CMAKE_BINARY_DIR}/data/io.elementary.calendar.desktop.in
        ${CMAKE_BINARY_DIR}/data/io.elementary.calendar-original.desktop.in
    APPDATA_FILES
        ${CMAKE_BINARY_DIR}/data/io.elementary.calendar.appdata.xml.in
)
