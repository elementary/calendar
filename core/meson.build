config_data = configuration_data()
config_data.set('APP_NAME', 'Calendar')
config_data.set('EXEC_NAME', meson.project_name())
config_data.set('PLUGIN_DIR', pluginsdir)

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
    'Services/Calendar/Util/DateIterator.vala',
    'Services/Calendar/Util/DateRange.vala',
    'Services/Calendar/Util/DateTime.vala',
    'Services/Calendar/Util/ECalComponent.vala',
    'Services/Calendar/Util/ESource.vala',
    'Services/Calendar/Util/ICalComponent.vala',
    'Services/Calendar/Util/ICalTime.vala',
    'Utils.vala',
    'GesturesUtils.vala'
)

core_deps = [
    glib_dep,
    gee_dep,
    granite_dep,
    gtk_dep,
    libecal_dep,
    libedataserver_dep,
    libedataserverui_dep,
    libical_dep,
    libsoup_dep,
    gmodule_dep
]

core_lib = shared_library(
    'elementary-calendar',
    core_files,
    config_file,
    dependencies: [ core_deps, m_dep ],
    install: true,
    install_dir: [true, join_paths(get_option('includedir'), 'elementary-calendar'), true],
    soversion: '0',
    version: '0.1'
)

core_dep = declare_dependency(
    link_with: core_lib,
    dependencies: core_deps,
    include_directories: include_directories('.')
)

install_data(
    'elementary-calendar.deps',
    install_dir: join_paths(get_option('datadir'), 'vala', 'vapi')
)

pkgconfig.generate(
    core_lib,
    filebase: 'elementary-calendar',
    version: meson.project_version(),
    name: 'elementary Calendar',
    description: 'Extension endpoint to the Calendar application',
    subdirs: 'elementary-calendar',
    requires: core_deps
)

subdir('Tests')
