cmake_minimum_required(VERSION 3.14)
set(CMAKE_C_STANDARD 11)

set(CMAKE_CONFIGURATION_TYPES "Debug;Release")
set(CMAKE_XCODE_GENERATE_SCHEME TRUE)

set(GAME_NAME PlaydateTemplate)

# Game Name Customization
set(PLAYDATE_GAME_NAME PlaydateTemplate) #Set Project Name Here

set(PLAYDATE_GAME_DEVICE ${GAME_NAME}_DEVICE)

project(${PLAYDATE_GAME_NAME} C ASM)

if (TOOLCHAIN STREQUAL "armgcc")
	add_executable(${PLAYDATE_GAME_DEVICE} main.c)
else()
	add_library(${PLAYDATE_GAME_NAME} SHARED main.c )
endif()

# Allow SDK path to be specified via environment variable or CMake variable
if(DEFINED ENV{PLAYDATE_SDK_PATH})
	set(SDK $ENV{PLAYDATE_SDK_PATH})
elseif(DEFINED PLAYDATE_SDK_PATH)
	set(SDK ${PLAYDATE_SDK_PATH})
else()
	set(SDK ${PROJECT_SOURCE_DIR}/playdate)
endif()

include(${SDK}/C_API/buildsupport/playdate_game.cmake)

