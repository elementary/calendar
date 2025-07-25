project('io.elementary.calendar',
    'c', 'vala',
    version: '8.0.0',
    meson_version: '>=0.57.0'
)

add_project_arguments('-DGETTEXT_PACKAGE="@0@"'.format(meson.project_name()), language: 'c')

conf_data = configuration_data()
conf_data.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
conf_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: conf_data
)

libexecdir = join_paths(get_option('prefix'), get_option('libexecdir'), meson.project_name())
pluginsdir = join_paths(get_option('prefix'), get_option('libdir'), meson.project_name(), 'plugins')

gnome = import('gnome')
i18n = import('i18n')
pkgconfig = import('pkgconfig')

glib_dep = dependency('glib-2.0')
gee_dep = dependency('gee-0.8')
granite_dep = dependency('granite', version: '>=6.2.0')
gtk_dep = dependency('gtk+-3.0', version: '>=3.22')
handy_dep = dependency('libhandy-1', version: '>=0.90.0')
libedataserver_dep = dependency('libedataserver-1.2', version: '>=3.8.0')
libedataserverui_dep = dependency('libedataserverui-1.2', version: '>=3.46')
geocode_glib_dep = dependency('geocode-glib-2.0')
gmodule_dep = dependency('gmodule-2.0')
champlain_dep = dependency('champlain-0.12', fallback: ['libchamplain', 'libchamplain_dep'], default_options: ['default_library=static', 'introspection=false', 'vapi=false'])
champlain_gtk_dep = dependency('champlain-gtk-0.12', fallback: ['libchamplain', 'libchamplain_gtk_dep'], default_options: ['default_library=static', 'introspection=false', 'vapi=false'])
# We need to force the inclusion of the Vapi in case of fallback
if (champlain_dep.type_name() == 'internal')
    vapi_dir = meson.current_source_dir() / 'vapi'
    champlain_dep = [champlain_dep, meson.get_compiler('vala').find_library('champlain-0.12', dirs: vapi_dir)]
    champlain_gtk_dep = [champlain_gtk_dep, meson.get_compiler('vala').find_library('champlain-gtk-0.12', dirs: vapi_dir)]
endif
clutter_dep = dependency('clutter-1.0')
clutter_gtk_dep = dependency('clutter-gtk-1.0')
folks_dep = dependency('folks')
gclue_dep = dependency('libgeoclue-2.0')
libecal_dep = dependency('libecal-2.0')
libical_dep = dependency('libical-glib')
libportal_dep = [ dependency('libportal'), dependency('libportal-gtk3') ]

add_project_arguments('-DLIBICAL_GLIB_UNSTABLE_API=1', language: 'c')

m_dep = meson.get_compiler('c').find_library('m', required : false)

gresource_calendar = gnome.compile_resources(
    'gresource_calendar',
    join_paths('data', meson.project_name() + '.gresource.xml'),
    source_dir: 'data'
)

subdir('data')
subdir('core')
subdir('src')
subdir('plugins')
subdir('po')

gnome.post_install(
    glib_compile_schemas: true,
    gtk_update_icon_cache: true
)
