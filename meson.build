project('io.elementary.calendar',
    'c', 'vala',
    version: '5.1.1'
)

add_project_arguments([
    '-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()),
    '-DHANDY_USE_UNSTABLE_API'
    ],
    language: 'c'
)

libexecdir = join_paths(get_option('prefix'), get_option('libexecdir'), meson.project_name())
pluginsdir = join_paths(get_option('prefix'), get_option('libdir'), meson.project_name(), 'plugins')

gnome = import('gnome')
i18n = import('i18n')
pkgconfig = import('pkgconfig')

glib_dep = dependency('glib-2.0')
gee_dep = dependency('gee-0.8')
granite_dep = dependency('granite', version: '>=5.2.0')
gtk_dep = dependency('gtk+-3.0', version: '>=3.22')
handy_dep = dependency('libhandy-1', version: '>=0.90.0')
libedataserver_dep = dependency('libedataserver-1.2', version: '>=3.8.0')
libedataserverui_dep = dependency('libedataserverui-1.2', version: '>=3.8.0')
libsoup_dep = dependency('libsoup-2.4')
gmodule_dep = dependency('gmodule-2.0')
champlain_dep = dependency('champlain-0.12')
champlain_gtk_dep = dependency('champlain-gtk-0.12')
clutter_dep = dependency('clutter-1.0')
clutter_gtk_dep = dependency('clutter-gtk-1.0')
folks_dep = dependency('folks')
geocode_glib_dep = dependency('geocode-glib-1.0')
gclue_dep = dependency('libgeoclue-2.0')
libecal_dep = dependency('libecal-2.0', required: false)
if libecal_dep.found()
    libical_dep = dependency('libical-glib')
    add_project_arguments('--define=E_CAL_2_0', language: 'vala')
    add_project_arguments('-DLIBICAL_GLIB_UNSTABLE_API=1', language: 'c')
else
    libecal_dep = dependency('libecal-1.2', version: '>=3.8.0')
    libical_dep = dependency('libical')
    add_project_arguments('--vapidir', join_paths(meson.current_source_dir(), 'vapi'), language: 'vala')
endif

m_dep = meson.get_compiler('c').find_library('m', required : false)

gresource_calendar = gnome.compile_resources(
    'gresource_calendar',
    join_paths('data', meson.project_name() + '.gresource.xml'),
    source_dir: 'data'
)

subdir('data')
subdir('core')
subdir('daemon')
subdir('src')
subdir('plugins')
subdir('po')

meson.add_install_script('meson/post_install.py')
