install_data(
    '../schemas/' + meson.project_name() + '.gschema.xml',
    install_dir: join_paths(get_option('prefix'), get_option('datadir'), 'glib-2.0', 'schemas')
)

i18n.merge_file(
    input:  meson.project_name() + '.desktop.in.in',
    output: meson.project_name() + '.desktop',
    po_dir: join_paths(meson.source_root (), 'po', 'extra'),
    type: 'desktop',
    install_dir: join_paths(get_option('datadir'), 'applications'),
    install: true
)

i18n.merge_file(
    input: meson.project_name() + '.appdata.xml.in.in',
    output: meson.project_name() + '.appdata.xml.in',
    po_dir: join_paths(meson.source_root (), 'po', 'extra'),
    install_dir: join_paths(get_option('datadir'), 'metainfo'),
    install: true
)

install_data(
    'io.elementary.calendar-daemon.desktop',
    install_dir: join_paths(get_option('datadir'), 'applications')
)
