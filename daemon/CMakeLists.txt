#
# Libnotify
#
pkg_check_modules (LIBNOTIFY QUIET libnotify)
if (LIBNOTIFY_FOUND)
  message ("-- libnotify enabled")

  set (GLOBAL_VALAC_OPTIONS ${GLOBAL_VALAC_OPTIONS} --define=HAVE_LIBNOTIFY)

  set (DEPS_PACKAGES ${DEPS_PACKAGES} libnotify)

  set (DEPS_CFLAGS ${DEPS_CFLAGS} ${LIBNOTIFY_CFLAGS})
  set (DEPS_LIBRARIES ${DEPS_LIBRARIES} ${LIBNOTIFY_LIBRARIES})
  set (DEPS_LIBRARY_DIRS ${DEPS_LIBRARY_DIRS} ${LIBNOTIFY_LIBRARY_DIRS})
else ()
  message ("-- libnotify disabled")
endif ()

set(DAEMON_SOURCE
    Daemon.vala
)
set(DAEMON_EXEC_NAME ${CMAKE_PROJECT_NAME}-daemon)

vala_precompile(DAEMON_VALA_C ${DAEMON_EXEC_NAME}
    ${DAEMON_SOURCE}
PACKAGES
    ${DEPS_PACKAGES}
OPTIONS
    ${GLOBAL_VALAC_OPTIONS}
)


add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})
add_executable(${DAEMON_EXEC_NAME} ${DAEMON_VALA_C})

target_link_libraries(${DAEMON_EXEC_NAME} ${DEPS_LIBRARIES} -lm)

install(TARGETS ${DAEMON_EXEC_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_FULL_BINDIR})
