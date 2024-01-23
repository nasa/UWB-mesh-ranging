% /* Copyright (c) 2022-23 California Institute of Technology (Caltech).
%  * U.S. Government sponsorship acknowledged.
%  *
%  * All rights reserved.
%  *
%  * Redistribution and use in source and binary forms, with or without
%  * modification, are permitted provided that the following conditions are met:
%  *
%  * - Redistributions of source code must retain the above copyright notice,
%  *   this list of conditions and the following disclaimer.
%  * - Redistributions in binary form must reproduce the above copyright notice,
%  *   this list of conditions and the following disclaimer in the documentation
%  *   and/or other materials provided with the distribution.
%  * - Neither the name of Caltech nor its operating division,
%  *   the Jet Propulsion Laboratory, nor the names of its contributors may be
%  *   used to endorse or promote products derived from this software without
%  *   specific prior written permission.
%  *
%  * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%  * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%  * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
%  * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
%  * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
%  * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
%  * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
%  * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
%  * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
%  * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
%  * POSSIBILITY OF SUCH DAMAGE.
%  *
%  * Open Source License Approved by Caltech/JPL
%  *
%  * APACHE LICENSE, VERSION 2.0
%  * - Text version: https://www.apache.org/licenses/LICENSE-2.0.txt
%  * - SPDX short identifier: Apache-2.0
%  * - OSI Approved License: https://opensource.org/licenses/Apache-2.0
%  */

