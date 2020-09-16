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

eventstore_tests = executable(
  tests_name + '-eventstore',
  'eventstore-tests.vala',
  dependencies: tests_deps
)
test('EventStore Tests', eventstore_tests, suite: 'core', is_parallel: false)
