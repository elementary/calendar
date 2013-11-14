pkg_check_modules (CALDAV_DEPS libsoup-2.4)

if (CALDAV_DEPS_FOUND)

set (DEPS_CFLAGS ${DEPS_CFLAGS} ${CALDAV_DEPS_CFLAGS})
set (DEPS_LIBRARIES ${DEPS_LIBRARIES} ${CALDAV_DEPS_LIBRARIES})
set (DEPS_LIBRARY_DIRS ${DEPS_LIBRARY_DIRS} ${CALDAV_DEPS_LIBRARY_DIRS})

add_definitions (${DEPS_CFLAGS})
link_directories (${DEPS_LIBRARY_DIRS})

set (TARGET_NAME caldav)
vala_precompile (CALDAV_VALA_C ${TARGET_NAME}
    CalDAV.vala
    CalDAVBackend.vala
PACKAGES
    ${DEPS_PACKAGES}
    libsoup-2.4
OPTIONS
    ${GLOBAL_VALAC_OPTIONS}
)

add_library (${TARGET_NAME} MODULE ${CALDAV_VALA_C})

target_link_libraries (${TARGET_NAME} ${DEPS_LIBRARIES})
add_dependencies (${TARGET_NAME} ${SRC_TARGET})

install (TARGETS ${TARGET_NAME} DESTINATION ${PLUGIN_DIR}/CalDAV/)
install (FILES caldav.plugin DESTINATION ${PLUGIN_DIR}/CalDAV/)

else ()

message("-- CalDAV plugin disabled")

endif ()
