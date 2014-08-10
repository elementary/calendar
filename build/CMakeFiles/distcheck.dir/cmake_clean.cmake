FILE(REMOVE_RECURSE
  "CMakeFiles/distcheck"
)

# Per-language clean rules from dependency scanning.
FOREACH(lang)
  INCLUDE(CMakeFiles/distcheck.dir/cmake_clean_${lang}.cmake OPTIONAL)
ENDFOREACH(lang)
