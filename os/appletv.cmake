# Copyright (c) 2014, Ruslan Baratov
# All rights reserved.

if(DEFINED POLLY_OS_APPLETV_CMAKE)
  return()
else()
  set(POLLY_OS_APPLETV_CMAKE 1)
endif()

include (CMakeForceCompiler)
CMAKE_FORCE_C_COMPILER (/usr/bin/gcc Apple)
CMAKE_FORCE_CXX_COMPILER (/usr/bin/g++ Apple)
set(CMAKE_AR ar CACHE FILEPATH "" FORCE)

# Skip the platform compiler checks for cross compiling
set (CMAKE_CXX_COMPILER_WORKS TRUE)
set (CMAKE_C_COMPILER_WORKS TRUE)
set (CMAKE_THREAD_LIBS_INIT YES)

# All iOS/Darwin specific settings - some may be redundant
set (CMAKE_SHARED_LIBRARY_PREFIX "lib")
set (CMAKE_SHARED_LIBRARY_SUFFIX ".tbd")
set (CMAKE_SHARED_MODULE_PREFIX "lib")
set (CMAKE_SHARED_MODULE_SUFFIX ".tbd")
set (CMAKE_MODULE_EXISTS 1)
set (CMAKE_DL_LIBS "")
set(CMAKE_FIND_LIBRARY_SUFFIXES ".tbd" ".dylib" ".so" ".a")

set (CMAKE_C_OSX_COMPATIBILITY_VERSION_FLAG "-compatibility_version ")
set (CMAKE_C_OSX_CURRENT_VERSION_FLAG "-current_version ")
set (CMAKE_CXX_OSX_COMPATIBILITY_VERSION_FLAG "${CMAKE_C_OSX_COMPATIBILITY_VERSION_FLAG}")
set (CMAKE_CXX_OSX_CURRENT_VERSION_FLAG "${CMAKE_C_OSX_CURRENT_VERSION_FLAG}")

set(MACOSX_BUNDLE_GUI_IDENTIFIER com.example)
set(CMAKE_MACOSX_BUNDLE YES)
set(CMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "iPhone Developer")

set(CMAKE_OSX_SYSROOT "appletvos" CACHE STRING "System root for AppleTV" FORCE)
set(CMAKE_XCODE_EFFECTIVE_PLATFORMS "-appletvos;-appletvsimulator")

# find 'appletvos' and 'appletvsimulator' roots and version
find_program(XCODE_SELECT_EXECUTABLE xcode-select)
if(NOT XCODE_SELECT_EXECUTABLE)
  polly_fatal_error("xcode-select not found")
endif()

if(XCODE_VERSION VERSION_LESS "5.0.0")
  polly_fatal_error("Works since Xcode 5.0.0 (current ver: ${XCODE_VERSION})")
endif()

if(CMAKE_VERSION VERSION_LESS "3.5")
  polly_fatal_error(
      "CMake minimum required version for iOS is 3.5 (current ver: ${CMAKE_VERSION})"
  )
endif()

string(COMPARE EQUAL "$ENV{DEVELOPER_DIR}" "" _is_empty)
if(NOT _is_empty)
  polly_status_debug("Developer root (env): $ENV{DEVELOPER_DIR}")
endif()

