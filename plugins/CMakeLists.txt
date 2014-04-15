option (BUILD_PLUGINS "Whether to build plugins or not." ON)

if (BUILD_PLUGINS)
    message("-- Plugins enabled")

    add_subdirectory (CalDAV)
    add_subdirectory (Google)
else ()
    message("-- Plugins disabled")
endif ()
