set(CLIENT_SOURCE
    AgendaView.vala
    Application.vala
    ImportDialog.vala
    MainWindow.vala
    EventEdition/ContactImage.vala
    EventEdition/EventDialog.vala
    EventEdition/GuestsPanel.vala
    EventEdition/InfoPanel.vala
    EventEdition/LocationPanel.vala
    EventEdition/ReminderPanel.vala
    EventEdition/RepeatPanel.vala
    EventParser/EventParser.vala
    EventParser/EventParserHandler.vala
    EventParser/ParsedEvent.vala
    EventParser/Parsers/ParserDe.vala
    EventParser/Parsers/ParserEn.vala
    Grid/CalendarView.vala
    Grid/GridDay.vala
    Grid/Grid.vala
    Grid/EventButton.vala
    Grid/WeekLabels.vala
    Grid/Header.vala
    Grid/VAutoHider.vala
    SourceDialog/SourceDialog.vala
    SourceDialog/SourceItem.vala
    SourceDialog/SourceSelector.vala
    Widgets/CalendarButton.vala
    Widgets/ContractorButtonWithMenu.vala
    Widgets/DateSwitcher.vala
    Widgets/DateTimePicker.vala
    Widgets/DynamicSpinner.vala
    Widgets/HeaderBar.vala
)

vala_precompile(CLIENT_VALA_C ${CMAKE_PROJECT_NAME}
    ${CLIENT_SOURCE}
PACKAGES
    ${DEPS_PACKAGES}
OPTIONS
    ${GLOBAL_VALAC_OPTIONS}
)

include (GResource)
glib_compile_resources (GLIB_RESOURCES_MAYA ../data/maya.gresource.xml)

set(EXEC_NAME ${CMAKE_PROJECT_NAME})

add_definitions(${DEPS_CFLAGS} ${CORE_CFLAGS})
link_directories(${DEPS_LIBRARY_DIRS} ${CORE_LIBRARY_DIRS})
add_executable(${EXEC_NAME} ${CLIENT_VALA_C} ${GLIB_RESOURCES_MAYA})

target_link_libraries(${EXEC_NAME} ${DEPS_LIBRARIES} ${CORE_LIBRARIES} -lm)

install(TARGETS ${EXEC_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_FULL_BINDIR})
