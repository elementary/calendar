pkg_check_modules (GOOGLE_DEPS QUIET libsoup-2.4)
if (GOOGLE_DEPS_FOUND)

set (GOOGLE_CFLAGS ${CORE_CFLAGS} ${GOOGLE_DEPS_CFLAGS})
set (GOOGLE_LIBRARIES ${CORE_LIBRARIES} ${CORE_LIBRARY_NAME} ${GOOGLE_DEPS_LIBRARIES})
set (GOOGLE_LIBRARY_DIRS ${CORE_LIBRARY_DIRS} ${GOOGLE_DEPS_LIBRARY_DIRS})

add_definitions (${GOOGLE_CFLAGS})
link_directories (${GOOGLE_LIBRARY_DIRS})

set (TARGET_NAME google)
vala_precompile (GOOGLE_VALA_C ${TARGET_NAME}
    GoogleBackend.vala
PACKAGES
    ${CORE_PACKAGES}
    ${CMAKE_PROJECT_NAME}
    libsoup-2.4
OPTIONS
    ${GLOBAL_VALAC_OPTIONS}
)

add_library (${TARGET_NAME} MODULE ${GOOGLE_VALA_C})

target_link_libraries (${TARGET_NAME} ${GOOGLE_LIBRARIES})
add_dependencies (${TARGET_NAME} ${CMAKE_PROJECT_NAME})

install (TARGETS ${TARGET_NAME} DESTINATION ${PLUGIN_DIR}/Google/)

else ()

message("-- Google plugin disabled")

endif ()