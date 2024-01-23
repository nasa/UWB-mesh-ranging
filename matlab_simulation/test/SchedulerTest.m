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

classdef SchedulerTest < matlab.mock.TestCase

    properties
        scheduler;

        clockStub;
        clockBehaviour;
        timeKeepingStub;
        timeKeepingBehaviour;
        randomNumbersStub;
        randomNumbersBehaviour;
        slotMapStub;
        slotMapBehaviour;

        config;
    end

    methods(TestMethodSetup)
        function addSrcPath(testCase)
            addpath('../src');
        end

        function setUpTest(testCase)
            [testCase.clockStub, testCase.clockBehaviour] = StubFactory.makeClockStub(testCase);
            [testCase.timeKeepingStub, testCase.timeKeepingBehaviour] = StubFactory.makeTimeKeepingStub(testCase);
            [testCase.randomNumbersStub, testCase.randomNumbersBehaviour] = StubFactory.makeRandomNumbersStub(testCase);
            [testCase.slotMapStub, testCase.slotMapBehaviour] = StubFactory.makeSlotMapStub(testCase);

            currentTime = 0;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), currentTime);
            
            testCase.config.slotsPerFrame = 4;
            testCase.config.slotLength = 100;
            testCase.config.initialPingUpperLimit = 250;
            testCase.config.guardPeriodLength = 5;

            testCase.scheduler = Scheduler(testCase.clockStub, testCase.timeKeepingStub, testCase.randomNumbersStub, testCase.slotMapStub, testCase.config);
        end

    end

    methods(Test)

        function nothingScheduledOnCreation(testCase)
            nextPingScheduled = testCase.scheduler.getTimeNextPingScheduled();

            testCase.verifyEmpty(nextPingScheduled);
        end

