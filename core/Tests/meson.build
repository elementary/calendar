tests_name = meson.project_name() + '-tests'

config = configuration_data()
config.set('source_dir', meson.source_root())

core = declare_dependency(
    link_with: core_lib,
    dependencies: core_deps,
    include_directories: include_directories('..')
)

tests_deps = core_deps + [ core_dep ]

util_tests = executable(
  tests_name,
  'util-tests.vala',
  dependencies: tests_deps
)
test('Utils Tests', util_tests, suite: 'core', is_parallel: false)

# We need these three locales to run the tests
locales = run_command('locale', '-a').stdout().split('\n')
if locales.contains ('en_GB.utf8') and locales.contains ('en_US.utf8') and locales.contains ('ar_AE.utf8')
    eventstore_tests = executable(
      tests_name + '-eventstore',
      'eventstore-tests.vala',
      dependencies: tests_deps
    )
    test('EventStore Tests', eventstore_tests, suite: 'core', is_parallel: false)
else
message('EventStore Tests have been disabled, a locale is missing in the system.')
endif
