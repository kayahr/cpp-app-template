# Small helper for kayahr-internal dependencies.
#
# Usage:
#
#   include(cmake/KayahrDeps.cmake)
#   kayahr_require(core v1.0.0)
#
# This first tries to use an installed CMake package named kayahr-core with a
# compatible version. If no installed package is found, it fetches the matching
# Git tag from https://github.com/kayahr/core.git via FetchContent.
#
# The first kayahr_require() call for a dependency selects the version for the
# whole build. Later calls for the same dependency must request the same major
# version and must not require a newer version than the selected one.
#
# Per dependency option:
#
#   -D KAYAHR_CORE_USE_SYSTEM=OFF
#
# disables find_package() for kayahr-core and forces FetchContent. The option is
# ON by default. Dependency names are converted to uppercase and non-alphanumeric
# characters become underscores, so "foo-bar" uses KAYAHR_FOO_BAR_USE_SYSTEM.

if(COMMAND kayahr_require)
    return()
endif()

include(FetchContent)

function(kayahr_require name tag)
    set(package "kayahr-${name}")
    set(target "kayahr::${name}")

    string(REGEX REPLACE "^v" "" required "${tag}")
    string(REGEX MATCH "^[0-9]+" required_major "${required}")
    string(TOUPPER "${name}" key)
    string(REGEX REPLACE "[^A-Z0-9]" "_" key "${key}")

    set(use_system_var "KAYAHR_${key}_USE_SYSTEM")
    option("${use_system_var}" "Use installed ${package} if available" ON)

    get_property(selected GLOBAL PROPERTY "KAYAHR_${key}_VERSION")
    if(selected)
        string(REGEX MATCH "^[0-9]+" selected_major "${selected}")
        if(NOT selected_major STREQUAL required_major)
            message(FATAL_ERROR
                "${package} v${selected} is already selected, "
                "but v${required} requires major version ${required_major}"
            )
        endif()

        if(selected VERSION_LESS required)
            message(FATAL_ERROR
                "${package} v${selected} is already selected, "
                "but v${required} or newer is required"
            )
        endif()

        if(TARGET "${target}")
            return()
        endif()
    endif()

    if(${use_system_var})
        find_package("${package}" "${required}" CONFIG QUIET)

        if(TARGET "${target}")
            set(actual "${required}")
            if(NOT "${${package}_VERSION}" STREQUAL "")
                set(actual "${${package}_VERSION}")
            endif()
            set_property(GLOBAL PROPERTY "KAYAHR_${key}_VERSION" "${actual}")
            return()
        endif()

        if("${${package}_FOUND}")
            message(FATAL_ERROR "${package} was found, but it did not define ${target}")
        endif()

        if(NOT "${${package}_CONSIDERED_CONFIGS}" STREQUAL "")
            message(FATAL_ERROR
                "Installed ${package} was found, but no compatible version for "
                "v${required}. Considered versions: ${${package}_CONSIDERED_VERSIONS}"
            )
        endif()
    endif()

    set_property(GLOBAL PROPERTY "KAYAHR_${key}_VERSION" "${required}")

    FetchContent_Declare(
        "${package}"
        GIT_REPOSITORY "https://github.com/kayahr/${name}.git"
        GIT_TAG "${tag}"
        GIT_SHALLOW TRUE
        EXCLUDE_FROM_ALL
    )
    FetchContent_MakeAvailable("${package}")

    if(NOT TARGET "${target}")
        message(FATAL_ERROR "${package} did not define ${target}")
    endif()
endfunction()