classdef TimeKeepingTest < matlab.mock.TestCase

    properties
        timeKeeping;

        clockStub;
        clockBehaviour;

        config;
    end

    methods(TestMethodSetup)
        function addSrcPath(testCase)
            addpath('../src');
        end

        function setUpTest(testCase)
            [testCase.clockStub, testCase.clockBehaviour] = StubFactory.makeClockStub(testCase);

            testCase.config.initialWaitTime = 1000;
            testCase.config.slotsPerFrame = 4;
            testCase.config.slotLength = 100;
            testCase.timeKeeping = TimeKeeping(testCase.clockStub, testCase.config);
        end
    end

    methods(Test)

        function waitTimeNotOver(testCase)
            currentTime = 999;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), currentTime);

            isOver = testCase.timeKeeping.initialWaitTimeOver();
                
            testCase.verifyFalse(isOver);
        end

        function waitTimeOver(testCase)
            currentTime = 1001;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), currentTime);

            isOver = testCase.timeKeeping.initialWaitTimeOver();
            
            testCase.verifyTrue(isOver);
        end

        function waitTimeExactlyOver(testCase)
            currentTime = 1000;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), currentTime);

            isOver = testCase.timeKeeping.initialWaitTimeOver();
            
            testCase.verifyTrue(isOver);
        end

        function waitTimeCanBeExtendedByReset(testCase)
            currentTime = 1000;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), currentTime);

            testCase.timeKeeping.resetTime();

            currentTime = 1999;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), currentTime);

            isOver = testCase.timeKeeping.initialWaitTimeOver();
            
            testCase.verifyFalse(isOver);
        end

        function canCurrentSlotIsSlotOne(testCase)
            currentTime = 1000;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), currentTime);
            
            testCase.timeKeeping.setFrameStartToTime(1000);

            currentSlot = testCase.timeKeeping.calculateCurrentSlotNum();

            testCase.verifyEqual(currentSlot, 1);
        end

        function canCurrentSlotIsSlotFour(testCase)
            currentTime = 1399;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), currentTime);
            
            testCase.timeKeeping.setFrameStartToTime(1000);

            currentSlot = testCase.timeKeeping.calculateCurrentSlotNum();

            testCase.verifyEqual(currentSlot, 4);
        end

        function canCurrentSlotIsSlotOneNextFrame(testCase)
            currentTime = 1400;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), currentTime);
            
            testCase.timeKeeping.setFrameStartToTime(1000);

            currentSlot = testCase.timeKeeping.calculateCurrentSlotNum();

            testCase.verifyEqual(currentSlot, 1);
        end

        function currentSlotIsOneIfNoFrameStartSet(testCase)
            currentTime = 1100;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), currentTime);
            
            currentSlot = testCase.timeKeeping.calculateCurrentSlotNum();

            testCase.verifyEqual(currentSlot, 1);
        end

        function calculateCurrentFrameIsFirstFrame(testCase)
            currentTime = 1000;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), currentTime);
            testCase.timeKeeping.setFrameStartToTime(1000);

            currentFrame = testCase.timeKeeping.calculateCurrentFrameNum();

            testCase.verifyEqual(currentFrame, 1);
        end

        function calculateCurrentFrameIsThirdFrame(testCase)
            currentTime = 1800;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), currentTime);
            testCase.timeKeeping.setFrameStartToTime(1000);

            currentFrame = testCase.timeKeeping.calculateCurrentFrameNum();

            testCase.verifyEqual(currentFrame, 3);
        end

        function calculateStartOfSlotInCurrentFrame(testCase)
            currentTime = 1000;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), currentTime);
            testCase.timeKeeping.setFrameStartToTime(1000);

            nextStart = testCase.timeKeeping.calculateNextStartOfSlot(2);
            
            testCase.verifyEqual(nextStart, 1100);
        end

        function calculateStartOfSlotInNextFrame(testCase)
            currentTime = 1100;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), currentTime);
            testCase.timeKeeping.setFrameStartToTime(1000);

            nextStart = testCase.timeKeeping.calculateNextStartOfSlot(1);
            
            testCase.verifyEqual(nextStart, 1400);
        end

        function calculateOwnSlotCurrentSlot(testCase)
            time = 1000;
            testCase.timeKeeping.setFrameStartToTime(1000);

            ownSlotAtTime = testCase.timeKeeping.calculateOwnSlotAtTime(time);
            testCase.verifyEqual(ownSlotAtTime, 1);
        end

        function calculateOwnSlotEndOfCurrentSlot(testCase)
            time = 1099;
            testCase.timeKeeping.setFrameStartToTime(1000);

            ownSlotAtTime = testCase.timeKeeping.calculateOwnSlotAtTime(time);
            testCase.verifyEqual(ownSlotAtTime, 1);
        end

        function calculateOwnSlotStartOfNextSlot(testCase)
            time = 1100;
            testCase.timeKeeping.setFrameStartToTime(1000);

            ownSlotAtTime = testCase.timeKeeping.calculateOwnSlotAtTime(time);
            testCase.verifyEqual(ownSlotAtTime, 2);
        end

        function calculateOwnSlotNextFrame(testCase)
            time = 1400;
            testCase.timeKeeping.setFrameStartToTime(1000);

            ownSlotAtTime = testCase.timeKeeping.calculateOwnSlotAtTime(time);
            testCase.verifyEqual(ownSlotAtTime, 1);
        end

        function calculateOwnSlotPreviousFrame(testCase)
            time = 1800;
            testCase.timeKeeping.setFrameStartToTime(2000);

            ownSlotAtTime = testCase.timeKeeping.calculateOwnSlotAtTime(time);
            testCase.verifyEqual(ownSlotAtTime, 3);
        end

        function calculateOwnSlotNegativeTimes(testCase)
            time = -199;
            testCase.timeKeeping.setFrameStartToTime(0);

            ownSlotAtTime = testCase.timeKeeping.calculateOwnSlotAtTime(time);
            testCase.verifyEqual(ownSlotAtTime, 3);
        end

        function recordIncomingPreambleTimeUseClock(testCase)
            time = 1111;
            testCase.assignOutputsWhen(withAnyInputs(testCase.clockBehaviour.getLocalTime()), time);

            recordTime = testCase.timeKeeping.recordPreamble();
            testCase.verifyEqual(recordTime, time);
        end

        function calculateNetAgeForLastPreamble(testCase)
            time = 1000;
            testCase.assignOutputsWhen(withAnyInputs(testCase.clockBehaviour.getLocalTime()), time);
            testCase.timeKeeping.recordPreamble();

            time = 1010;
            testCase.assignOutputsWhen(withAnyInputs(testCase.clockBehaviour.getLocalTime()), time);
            networkAgeAtLastPreamble = 100;

            networkAgeNow = testCase.timeKeeping.calculateNetworkAgeForLastPreamble(networkAgeAtLastPreamble);
            expectedNetworkAge = 110;
            
            testCase.verifyEqual(networkAgeNow, expectedNetworkAge);
        end

        function setFrameStartTimeForLastPreamble(testCase)
            time = 1000;
            testCase.assignOutputsWhen(withAnyInputs(testCase.clockBehaviour.getLocalTime()), time);
            testCase.timeKeeping.recordPreamble();

            timeNow = 1050;
            testCase.assignOutputsWhen(withAnyInputs(testCase.clockBehaviour.getLocalTime()), timeNow);
            
            timeSinceFrameStart = 100;
            testCase.timeKeeping.setFrameStartTimeForLastPreamble(timeSinceFrameStart);

            frameStart = testCase.timeKeeping.getFrameStartTime();
            expectedFrameStart = (time - timeSinceFrameStart);

            testCase.verifyEqual(frameStart, expectedFrameStart);
        end


