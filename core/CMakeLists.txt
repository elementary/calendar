set (CORE_LIB_VERSION 0.1)
set (CORE_LIB_SOVERSION 0)

set (CONFIG_FILE ${CMAKE_CURRENT_BINARY_DIR}/config.vala)
set (PC_FILE ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.pc)
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/config.vala.in ${CONFIG_FILE})
configure_file (${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.pc.in ${PC_FILE} @ONLY)

set (CORE_SOURCE
  ${CONFIG_FILE}
    Backends/Backend.vala
    Backends/BackendsManager.vala
    Backends/LocalBackend.vala
    Backends/PlacementWidget.vala
    Model/CalendarModel.vala
    Settings/MayaSettings.vala
    Settings/SavedState.vala
    Settings/LanguagesFormat.vala
    DateRange.vala
    Utils.vala
    GesturesUtils.vala
)

vala_precompile (CORE_VALA_C ${CORE_LIBRARY_NAME}
  ${CORE_SOURCE}
  PACKAGES
  ${CORE_PACKAGES}
  OPTIONS
  ${BASIC_VALAC_OPTIONS}
  GENERATE_VAPI
  ${CMAKE_PROJECT_NAME}
  GENERATE_HEADER
  ${CMAKE_PROJECT_NAME}
)

add_definitions (${CORE_CFLAGS})
link_directories (${CORE_LIBRARY_DIRS})

add_library (${CORE_LIBRARY_NAME} SHARED ${CORE_VALA_C})

set_target_properties (${CORE_LIBRARY_NAME} PROPERTIES
  PREFIX ""
  OUTPUT_NAME ${CORE_LIBRARY_NAME}
  VERSION ${CORE_LIB_VERSION}
  SOVERSION ${CORE_LIB_SOVERSION}
)

target_link_libraries (${CORE_LIBRARY_NAME} ${CORE_LIBRARIES})

install (TARGETS ${CORE_LIBRARY_NAME} DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR})
# Install lib stuffs
install (FILES ${CMAKE_BINARY_DIR}/core/${CMAKE_PROJECT_NAME}.pc DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR}/pkgconfig/)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.vapi DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/vala/vapi/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.deps DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/vala/vapi/)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.h DESTINATION ${CMAKE_INSTALL_FULL_INCLUDEDIR}/${CMAKE_PROJECT_NAME}/)