%         function schedulePingToSpecifiedTime(testCase)
%             scheduleTime = 1;
%             wasSuccess = testCase.scheduler.schedulePingAtTime(scheduleTime);
% 
%             nextPingScheduled = testCase.scheduler.getTimeNextPingScheduled();
%             testCase.verifyTrue(wasSuccess);
%             testCase.verifyEqual(nextPingScheduled, scheduleTime);
%         end
% 
%         function schedulePingToTimeInPast(testCase)
%             % should not make schedule if time is in the past; should keep
%             % the current next schedule
%             currentTime = 7;
%             testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), currentTime);
% 
%             scheduleTime = 10;
%             wasSuccess = testCase.scheduler.schedulePingAtTime(scheduleTime);
% 
%             newScheduleTime = 5;
%             wasSuccess = testCase.scheduler.schedulePingAtTime(newScheduleTime);
% 
%             nextPingScheduled = testCase.scheduler.getTimeNextPingScheduled();
% 
%             testCase.verifyFalse(wasSuccess);
%             testCase.verifyEqual(nextPingScheduled, scheduleTime);
%         end
% 
%         function schedulePingToIntMax(testCase)
%             scheduleTime = 2147483647;
%             wasSuccess = testCase.scheduler.schedulePingAtTime(scheduleTime);
% 
%             nextPingScheduled = testCase.scheduler.getTimeNextPingScheduled();
%             testCase.verifyTrue(wasSuccess);
%             testCase.verifyEqual(nextPingScheduled, 2147483647);
%         end

        function returnIfPingIsScheduledToNow(testCase)
            scheduleTime = 42;
            wasSuccess = testCase.scheduler.schedulePingAtTime(scheduleTime);

            isScheduledToNow = testCase.scheduler.pingScheduledToNow();
            testCase.verifyFalse(isScheduledToNow);

            % set time
            currentTime = 42;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), currentTime);

            isScheduledToNow = testCase.scheduler.pingScheduledToNow();
            testCase.verifyTrue(isScheduledToNow);
        end

        function cancelScheduledPing(testCase)
            scheduleTime = 42;
            wasSuccess = testCase.scheduler.schedulePingAtTime(scheduleTime);

            wasSuccess = testCase.scheduler.cancelScheduledPing();

            nextPingScheduled = testCase.scheduler.getTimeNextPingScheduled();
            testCase.verifyEmpty(nextPingScheduled);
        end

        function noSuccessOnCancelWhenNothingScheduled(testCase)
            wasSuccess = testCase.scheduler.cancelScheduledPing();
            nextPingScheduled = testCase.scheduler.getTimeNextPingScheduled();
            testCase.verifyEmpty(nextPingScheduled);
            testCase.verifyFalse(wasSuccess);
        end

        function nothingScheduledYetWhenNothingScheduled(testCase)
            nothingScheduled = testCase.scheduler.nothingScheduledYet();

            testCase.verifyTrue(nothingScheduled);
        end

        function nothingScheduledYetWhenSomethingScheduled(testCase)
            testScheduleTime = 15;
            testCase.scheduler.schedulePingAtTime(testScheduleTime);

            nothingScheduled = testCase.scheduler.nothingScheduledYet();
            
            testCase.verifyFalse(nothingScheduled);
        end

        function nothingScheduledYetWhenCanceled(testCase)
            testScheduleTime = 15;
            testCase.scheduler.schedulePingAtTime(testScheduleTime);
            testCase.scheduler.cancelScheduledPing();

            nothingScheduled = testCase.scheduler.nothingScheduledYet();

            testCase.verifyTrue(nothingScheduled);
        end

        function getSlotOfNextPingScheduledUsesTimeKeeping(testCase) 
            import matlab.mock.constraints.WasCalled;
            testScheduleTime = 123;
            expectedSlot = 2;
            testCase.assignOutputsWhen(testCase.timeKeepingBehaviour.calculateOwnSlotAtTime(testScheduleTime), expectedSlot);
            testCase.scheduler.schedulePingAtTime(testScheduleTime);

            slot = testCase.scheduler.getSlotOfNextSchedule();
            testCase.verifyEqual(slot, expectedSlot);
        end

        function schedulePingListeningUncUsesCorrectBoundaries(testCase)
            import matlab.mock.constraints.WasCalled;

            currentTime = 444;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), currentTime);

            lb = currentTime;
            ub = currentTime + testCase.config.initialPingUpperLimit;

            testCase.scheduler.scheduleNextPing(States.LISTENING_UNCONNECTED);
            testCase.verifyThat(testCase.randomNumbersBehaviour.getRandomIntBetween(lb, ub), WasCalled('WithCount', 1));
        end

        function schedulePingListeningConRespectsGuardPeriodNextOwn(testCase)
            % schedule ping to next own slot when slot reservation goal is
            % met (no slots need to be reserved)
            testOwnSlots = 3;
            testCase.assignOutputsWhen(withExactInputs(testCase.slotMapBehaviour.getOwnSlots()), testOwnSlots);
            minDelay = 0;

            startTime = 1200;
            testCase.assignOutputsWhen(testCase.timeKeepingBehaviour.calculateNextStartOfSlot(testOwnSlots), startTime);
            testCase.assignOutputsWhen(withExactInputs(testCase.slotMapBehaviour.slotReservationGoalMet()), true);
            testCase.assignOutputsWhen(withAnyInputs(testCase.randomNumbersBehaviour.getRandomIntBetween()), minDelay);

            testCase.scheduler.scheduleNextPing(States.LISTENING_CONNECTED);

            nextSchedule = testCase.scheduler.getTimeNextPingScheduled();
            earliestScheduleTime = startTime + testCase.config.guardPeriodLength;
            testCase.verifyGreaterThanOrEqual(nextSchedule, earliestScheduleTime);
        end

        function schedulePingListeningConRespectsGuardPeriodNoOwnSlot(testCase)
            % schedule ping to random reservable slot when currently no own
            % slot
            testReservableSlot = 3;
            testSlotStart = 1500;
            minDelay = 0;

            testCase.assignOutputsWhen(withExactInputs(testCase.slotMapBehaviour.slotReservationGoalMet()), false);
            testCase.assignOutputsWhen(withExactInputs(testCase.slotMapBehaviour.getReservableSlot()), testReservableSlot);
            testCase.assignOutputsWhen(withAnyInputs(testCase.randomNumbersBehaviour.getRandomIntBetween()), minDelay);

            testCase.assignOutputsWhen(testCase.timeKeepingBehaviour.calculateNextStartOfSlot(testReservableSlot), testSlotStart);

            testCase.scheduler.scheduleNextPing(States.LISTENING_CONNECTED);

            nextSchedule = testCase.scheduler.getTimeNextPingScheduled();
            earliestScheduleTime = testSlotStart + testCase.config.guardPeriodLength;
            testCase.verifyGreaterThanOrEqual(nextSchedule, earliestScheduleTime);
        end

        function schedulePingListeningConOwnSlotNotScheduleTooLate(testCase)
            % schedule ping to next own slot when slot reservation goal is
            % met (no slots need to be reserved)
            testOwnSlots = 3;
            testCase.assignOutputsWhen(withExactInputs(testCase.slotMapBehaviour.getOwnSlots()), testOwnSlots);
            maxDelay = floor(testCase.config.slotLength - 2 * testCase.config.guardPeriodLength - MessageSizes.PING_SIZE)/MessageSizes.PING_SIZE;

            startTime = 1200;
            testCase.assignOutputsWhen(testCase.timeKeepingBehaviour.calculateNextStartOfSlot(testOwnSlots), startTime);
            testCase.assignOutputsWhen(withExactInputs(testCase.slotMapBehaviour.slotReservationGoalMet()), true);
            testCase.assignOutputsWhen(withAnyInputs(testCase.randomNumbersBehaviour.getRandomIntBetween()), maxDelay);

            testCase.scheduler.scheduleNextPing(States.LISTENING_CONNECTED);

            nextSchedule = testCase.scheduler.getTimeNextPingScheduled();
            latestScheduleTime = startTime + testCase.config.slotLength - testCase.config.guardPeriodLength - MessageSizes.PING_SIZE;
            testCase.verifyLessThanOrEqual(nextSchedule, latestScheduleTime);
        end

        function schedulePingListeningConNoOwnSlotNotScheduleTooLate(testCase)
            testReservableSlot = 3;
            testSlotStart = 1500;
            maxDelay = floor(testCase.config.slotLength - 2 * testCase.config.guardPeriodLength - MessageSizes.PING_SIZE)/MessageSizes.PING_SIZE;

            testCase.assignOutputsWhen(withExactInputs(testCase.slotMapBehaviour.slotReservationGoalMet()), false);
            testCase.assignOutputsWhen(withExactInputs(testCase.slotMapBehaviour.getReservableSlot()), testReservableSlot);
            testCase.assignOutputsWhen(withAnyInputs(testCase.randomNumbersBehaviour.getRandomIntBetween()), maxDelay);

            testCase.assignOutputsWhen(testCase.timeKeepingBehaviour.calculateNextStartOfSlot(testReservableSlot), testSlotStart);

            testCase.scheduler.scheduleNextPing(States.LISTENING_CONNECTED);

            nextSchedule = testCase.scheduler.getTimeNextPingScheduled();
            latestScheduleTime = testSlotStart + testCase.config.slotLength - testCase.config.guardPeriodLength - MessageSizes.PING_SIZE;
            testCase.verifyLessThanOrEqual(nextSchedule, latestScheduleTime);
        end

        function schedulePingAddsRandomDelayHasOwnSlot(testCase)
            % random delay is also a mutliple of MessageSizes.PING_SIZE
            testDelayFactor = 2;
            minDelay = 0;
            maxDelay = 8;

            testCase.assignOutputsWhen(testCase.randomNumbersBehaviour.getRandomIntBetween(minDelay, maxDelay), testDelayFactor);

            startTime = 1000;
            testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateNextStartOfSlot()), startTime);
            testCase.assignOutputsWhen(withExactInputs(testCase.slotMapBehaviour.slotReservationGoalMet()), true);

            testCase.scheduler.scheduleNextPing(States.LISTENING_CONNECTED);

            nextSchedule = testCase.scheduler.getTimeNextPingScheduled();
            scheduleTime = startTime + testCase.config.guardPeriodLength + testDelayFactor * MessageSizes.PING_SIZE;
            testCase.verifyEqual(nextSchedule, scheduleTime);
        end


        function schedulePingAddsRandomDelayNoOwnSlot(testCase)
            % random delay is also a mutliple of MessageSizes.PING_SIZE
            testDelayFactor = 2;
            minDelay = 0;
            maxDelay = 8;

            testCase.assignOutputsWhen(testCase.randomNumbersBehaviour.getRandomIntBetween(minDelay, maxDelay), testDelayFactor);

            startTime = 1000;
            testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateNextStartOfSlot()), startTime);
            testCase.assignOutputsWhen(withExactInputs(testCase.slotMapBehaviour.slotReservationGoalMet()), false);

            testCase.scheduler.scheduleNextPing(States.LISTENING_CONNECTED);

            nextSchedule = testCase.scheduler.getTimeNextPingScheduled();
            scheduleTime = startTime + testCase.config.guardPeriodLength + testDelayFactor * MessageSizes.PING_SIZE;
            testCase.verifyEqual(nextSchedule, scheduleTime);
        end

    end

end