execute_process(
    COMMAND
    ${XCODE_SELECT_EXECUTABLE}
    "-print-path"
    OUTPUT_VARIABLE
    XCODE_DEVELOPER_ROOT # /.../Xcode.app/Contents/Developer
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

polly_status_debug("Developer root: ${XCODE_DEVELOPER_ROOT}")

find_program(XCODEBUILD_EXECUTABLE xcodebuild)
if(NOT XCODEBUILD_EXECUTABLE)
  polly_fatal_error("xcodebuild not found")
endif()

# Check version exists
execute_process(
    COMMAND
    "${XCODEBUILD_EXECUTABLE}"
    -showsdks
    -sdk
    "appletvos${IOS_SDK_VERSION}"
    RESULT_VARIABLE
    IOS_SDK_VERSION_RESULT
    OUTPUT_QUIET
    ERROR_QUIET
)
if(NOT "${IOS_SDK_VERSION_RESULT}" EQUAL 0)
  polly_fatal_error("iOS version `${IOS_SDK_VERSION}` not found (${IOS_SDK_VERSION_RESULT})")
endif()

# iPhone simulator root
set(
    IPHONESIMULATOR_ROOT
    "${XCODE_DEVELOPER_ROOT}/Platforms/AppleTVSimulator.platform/Developer"
)
if(NOT EXISTS "${IPHONESIMULATOR_ROOT}")
  polly_fatal_error(
      "IPHONESIMULATOR_ROOT not found (${IPHONESIMULATOR_ROOT})\n"
      "XCODE_DEVELOPER_ROOT: ${XCODE_DEVELOPER_ROOT}\n"
  )
endif()

# iPhone simulator SDK root
set(
    IPHONESIMULATOR_SDK_ROOT
    "${IPHONESIMULATOR_ROOT}/SDKs/AppleTVSimulator${IOS_SDK_VERSION}.sdk"
)

if(NOT EXISTS ${IPHONESIMULATOR_SDK_ROOT})
  polly_fatal_error(
      "IPHONESIMULATOR_SDK_ROOT not found (${IPHONESIMULATOR_SDK_ROOT})\n"
      "IPHONESIMULATOR_ROOT: ${IPHONESIMULATOR_ROOT}\n"
      "IOS_SDK_VERSION: ${IOS_SDK_VERSION}\n"
  )
endif()

# iPhone root
set(
    IPHONEOS_ROOT
    "${XCODE_DEVELOPER_ROOT}/Platforms/AppleTVOS.platform/Developer"
)
if(NOT EXISTS "${IPHONEOS_ROOT}")
  polly_fatal_error(
      "IPHONEOS_ROOT not found (${IPHONEOS_ROOT})\n"
      "XCODE_DEVELOPER_ROOT: ${XCODE_DEVELOPER_ROOT}\n"
  )
endif()

# iPhone SDK root
set(IPHONEOS_SDK_ROOT "${IPHONEOS_ROOT}/SDKs/AppleTVOS${IOS_SDK_VERSION}.sdk")

if(NOT EXISTS ${IPHONEOS_SDK_ROOT})
  hunter_fatal_error(
      "IPHONEOS_SDK_ROOT not found (${IPHONEOS_SDK_ROOT})\n"
      "IPHONEOS_ROOT: ${IPHONEOS_ROOT}\n"
      "IOS_SDK_VERSION: ${IOS_SDK_VERSION}\n"
  )
endif()

string(COMPARE EQUAL "${IOS_DEPLOYMENT_SDK_VERSION}" "" _is_empty)
if(_is_empty)
  set(
      CMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET
      "${IOS_SDK_VERSION}"
  )
else()
  set(
      CMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET
      "${IOS_DEPLOYMENT_SDK_VERSION}"
  )
endif()

# Emulate OpenCV toolchain --
set(IOS YES)
# -- end

# Set iPhoneOS architectures
set(archs "")
foreach(arch ${IPHONEOS_ARCHS})
  set(archs "${archs} ${arch}")
endforeach()
set(CMAKE_XCODE_ATTRIBUTE_ARCHS[sdk=appletvos*] "${archs}")
set(CMAKE_XCODE_ATTRIBUTE_VALID_ARCHS[sdk=appletvos*] "${archs}")

# Set iPhoneSimulator architectures
set(archs "")
foreach(arch ${IPHONESIMULATOR_ARCHS})
  set(archs "${archs} ${arch}")
endforeach()
set(CMAKE_XCODE_ATTRIBUTE_ARCHS[sdk=appletvsimulator*] "${archs}")
set(CMAKE_XCODE_ATTRIBUTE_VALID_ARCHS[sdk=appletvsimulator*] "${archs}")

# Introduced in iOS 9.0
set(CMAKE_XCODE_ATTRIBUTE_ENABLE_BITCODE YES)


# Set the find root to the iOS developer roots and to user defined paths
set (CMAKE_FIND_ROOT_PATH ${IPHONEOS_ROOT} ${IPHONEOS_SDK_ROOT} ${CMAKE_PREFIX_PATH} CACHE string  "iOS find search path root")

# default to searching for frameworks first
set (CMAKE_FIND_FRAMEWORK FIRST)


# set up the default search directories for frameworks
set (CMAKE_SYSTEM_FRAMEWORK_PATH
  ${IPHONEOS_SDK_ROOT}/System/Library/Frameworks
  ${IPHONEOS_SDK_ROOT}/System/Library/PrivateFrameworks
  ${IPHONEOS_SDK_ROOT}/Developer/Library/Frameworks
)

# only search the iOS sdks, not the remainder of the host filesystem
set (CMAKE_FIND_ROOT_PATH_MODE_PROGRAM ONLY)
set (CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set (CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
