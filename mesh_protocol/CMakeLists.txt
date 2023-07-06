# Copyright (c) 2022-23 California Institute of Technology (Caltech).
# U.S. Government sponsorship acknowledged.
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# - Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# - Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# - Neither the name of Caltech nor its operating division,
#   the Jet Propulsion Laboratory, nor the names of its contributors may be
#   used to endorse or promote products derived from this software without
#   specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# Open Source License Approved by Caltech/JPL
#
# APACHE LICENSE, VERSION 2.0
# - Text version: https://www.apache.org/licenses/LICENSE-2.0.txt
# - SPDX short identifier: Apache-2.0
# - OSI Approved License: https://opensource.org/licenses/Apache-2.0

cmake_minimum_required(VERSION 3.14)
project(mesh_net_protocol)

# GoogleTest requires at least C++11
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_C_STANDARD 11)

# include GoogleTest by downloading it from GitHub
include(FetchContent)
FetchContent_Declare(
  googletest
  URL https://github.com/google/googletest/archive/609281088cfefc76f9d0ce82e1ff6c30cc3591e5.zip
)
# For Windows: Prevent overriding the parent project's compiler/linker settings
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

# enable testing, add executables and link testing libs
enable_testing()

include_directories(
    ./test
    ./include
    ./src
)

set(BASE_DIR )

set(COMMON_SRC_FILES)
list(APPEND COMMON_SRC_FILES
    ${CMAKE_CURRENT_SOURCE_DIR}/include/StateMachine.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/StateMachine.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/Node.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/Node.c      
    ${CMAKE_CURRENT_SOURCE_DIR}/include/Message.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/Message.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/ProtocolClock.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/ProtocolClock.c      
    ${CMAKE_CURRENT_SOURCE_DIR}/include/Scheduler.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/Scheduler.c 
    ${CMAKE_CURRENT_SOURCE_DIR}/include/Driver.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/Driver.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/MessageHandler.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/MessageHandler.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/Neighborhood.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/Neighborhood.c   
    ${CMAKE_CURRENT_SOURCE_DIR}/include/Config.h
    ${CMAKE_CURRENT_SOURCE_DIR}/test/TestConfig.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/NetworkManager.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/NetworkManager.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/RangingManager.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/RangingManager.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/Util.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/Util.c
)


add_executable(
    statemachine_test
    ${COMMON_SRC_FILES}
    ${CMAKE_CURRENT_SOURCE_DIR}/include/TimeKeeping.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/TimeKeeping.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/Driver.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/Driver.c
    ${CMAKE_CURRENT_SOURCE_DIR}/test/StateMachineTest.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/test/TimeKeepingTest.cpp
)

add_executable(
    scheduler_test
    ${COMMON_SRC_FILES}
    ${CMAKE_CURRENT_SOURCE_DIR}/include/TimeKeeping.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/TimeKeeping.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/StateActions.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/StateActions.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/GuardConditions.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/GuardConditions.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/SlotMap.h
    ${CMAKE_CURRENT_SOURCE_DIR}/test/SchedulerTest.cpp
)

add_executable(
    networkmanager_test
    ${COMMON_SRC_FILES}    
    ${CMAKE_CURRENT_SOURCE_DIR}/include/TimeKeeping.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/TimeKeeping.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/StateActions.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/StateActions.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/GuardConditions.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/GuardConditions.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/SlotMap.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/SlotMap.c
    ${CMAKE_CURRENT_SOURCE_DIR}/test/NetworkManagerTest.cpp
)

add_executable(
    messagehandler_test
    ${COMMON_SRC_FILES}
    ${CMAKE_CURRENT_SOURCE_DIR}/include/TimeKeeping.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/TimeKeeping.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/MessageHandler.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/MessageHandler.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/StateActions.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/StateActions.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/GuardConditions.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/GuardConditions.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/SlotMap.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/SlotMap.c 
    ${CMAKE_CURRENT_SOURCE_DIR}/test/MessageHandlerTest.cpp
)

add_executable(
    slotmap_test
    ${COMMON_SRC_FILES}
    ${CMAKE_CURRENT_SOURCE_DIR}/include/TimeKeeping.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/TimeKeeping.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/StateActions.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/StateActions.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/GuardConditions.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/GuardConditions.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/SlotMap.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/SlotMap.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/RandomNumbers.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/RandomNumbers.c
    ${CMAKE_CURRENT_SOURCE_DIR}/include/LCG.h
    ${CMAKE_CURRENT_SOURCE_DIR}/src/LCG.c
    ${CMAKE_CURRENT_SOURCE_DIR}/test/SlotMapTest.cpp
)

target_link_libraries(
    statemachine_test
    gtest_main
    gtest
)

target_link_libraries(
    scheduler_test
    gtest_main
    gtest
)

target_link_libraries(
    networkmanager_test
    gtest_main
    gtest
)

target_link_libraries(
    messagehandler_test
    gtest_main
    gtest
)

target_link_libraries(
    slotmap_test
    gtest_main
    gtest
)

include(GoogleTest)
gtest_discover_tests(statemachine_test)
gtest_discover_tests(scheduler_test)
gtest_discover_tests(networkmanager_test)
gtest_discover_tests(messagehandler_test)
gtest_discover_tests(slotmap_test)
