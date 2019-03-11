daemon_deps = [
    core_dep,
    gee_dep,
    glib_dep,
    libecal_dep,
    libedataserver_dep,
    libedataserverui_dep,
    libical_dep,
    m_dep
]

executable(
    meson.project_name()+'-daemon',
    'Daemon.vala',
    dependencies: daemon_deps,
    install: true,
    install_dir: join_paths(get_option('prefix'), get_option('libexecdir'))
)
