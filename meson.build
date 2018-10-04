project('io.elementary.calendar',
    'c', 'vala',
    version: '4.2.2'
)

add_project_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language: 'c')
add_project_arguments('--vapidir', join_paths(meson.current_source_dir(), 'vapi'), language: 'vala')

libexecdir = join_paths(get_option('prefix'), get_option('libexecdir'), meson.project_name())
pluginsdir = join_paths(get_option('prefix'), get_option('libdir'), meson.project_name(), 'plugins')

gnome = import('gnome')
i18n = import('i18n')
pkgconfig = import('pkgconfig')

glib_dep = dependency('glib-2.0')
gee_dep = dependency('gee-0.8')
granite_dep = dependency('granite', version: '>=0.5')
gtk_dep = dependency('gtk+-3.0', version: '>=3.22')
libecal_dep = dependency('libecal-1.2', version: '>=3.8.0')
libedataserver_dep = dependency('libedataserver-1.2', version: '>=3.8.0')
libedataserverui_dep = dependency('libedataserverui-1.2', version: '>=3.8.0')
libical_dep = dependency('libical')
libsoup_dep = dependency('libsoup-2.4')
gmodule_dep = dependency('gmodule-2.0')
champlain_dep = dependency('champlain-0.12')
champlain_gtk_dep = dependency('champlain-gtk-0.12')
clutter_dep = dependency('clutter-1.0')
clutter_gtk_dep = dependency('clutter-gtk-1.0')
folks_dep = dependency('folks')
geocode_glib_dep = dependency('geocode-glib-1.0')
gclue_dep = dependency('libgeoclue-2.0')

m_dep = meson.get_compiler('c').find_library('m', required : false)
libnotify_dep = dependency('libnotify', required: false)

if libnotify_dep.found()
    add_project_arguments('--define=HAVE_LIBNOTIFY', language: 'vala')
endif

gresource_calendar = gnome.compile_resources(
    'gresource_calendar',
    'data/maya.gresource.xml',
    source_dir: 'data'
)

subdir('data')
subdir('core')
subdir('daemon')
subdir('src')
subdir('plugins')
subdir('po')

meson.add_install_script('meson/post_install.py')
