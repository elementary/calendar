pkg_check_modules(GOOGLE_DEPS libxml-2.0 json-glib-1.0 libsoup-2.4)

if (GOOGLE_DEPS_FOUND)

set(DEPS_CFLAGS ${DEPS_CFLAGS} ${GOOGLE_DEPS_CFLAGS})
set(DEPS_LIBRARIES ${DEPS_LIBRARIES} ${GOOGLE_DEPS_LIBRARIES})
set(DEPS_LIBRARY_DIRS ${DEPS_LIBRARY_DIRS} ${GOOGLE_DEPS_LIBRARY_DIRS})

add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})

set(TARGET_NAME google)
vala_precompile(GOOGLE_VALA_C ${TARGET_NAME}
    Google.vala
PACKAGES
    ${DEPS_PACKAGES}
    libxml-2.0
    json-glib-1.0
    libsoup-2.4
OPTIONS
    ${GLOBAL_VALAC_OPTIONS}
)

add_library(${TARGET_NAME} MODULE ${GOOGLE_VALA_C})

target_link_libraries(${TARGET_NAME} ${DEPS_LIBRARIES})
add_dependencies(${TARGET_NAME} ${SRC_TARGET})

install(TARGETS ${TARGET_NAME} DESTINATION ${PLUGIN_DIR}/Google/)
install(FILES google.plugin DESTINATION ${PLUGIN_DIR}/Google/)

else ()

message("-- Google plugin disabled")

endif ()
