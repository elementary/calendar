set(CLIENT_SOURCE
    Application.vala
    SourceDialog.vala
    SourceItem.vala
    MayaToolbar.vala
    SourceSelector.vala
    EventEdition/ContactImage.vala
    EventEdition/EventDialog.vala
    EventEdition/GuestsPanel.vala
    EventEdition/InfoPanel.vala
    EventEdition/LocationPanel.vala
    EventEdition/ReminderPanel.vala
    EventEdition/RepeatPanel.vala
    Grid/CalendarView.vala
    Grid/GridDay.vala
    Grid/Grid.vala
    Grid/EventButton/EventButton.vala
    Grid/EventButton/MultiDayEventButton.vala
    Grid/EventButton/SingleDayEventButton.vala
    Grid/WeekLabels.vala
    Grid/Header.vala
    Grid/VAutoHider.vala
    Sidebar/AgendaView.vala
    Sidebar/Sidebar.vala
    Sidebar/SourceWidget.vala
    Sidebar/EventWidget.vala
    Widgets/ContractorButtonWithMenu.vala
    Widgets/DateSwitcher.vala
    Widgets/DateTimePicker.vala
    Widgets/DynamicSpinner.vala
)

vala_precompile(CLIENT_VALA_C ${CMAKE_PROJECT_NAME}
    ${CLIENT_SOURCE}
PACKAGES
    ${DEPS_PACKAGES}
OPTIONS
    ${GLOBAL_VALAC_OPTIONS}
)

set(EXEC_NAME ${CMAKE_PROJECT_NAME})

add_definitions(${DEPS_CFLAGS} ${CORE_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS} ${CORE_LIBRARY_DIRS})
add_executable(${EXEC_NAME} ${CLIENT_VALA_C})

target_link_libraries(${EXEC_NAME} ${DEPS_LIBRARIES} ${CORE_LIBRARIES} -lm)

install(TARGETS ${EXEC_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_FULL_BINDIR})