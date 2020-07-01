tests_name = meson.project_name() + '-tests'

config = configuration_data()
config.set('source_dir', meson.source_root())

tests_files = files(
  'util-tests.vala'
)

core = declare_dependency(
    link_with: core_lib,
    dependencies: core_deps,
    include_directories: include_directories('..')
)

tests_deps = core_deps + [ core_dep ]

tests = executable(
  tests_name,
  tests_files,
  dependencies: tests_deps
)

test('Core tests', tests)
