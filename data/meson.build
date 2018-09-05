desktop_config = configuration_data()
desktop_config.set('EXEC_PATH', libexecdir+'-daemon')
configure_file (
    input: meson.project_name()+'-daemon' + '.desktop.in',
    output: meson.project_name()+'-daemon' + '.desktop',
    configuration: desktop_config,
    install_dir: join_paths(get_option('sysconfdir'), 'xdg', 'autostart')
)

install_data(
    meson.project_name() + '.gschema.xml',
    install_dir: join_paths(get_option('prefix'), get_option('datadir'), 'glib-2.0', 'schemas')
)

i18n.merge_file(
    input:  meson.project_name() + '.desktop.in',
    output:  meson.project_name() + '.desktop',
    po_dir: join_paths(meson.source_root (), 'po', 'extra'),
    type: 'desktop',
    install_dir: join_paths(get_option('datadir'), 'applications'),
    install: true
)

i18n.merge_file(
    input: meson.project_name() + '.appdata.xml.in',
    output: meson.project_name() + '.appdata.xml',
    po_dir: join_paths(meson.source_root (), 'po', 'extra'),
    install_dir: join_paths(get_option('datadir'), 'metainfo'),
    install: true
)
