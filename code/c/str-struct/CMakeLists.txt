cmake_minimum_required(VERSION 3.7 FATAL_ERROR)
project(ffi-demo VERSION 1.0.0 LANGUAGES C)
add_library(structs_library SHARED structs.c structs.def)
target_link_libraries(structs_library PUBLIC m)
add_executable(structs_test structs.c)
target_link_libraries(structs_test PUBLIC m)

set_target_properties(structs_library PROPERTIES
    PUBLIC_HEADER structs.h
    VERSION ${PROJECT_VERSION}
    SOVERSION 1
    OUTPUT_NAME "structs"
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Hex_Identity_ID_Goes_Here"
)