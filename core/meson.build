config_data = configuration_data()
config_data.set('APP_NAME', 'Calendar')
config_data.set('EXEC_NAME', meson.project_name())
config_data.set('GETTEXT_PACKAGE', meson.project_name())
config_data.set('PLUGIN_DIR', pluginsdir)
config_data.set('VERSION', meson.project_version())

config_file = configure_file(
    configuration: config_data,
    input: 'config.vala.in',
    output: '@BASENAME@'
)

core_files = files(
    'Backends/Backend.vala',
    'Backends/BackendsManager.vala',
    'Backends/LocalBackend.vala',
    'Backends/PlacementWidget.vala',
    'Model/CalendarModel.vala',
    'Settings/MayaSettings.vala',
    'Settings/SavedState.vala',
    'Settings/LanguagesFormat.vala',
    'DateRange.vala',
    'Utils.vala',
    'GesturesUtils.vala'
)

core_deps = [
    glib_dep,
    granite_dep,
    gtk_dep,
    libecal_dep,
    libedataserver_dep,
    libedataserverui_dep,
    libical_dep,
    libsoup_dep,
    gmodule_dep,
    m_dep
]

core_lib = shared_library(
    'elementary-calendar',
    core_files,
    config_file,
    dependencies: core_deps,
    install: true,
    soversion: '0',
    version: '0.1'
)

core_dep = declare_dependency(
    link_with: core_lib,
    dependencies: core_deps,
    include_directories: include_directories('.')
)
