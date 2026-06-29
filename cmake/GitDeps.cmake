# Copyright (c) 2026 Klaus Reimer
# SPDX-License-Identifier: MIT
# Version: 1.0.0
# Source: https://github.com/kayahr/cmake-git-deps

if(COMMAND git_require)
    return()
endif()

include(FetchContent)

function(_git_normalize_version output value)
    string(REGEX REPLACE "^v" "" normalized "${value}")

    if(NOT normalized MATCHES "^[0-9]+(\\.[0-9]+)*$")
        message(FATAL_ERROR
            "Cannot derive a CMake package version from '${value}'. "
            "Pass VERSION explicitly."
        )
    endif()

    set("${output}" "${normalized}" PARENT_SCOPE)
endfunction()

function(git_require target)
    set(options)
    set(one_value_args PACKAGE REVISION URL VERSION USE_SYSTEM)
    set(multi_value_args)
    cmake_parse_arguments(ARG "${options}" "${one_value_args}" "${multi_value_args}" ${ARGN})

    if(ARG_UNPARSED_ARGUMENTS)
        list(LENGTH ARG_UNPARSED_ARGUMENTS unparsed_count)
        if(unparsed_count EQUAL 1 AND NOT DEFINED ARG_REVISION)
            list(GET ARG_UNPARSED_ARGUMENTS 0 ARG_REVISION)
        else()
            message(FATAL_ERROR "Invalid git_require() arguments: ${ARG_UNPARSED_ARGUMENTS}")
        endif()
    endif()

    if(NOT DEFINED ARG_REVISION)
        message(FATAL_ERROR "git_require(${target}) needs a REVISION or positional revision")
    endif()

    if(DEFINED ARG_VERSION)
        _git_normalize_version(required "${ARG_VERSION}")
    else()
        _git_normalize_version(required "${ARG_REVISION}")
    endif()

    if(target MATCHES "^([^:]+)::([^:]+)$")
        set(owner "${CMAKE_MATCH_1}")
        set(repo "${CMAKE_MATCH_2}")
    elseif(NOT DEFINED ARG_PACKAGE OR NOT DEFINED ARG_URL)
        message(FATAL_ERROR
            "Target '${target}' does not match '<owner>::<repo>'. "
            "Pass PACKAGE and URL explicitly."
        )
    endif()

    if(DEFINED ARG_PACKAGE)
        set(package "${ARG_PACKAGE}")
    else()
        set(package "${owner}-${repo}")
    endif()

    if(DEFINED ARG_URL)
        set(git_url "${ARG_URL}")
    else()
        set(git_url "https://github.com/${owner}/${repo}.git")
    endif()

    string(REGEX MATCH "^[0-9]+" required_major "${required}")
    string(TOUPPER "${target}" key)
    string(REGEX REPLACE "[^A-Z0-9]+" "_" key "${key}")
    string(REGEX REPLACE "^_+|_+$" "" key "${key}")

    set(use_system_var "GIT_${key}_USE_SYSTEM")
    option("${use_system_var}" "Use installed ${package} if available" ON)

    if(DEFINED ARG_USE_SYSTEM)
        set("${use_system_var}" "${ARG_USE_SYSTEM}")
    endif()

    get_property(selected GLOBAL PROPERTY "GIT_${key}_VERSION")
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

            string(REGEX MATCH "^[0-9]+" actual_major "${actual}")
            if(NOT actual_major STREQUAL required_major)
                message(FATAL_ERROR
                    "Installed ${package} v${actual} was found, "
                    "but v${required} requires major version ${required_major}"
                )
            endif()

            set_property(GLOBAL PROPERTY "GIT_${key}_VERSION" "${actual}")
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

    set_property(GLOBAL PROPERTY "GIT_${key}_VERSION" "${required}")

    FetchContent_Declare(
        "${package}"
        GIT_REPOSITORY "${git_url}"
        GIT_TAG "${ARG_REVISION}"
        EXCLUDE_FROM_ALL
    )
    FetchContent_MakeAvailable("${package}")

    if(NOT TARGET "${target}")
        message(FATAL_ERROR "${package} did not define ${target}")
    endif()
endfunction()
