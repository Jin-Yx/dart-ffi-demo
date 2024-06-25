cmake_minimum_required(VERSION 3.7 FATAL_ERROR)
project(ffi-demo VERSION 1.0.0 LANGUAGES C)
add_library(helloWorld SHARED hello.c hello.def)
add_executable(helloExec hello.c)

set_target_properties(helloWorld PROPERTIES
    PUBLIC_HEADER hello.h
    VERSION ${PROJECT_VERSION}
    SOVERSION 1
    OUTPUT_NAME "hello"
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "Hex_Identity_ID_Goes_Here"
)