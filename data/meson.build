icon_sizes = ['16', '24', '32', '48', '64', '128']

foreach i : icon_sizes
    install_data(
        join_paths('icons', i + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps'),
        rename: meson.project_name() + '.svg'
    )
    install_data(
        join_paths('icons', i + '.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'apps'),
        rename: meson.project_name() + '.svg'
    )
endforeach

action_sizes = ['16', '24']
foreach i : action_sizes
    install_data(
        join_paths('icons', i, 'event-new.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'actions'),
        rename: meson.project_name() + '.event-new.svg'
    )
    install_data(
        join_paths('icons', i, 'event-new.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i + '@2', 'actions'),
        rename: meson.project_name() + '.event-new.svg'
    )
endforeach

install_data(
    join_paths('icons', '16', 'event-new-symbolic.svg'),
    install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', 'scalable', 'actions'),
    rename: meson.project_name() + '.event-new-symbolic.svg'
)

install_data(
    meson.project_name() + '.gschema.xml',
    install_dir: join_paths(get_option('prefix'), get_option('datadir'), 'glib-2.0', 'schemas')
)

i18n.merge_file(
    input:  meson.project_name() + '.desktop.in',
    output:  meson.project_name() + '.desktop',
    po_dir: join_paths(meson.project_source_root (), 'po', 'extra'),
    type: 'desktop',
    install_dir: join_paths(get_option('datadir'), 'applications'),
    install: true
)

i18n.merge_file(
    input: 'calendar.metainfo.xml.in',
    output: meson.project_name() + '.metainfo.xml',
    po_dir: meson.source_root() / 'po' / 'extra',
    type: 'xml',
    install: true,
    install_dir: get_option('datadir') / 'metainfo',
)
