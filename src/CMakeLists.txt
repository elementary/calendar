
set(CLIENT_VAPI ${SRC_TARGET})

set(CONFIG_FILE ${CMAKE_CURRENT_BINARY_DIR}/config.vala)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/config.vala.cmake ${CONFIG_FILE})
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/${CLIENT_VAPI}.pc.cmake ${CMAKE_CURRENT_BINARY_DIR}/${CLIENT_VAPI}.pc)

set(CLIENT_SOURCE
    ${CONFIG_FILE}
    Application.vala
    PluginManager.vala
    Model/CalendarModel.vala
    Services/Dexter.vala
    Settings/MayaSettings.vala
    Settings/SavedState.vala
    Settings/LanguagesFormat.vala
    Utils.vala
    Threads.vala
    View/Sidebar/AgendaView.vala
    View/Sidebar/Sidebar.vala
    View/Sidebar/SourceWidget.vala
    View/Sidebar/EventWidget.vala
    View/Grid/CalendarView.vala
    View/Grid/GridDay.vala
    View/Grid/Grid.vala
    View/Grid/EventButton/EventButton.vala
    View/Grid/EventButton/MultiDayEventButton.vala
    View/Grid/EventButton/SingleDayEventButton.vala
    View/Grid/WeekLabels.vala
    View/Grid/Header.vala
    View/Grid/VAutoHider.vala
    View/EventDialog.vala
    View/SourceDialog.vala
    View/MayaToolbar.vala
    View/SourceSelector.vala
    View/Widgets/ContractorButtonWithMenu.vala
    View/Widgets/DateSwitcher.vala
    View/Widgets/DateTimePicker.vala
    View/Widgets/Postler/GuestEntry.vala
    View/Widgets/Postler/FlowBox.vala
    View/Widgets/Postler/Contact.vala
    Backends/Backend.vala
    Backends/BackendsManager.vala
    Backends/LocalBackend.vala
    Backends/PlacementWidget.vala
)

vala_precompile(CLIENT_VALA_C ${SRC_TARGET}
    ${CLIENT_SOURCE}
PACKAGES
    ${DEPS_PACKAGES}
OPTIONS
    ${GLOBAL_VALAC_OPTIONS}
GENERATE_VAPI
    ${CLIENT_VAPI}
GENERATE_HEADER
    ${CLIENT_VAPI}
)

set(EXEC_NAME ${SRC_TARGET})

add_definitions(${DEPS_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS})
add_executable(${EXEC_NAME} ${CLIENT_VALA_C})

target_link_libraries(${EXEC_NAME} ${DEPS_LIBRARIES})

if (BUILD_SHARED_LIBS)
    install(TARGETS ${CLIENT_LIBRARY_NAME} DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR})
    # Install lib stuffs
    install (FILES ${CMAKE_BINARY_DIR}/src/${CLIENT_VAPI}.pc DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR}/pkgconfig/)
    install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${CLIENT_VAPI}.vapi DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/vala/vapi/)
    install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/${CLIENT_VAPI}.deps DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/vala/vapi/)
    install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${CLIENT_VAPI}.h DESTINATION ${CMAKE_INSTALL_FULL_INCLUDEDIR}/${CLIENT_VAPI}/)
endif ()

install(TARGETS ${EXEC_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_FULL_BINDIR})