cmake_minimum_required(VERSION 3.31)

set(NAME cpp-app-template)
set(NAMESPACE kayahr)

project(${NAME}
    VERSION 1.0.0
    DESCRIPTION "C++ app template"
    HOMEPAGE_URL "https://github.com/${NAMESPACE}/${NAME}"
    LANGUAGES CXX
)

include(GNUInstallDirs)
include(cmake/CompilerWarnings.cmake)
include(cmake/GitDeps.cmake)

set(CMAKE_CXX_STANDARD 26)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

option(BUILD_SHARED_LIBS "Build shared libraries" OFF)

git_require(kayahr::library-template v1.1.0 REPO_PREFIX cpp-)

file(GLOB_RECURSE MAIN_SOURCES CONFIGURE_DEPENDS
    src/*.cpp
)
list(REMOVE_ITEM MAIN_SOURCES
    "${CMAKE_CURRENT_SOURCE_DIR}/src/main.cpp"
)
list(SORT MAIN_SOURCES)

add_library(${NAME}-main STATIC
    ${MAIN_SOURCES}
)
target_include_directories(${NAME}-main PUBLIC
    "${CMAKE_CURRENT_SOURCE_DIR}/src"
)
target_link_libraries(${NAME}-main PRIVATE
    ${NAMESPACE}::library-template
)

add_executable(${NAME}
    src/main.cpp
)
target_link_libraries(${NAME} PRIVATE
    ${NAME}-main
)

file(GLOB SANDBOX_SOURCES CONFIGURE_DEPENDS
    sandbox/*.cpp
)
list(SORT SANDBOX_SOURCES)

foreach(SANDBOX_SOURCE IN LISTS SANDBOX_SOURCES)
    get_filename_component(SANDBOX_NAME "${SANDBOX_SOURCE}" NAME_WE)

    add_executable(sandbox-${SANDBOX_NAME}
        EXCLUDE_FROM_ALL
        "${SANDBOX_SOURCE}"
    )
    target_link_libraries(sandbox-${SANDBOX_NAME} PRIVATE
        ${NAME}-main
    )
endforeach()

set(CMAKE_SKIP_TEST_ALL_DEPENDENCY FALSE)
enable_testing()
find_package(GTest REQUIRED)
include(GoogleTest)

file(GLOB_RECURSE TEST_SOURCES CONFIGURE_DEPENDS
    test/*.cpp
)
list(SORT TEST_SOURCES)

add_executable(${NAME}-tests
    ${TEST_SOURCES}
)
target_link_libraries(${NAME}-tests PRIVATE
    ${NAME}-main
    GTest::gtest_main
)
gtest_discover_tests(${NAME}-tests)

install(TARGETS ${NAME}
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
)
