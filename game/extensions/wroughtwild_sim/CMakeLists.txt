# Builds the wroughtwild_sim GDExtension: the sim/ rules library plus a thin
# godot-cpp binding. Output lands in game/bin/ where the .gdextension expects it.
#
#   cmake -S game/extensions/wroughtwild_sim -B build/gdext -G "MinGW Makefiles" \
#         -DCMAKE_BUILD_TYPE=Release
#   cmake --build build/gdext -j
cmake_minimum_required(VERSION 3.22)
project(wroughtwild_sim CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

get_filename_component(REPO_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../.." ABSOLUTE)
set(SIM_DIR "${REPO_ROOT}/sim")
set(GODOT_CPP_DIR "${REPO_ROOT}/third_party/godot-cpp")

if(NOT EXISTS "${GODOT_CPP_DIR}/CMakeLists.txt")
    message(FATAL_ERROR "godot-cpp submodule missing: run `git submodule update --init`")
endif()

# The sim library throws on malformed tuning and the binding catches it, so
# exceptions stay enabled through the whole extension.
set(GODOTCPP_DISABLE_EXCEPTIONS OFF CACHE BOOL "" FORCE)
add_subdirectory("${GODOT_CPP_DIR}" godot-cpp)

file(GLOB SIM_SOURCES CONFIGURE_DEPENDS "${SIM_DIR}/src/*.cpp")

add_library(wroughtwild_sim SHARED
    src/register_types.cpp
    src/wroughtwild_sim.cpp
    ${SIM_SOURCES})

target_include_directories(wroughtwild_sim PRIVATE "${SIM_DIR}/include" src)
target_link_libraries(wroughtwild_sim PRIVATE godot-cpp)
target_compile_options(wroughtwild_sim PRIVATE -Wall -Wextra)

if(MINGW)
    # Self-contained DLL: no libstdc++/libgcc/winpthread DLLs next to the editor.
    target_link_options(wroughtwild_sim PRIVATE -static -static-libgcc -static-libstdc++)
endif()

# File name matches the [libraries] table in game/bin/wroughtwild_sim.gdextension.
string(TOLOWER "${CMAKE_SYSTEM_NAME}" WW_PLATFORM)
if(WW_PLATFORM STREQUAL "darwin")
    set(WW_PLATFORM "macos")
endif()
set_target_properties(wroughtwild_sim PROPERTIES
    PREFIX "lib"
    OUTPUT_NAME "wroughtwild_sim.${WW_PLATFORM}.x86_64"
    RUNTIME_OUTPUT_DIRECTORY "${REPO_ROOT}/game/bin"
    LIBRARY_OUTPUT_DIRECTORY "${REPO_ROOT}/game/bin")