%         function calculateSlotOffsetOneSlotOff(testCase)
%             % set current slot to 2
%             time = 1199;
%             testCase.assignOutputsWhen(withAnyInputs(testCase.clockBehaviour.getLocalTime()), time);
%             testCase.timeKeeping.recordPreamble();
%             testCase.timeKeeping.setFrameStartToTime(1000);
% 
% 
%             timeSinceFrameStartInMessage = 200; % other slot is 3
% 
%             offset = testCase.timeKeeping.calculateSlotOffset(timeSinceFrameStartInMessage);
%             expectedOffset = 1;
% 
%             testCase.verifyEqual(offset, expectedOffset);
%         end
% 
%         function calculateSlotOffsetMinusOneSlotOffGivesThree(testCase)
%             % set current slot to 2
%             time = 1199;
%             testCase.assignOutputsWhen(withAnyInputs(testCase.clockBehaviour.getLocalTime()), time);
%             testCase.timeKeeping.recordPreamble();
%             testCase.timeKeeping.setFrameStartToTime(1000);
% 
% 
%             timeSinceFrameStartInMessage = 0; % other slot is 1
% 
%             offset = testCase.timeKeeping.calculateSlotOffset(timeSinceFrameStartInMessage);
%             expectedOffset = 3;
% 
%             testCase.verifyEqual(offset, expectedOffset);
%         end
% 
%         function calculateSlotOffsetOneSlotOffWithPreamble(testCase)
%             % set slot to 2 when preamble was received
%             testCase.timeKeeping.setFrameStartToTime(1000);
% 
%             time = 1195;
%             testCase.assignOutputsWhen(withAnyInputs(testCase.clockBehaviour.getLocalTime()), time);
%             testCase.timeKeeping.recordPreamble();
% 
%             % set slot to 3 when message was complete
%             timeNow = 1205;
%             testCase.assignOutputsWhen(withAnyInputs(testCase.clockBehaviour.getLocalTime()), timeNow);
% 
%             timeSinceFrameStartInMessage = 200; % other slot is 3
% 
%             offset = testCase.timeKeeping.calculateSlotOffset(timeSinceFrameStartInMessage);
%             expectedOffset = 1;
% 
%             testCase.verifyEqual(offset, expectedOffset);
%         end
% 
%         function calculateSlotOffsetTestBoundary(testCase)
%             % set slot to 1 
%             testCase.timeKeeping.setFrameStartToTime(1000);
%             time = 1000;
%             testCase.assignOutputsWhen(withAnyInputs(testCase.clockBehaviour.getLocalTime()), time);
%             testCase.timeKeeping.recordPreamble();
% 
%             timeSinceFrameStartInMessage = 399; % other slot is 4
% 
%             offset = testCase.timeKeeping.calculateSlotOffset(timeSinceFrameStartInMessage);
%             expectedOffset = 3;
% 
%             testCase.verifyEqual(offset, expectedOffset);
%         end

        function nextStartOfSlotCalculationConsidersGuardPeriod(testCase)
            assumeFail(testCase);
        end

        function nextStartOfSlotCalculationConsidersDutyCycle(testCase)
            assumeFail(testCase);
        end

    end

end