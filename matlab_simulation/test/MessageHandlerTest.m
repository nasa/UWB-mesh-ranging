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

classdef MessageHandlerTest < matlab.mock.TestCase

    properties
        messageHandler;

        networkManagerStub;
        networkManagerBehaviour;
        timeKeepingStub;
        timeKeepingBehaviour;
        schedulerStub;
        schedulerBehaviour;
        slotMapStub;
        slotMapBehaviour;
        driverAbstractionLayerStub;
        driverAbstractionLayerBehaviour;
        clockStub;
        clockBehaviour;

        testPing;
    end

    methods(TestMethodSetup)
        function addSrcPath(testCase)
            addpath('../src');
        end

        function setUpTest(testCase)
            [testCase.networkManagerStub, testCase.networkManagerBehaviour] = StubFactory.makeNetworkManagerStub(testCase);
            [testCase.timeKeepingStub, testCase.timeKeepingBehaviour] = StubFactory.makeTimeKeepingStub(testCase);
            [testCase.schedulerStub, testCase.schedulerBehaviour] = StubFactory.makeSchedulerStub(testCase);
            [testCase.slotMapStub, testCase.slotMapBehaviour] = StubFactory.makeSlotMapStub(testCase);
            [testCase.driverAbstractionLayerStub, testCase.driverAbstractionLayerBehaviour] = StubFactory.makeDriverAbstractionLayerStub(testCase);
            [testCase.clockStub, testCase.clockBehaviour] = StubFactory.makeClockStub(testCase);

            testCase.messageHandler = MessageHandler(testCase.networkManagerStub, ...
                testCase.timeKeepingStub, testCase.schedulerStub, testCase.slotMapStub, ...
                testCase.driverAbstractionLayerStub, testCase.clockStub);

            testCase.testPing.type = MessageTypes.PING;
            testCase.testPing.networkAge = 100;
            testCase.testPing.networkId = 42;
            testCase.testPing.timeSinceFrameStart = 20;
        end
    end

    methods(Test)

        %% handle incoming ping unconnected
        function incomingPingUnconnectedSetNetworkToConnected(testCase)
            import matlab.mock.constraints.WasCalled;
            msg = testCase.testPing;

            testCase.messageHandler.handlePingUnconnected(msg);

            testCase.verifyThat(withAnyInputs(testCase.networkManagerBehaviour.setNetworkStatusToConnected()), WasCalled('WithCount', 1));
        end

        function incomingPingUnconnectedSetNetworkId(testCase)
            import matlab.mock.constraints.WasCalled;
            msg = testCase.testPing;

            testCase.messageHandler.handlePingUnconnected(msg);

            testCase.verifyThat(testCase.networkManagerBehaviour.setNetworkId(testCase.testPing.networkId), WasCalled('WithCount', 1));
        end

        function incomingPingUnconnectedSetNetworkAge(testCase)
            import matlab.mock.constraints.WasCalled;
            testAge = 42;
            testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateNetworkAgeForLastPreamble()), testAge);
            
            msg = testCase.testPing;

            testCase.messageHandler.handlePingUnconnected(msg);

            testCase.verifyThat(testCase.networkManagerBehaviour.saveNetworkAgeAtJoining(testAge), WasCalled('WithCount', 1));
        end

        function incomingPingUnconnectedSetFrameStart(testCase)
            import matlab.mock.constraints.WasCalled;
            
            msg = testCase.testPing;

            testCase.messageHandler.handlePingUnconnected(msg);

            testCase.verifyThat(testCase.timeKeepingBehaviour.setFrameStartTimeForLastPreamble(msg.timeSinceFrameStart), WasCalled('WithCount', 1));
        end

        function incomingPingUnconnectedCancelsSchedules(testCase)
            import matlab.mock.constraints.WasCalled;

            msg = testCase.testPing;

            testCase.messageHandler.handlePingUnconnected(msg);

            testCase.verifyThat(withExactInputs(testCase.schedulerBehaviour.cancelScheduledPing()), WasCalled('WithCount', 1));
        end

        %% handle incoming preamble
        function incomingPreambleRecordTime(testCase)
            import matlab.mock.constraints.WasCalled;
            % create message
            msg.type = MessageTypes.PREAMBLE;

            testCase.messageHandler.handlePreamble(msg);

            testCase.verifyThat(testCase.timeKeepingBehaviour.recordPreamble(msg), WasCalled('WithCount', 1));
        end

        %% handle incoming ping connected
        function incomingPingSameNetworkConnectedUpdateAcks(testCase)
            % update acknowledgements for own pending slots
            import matlab.mock.constraints.WasCalled;
            msg = testCase.testPing;
            
            testCase.messageHandler.handlePingConnected(msg);

            testCase.verifyThat(testCase.slotMapBehaviour.updatePendingSlotAcks(msg), WasCalled('WithCount', 1));
        end

        function incomingPingSameNetworkCheckOwnSlotCollisions(testCase)
            import matlab.mock.constraints.WasCalled;
            msg = testCase.testPing;
            
            testCase.messageHandler.handlePingConnected(msg);

            testCase.verifyThat(testCase.slotMapBehaviour.checkOwnSlotsForCollisions(msg), WasCalled('WithCount', 1));
        end

        function incomingPingSameNetworkReleaseCollidingOwnSlots(testCase)
            import matlab.mock.constraints.WasCalled;
            testCollidingSlots = 2;
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.checkOwnSlotsForCollisions()), testCollidingSlots);

            msg = testCase.testPing;
            
            testCase.messageHandler.handlePingConnected(msg);

            testCase.verifyThat(testCase.slotMapBehaviour.releaseOwnSlots(testCollidingSlots), WasCalled('WithCount', 1));
        end

        function incomingPingSameNetworkCheckPendingSlotCollisions(testCase)
            import matlab.mock.constraints.WasCalled;
            msg = testCase.testPing;
            
            testCase.messageHandler.handlePingConnected(msg);

            testCase.verifyThat(testCase.slotMapBehaviour.checkPendingSlotsForCollisions(msg), WasCalled('WithCount', 1));
        end

        function incomingPingSameNetworkReleaseCollidingPendingSlots(testCase)
            import matlab.mock.constraints.WasCalled;
            testCollidingSlots = 3;
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.checkPendingSlotsForCollisions()), testCollidingSlots);

            msg = testCase.testPing;
            
            testCase.messageHandler.handlePingConnected(msg);

            testCase.verifyThat(testCase.slotMapBehaviour.releasePendingSlots(testCollidingSlots), WasCalled('WithCount', 1));
        end

        function incomingPingSameNetworkUpdateOneHopSlots(testCase)
            import matlab.mock.constraints.WasCalled;
            msg = testCase.testPing;
            currentSlot = 3;
            localTime = 1333;
            testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateCurrentSlotNum()), currentSlot);
            testCase.assignOutputsWhen(withAnyInputs(testCase.clockBehaviour.getLocalTime()), localTime);

            testCase.messageHandler.handlePingConnected(msg);

            testCase.verifyThat(testCase.slotMapBehaviour.updateOneHopSlotMap(msg, currentSlot, localTime), WasCalled('WithCount', 1));
        end

        function incomingPingSameNetworkUpdateTwoHopSlots(testCase)
            import matlab.mock.constraints.WasCalled;
            msg = testCase.testPing;
            localTime = 1333;
            testCase.assignOutputsWhen(withAnyInputs(testCase.clockBehaviour.getLocalTime()), localTime);

            testCase.messageHandler.handlePingConnected(msg);

            testCase.verifyThat(testCase.slotMapBehaviour.updateTwoHopSlotMap(msg, localTime), WasCalled('WithCount', 1));
        end

        function incomingPingSameNetworkUpdateThreeHopSlots(testCase)
            import matlab.mock.constraints.WasCalled;
            msg = testCase.testPing;
            localTime = 1333;
            testCase.assignOutputsWhen(withAnyInputs(testCase.clockBehaviour.getLocalTime()), localTime);

            testCase.messageHandler.handlePingConnected(msg);

            testCase.verifyThat(testCase.slotMapBehaviour.updateThreeHopSlotMap(msg, localTime), WasCalled('WithCount', 1));
        end

        function cancelsScheduledPingSameNetwork(testCase)
            % if scheduled slot was released before
            import matlab.mock.constraints.WasCalled;
            testCollidingOwnSlots = 2;
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.checkOwnSlotsForCollisions()), testCollidingOwnSlots);
            testCollidingPendingSlots = 3;
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.checkPendingSlotsForCollisions()), testCollidingPendingSlots);
            
            nextScheduledSlot = 2;
            testCase.assignOutputsWhen(withAnyInputs(testCase.schedulerBehaviour.getSlotOfNextSchedule()), nextScheduledSlot);

            msg = testCase.testPing;

            testCase.messageHandler.handlePingConnected(msg);

            testCase.verifyThat(withExactInputs(testCase.schedulerBehaviour.cancelScheduledPing()), WasCalled('WithCount', 1));
        end

        function doesNotCancelScheduledPingSameNetwork(testCase)
            % if scheduled slot was not released before
            import matlab.mock.constraints.WasCalled;
            testCollidingOwnSlots = 2;
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.checkOwnSlotsForCollisions()), testCollidingOwnSlots);
            testCollidingPendingSlots = 3;
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.checkPendingSlotsForCollisions()), testCollidingPendingSlots);
            
            nextScheduledSlot = 4;
            testCase.assignOutputsWhen(withAnyInputs(testCase.schedulerBehaviour.getSlotOfNextSchedule()), nextScheduledSlot);

            msg = testCase.testPing;

            testCase.messageHandler.handlePingConnected(msg);

            testCase.verifyNotCalled(withAnyInputs(testCase.schedulerBehaviour.cancelScheduledPing()));
        end

%         function shiftSlotMapIfOtherNetworkPrecedes(testCase)
%             % in order to switch to the foreign network
%             import matlab.mock.constraints.WasCalled;
%             testCase.assignOutputsWhen(withAnyInputs(testCase.networkManagerBehaviour.isPingFromForeignNetwork()), true);
%             testCase.assignOutputsWhen(withAnyInputs(testCase.networkManagerBehaviour.isForeignNetworkPreceding()), true);
%             testSlotOffset = 2;
%             testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateSlotOffset()), testSlotOffset);
% 
%             msg = testCase.testPing;
% 
%             testCase.messageHandler.handlePingConnected(msg);
% 
%             testCase.verifyThat(testCase.slotMapBehaviour.shiftSlotMap(testSlotOffset), WasCalled('WithCount', 1));
%         end

%         function useTimeKeepingToCalculateSlotOffset(testCase)
%             import matlab.mock.constraints.WasCalled;
%             testCase.assignOutputsWhen(withAnyInputs(testCase.networkManagerBehaviour.isPingFromForeignNetwork()), true);
%             testCase.assignOutputsWhen(withAnyInputs(testCase.networkManagerBehaviour.isForeignNetworkPreceding()), true);
%             testSlotOffset = 3;
%             testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateSlotOffset()), testSlotOffset);
% 
%             msg = testCase.testPing;
% 
%             testCase.messageHandler.handlePingConnected(msg);
% 
%             testCase.verifyThat(testCase.timeKeepingBehaviour.calculateSlotOffset(msg), WasCalled('WithCount', 1));
%             testCase.verifyThat(testCase.slotMapBehaviour.shiftSlotMap(testSlotOffset), WasCalled('WithCount', 1));
%         end

%         function shiftOwnSlotsIfOtherNetworkPrecedes(testCase)
%             import matlab.mock.constraints.WasCalled;
%             testCase.assignOutputsWhen(withAnyInputs(testCase.networkManagerBehaviour.isPingFromForeignNetwork()), true);
%             testCase.assignOutputsWhen(withAnyInputs(testCase.networkManagerBehaviour.isForeignNetworkPreceding()), true);
%             testSlotOffset = 3;
%             testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateSlotOffset()), testSlotOffset);
% 
%             msg = testCase.testPing;
% 
%             testCase.messageHandler.handlePingConnected(msg);
% 
%             testCase.verifyThat(testCase.slotMapBehaviour.shiftOwnSlots(testSlotOffset), WasCalled('WithCount', 1));
%         end

        function allNetworkJoinFuncsCalledWhenOtherNetworkPrecedes(testCase)
            import matlab.mock.constraints.WasCalled;
            testCase.assignOutputsWhen(withAnyInputs(testCase.networkManagerBehaviour.isPingFromForeignNetwork()), true);
            testCase.assignOutputsWhen(withAnyInputs(testCase.networkManagerBehaviour.isForeignNetworkPreceding()), true);
            testAge = 42;
            testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateNetworkAgeForLastPreamble()), testAge);

            msg = testCase.testPing;

            testCase.messageHandler.handlePingConnected(msg);

            testCase.verifyThat(withAnyInputs(testCase.networkManagerBehaviour.setNetworkStatusToConnected()), WasCalled('WithCount', 1));
            testCase.verifyThat(testCase.networkManagerBehaviour.setNetworkId(testCase.testPing.networkId), WasCalled('WithCount', 1));
            testCase.verifyThat(testCase.networkManagerBehaviour.saveNetworkAgeAtJoining(testAge), WasCalled('WithCount', 1));
            testCase.verifyThat(testCase.timeKeepingBehaviour.setFrameStartTimeForLastPreamble(msg.timeSinceFrameStart), WasCalled('WithCount', 1));
            testCase.verifyThat(withExactInputs(testCase.schedulerBehaviour.cancelScheduledPing()), WasCalled('WithCount', 1));
        end

        function dontUpdateSlotsWhenForeignNetworkNotPrecedes(testCase)
            import matlab.mock.constraints.WasCalled;
            testCase.assignOutputsWhen(withAnyInputs(testCase.networkManagerBehaviour.isPingFromForeignNetwork()), true);
            testCase.assignOutputsWhen(withAnyInputs(testCase.networkManagerBehaviour.isForeignNetworkPreceding()), false);

            msg = testCase.testPing;

            testCase.messageHandler.handlePingConnected(msg);

            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.updatePendingSlotAcks()));
            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.checkOwnSlotsForCollisions()));
            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.releaseOwnSlots()));
            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.checkPendingSlotsForCollisions()));
            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.releasePendingSlots()));
            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.updateOneHopSlotMap()));
            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.updateTwoHopSlotMap()));
            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.updateThreeHopSlotMap()));
            testCase.verifyNotCalled(withAnyInputs(testCase.schedulerBehaviour.cancelScheduledPing()));
        end

        function ownNetworkNotExistsForeignNetworkNotPrecedes(testCase)
            % switch to foreign network if own network was not created
            % successfully, even it foreign network does not precede
            import matlab.mock.constraints.WasCalled;
            testCase.assignOutputsWhen(withAnyInputs(testCase.networkManagerBehaviour.isPingFromForeignNetwork()), true);
            testCase.assignOutputsWhen(withAnyInputs(testCase.networkManagerBehaviour.isForeignNetworkPreceding()), false);
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.ownNetworkExists()), false);
%             testSlotOffset = 3;
%             testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateSlotOffset()), testSlotOffset);
            testAge = 42;
            testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateNetworkAgeForLastPreamble()), testAge);
            msg = testCase.testPing;

            testCase.messageHandler.handlePingConnected(msg);

%             testCase.verifyThat(testCase.slotMapBehaviour.shiftSlotMap(testSlotOffset), WasCalled('WithCount', 1));
%             testCase.verifyThat(testCase.slotMapBehaviour.shiftOwnSlots(testSlotOffset), WasCalled('WithCount', 1));
            testCase.verifyThat(withAnyInputs(testCase.networkManagerBehaviour.setNetworkStatusToConnected()), WasCalled('WithCount', 1));
            testCase.verifyThat(testCase.networkManagerBehaviour.setNetworkId(testCase.testPing.networkId), WasCalled('WithCount', 1));
            testCase.verifyThat(testCase.networkManagerBehaviour.saveNetworkAgeAtJoining(testAge), WasCalled('WithCount', 1));
            testCase.verifyThat(testCase.timeKeepingBehaviour.setFrameStartTimeForLastPreamble(msg.timeSinceFrameStart), WasCalled('WithCount', 1));
            testCase.verifyThat(withExactInputs(testCase.schedulerBehaviour.cancelScheduledPing()), WasCalled('WithCount', 1));
        end

         function ownNetworkExistsForeignNetworkNotPrecedes(testCase)
            % do not switch if own network exists and foreign does not
            % precede
            import matlab.mock.constraints.WasCalled;
            testCase.assignOutputsWhen(withAnyInputs(testCase.networkManagerBehaviour.isPingFromForeignNetwork()), true);
            testCase.assignOutputsWhen(withAnyInputs(testCase.networkManagerBehaviour.isForeignNetworkPreceding()), false);
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.ownNetworkExists()), true);
%             testSlotOffset = 3;
%             testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateSlotOffset()), testSlotOffset);
            testAge = 42;
            testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateNetworkAgeForLastPreamble()), testAge);
            msg = testCase.testPing;

            testCase.messageHandler.handlePingConnected(msg);

            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.updatePendingSlotAcks()));
            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.checkOwnSlotsForCollisions()));
            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.releaseOwnSlots()));
            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.checkPendingSlotsForCollisions()));
            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.releasePendingSlots()));
            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.updateOneHopSlotMap()));
            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.updateTwoHopSlotMap()));
            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.updateThreeHopSlotMap()));
            testCase.verifyNotCalled(withAnyInputs(testCase.schedulerBehaviour.cancelScheduledPing()));

%             testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.shiftSlotMap()));
%             testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.shiftOwnSlots()));
            testCase.verifyNotCalled(withAnyInputs(testCase.networkManagerBehaviour.setNetworkStatusToConnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.networkManagerBehaviour.setNetworkId()));
            testCase.verifyNotCalled(withAnyInputs(testCase.networkManagerBehaviour.saveNetworkAgeAtJoining()));
            testCase.verifyNotCalled(withAnyInputs(testCase.timeKeepingBehaviour.setFrameStartTimeForLastPreamble()));
            testCase.verifyNotCalled(withAnyInputs(testCase.schedulerBehaviour.cancelScheduledPing()));
         end

         %% handle incoming collision unconnected
         function incomingCollisionUnconnectedRecordsTime(testCase)
            import matlab.mock.constraints.WasCalled;
            localTime = 1333;
            testCase.assignOutputsWhen(withAnyInputs(testCase.clockBehaviour.getLocalTime()), localTime);

            msg.type = MessageTypes.COLLISION;
            testCase.messageHandler.handleCollisionUnconnected(msg);

            testCase.verifyThat(testCase.slotMapBehaviour.recordCollisionTime(msg, localTime), WasCalled('WithCount', 1));
         end

         %% handle incoming collision connected
         function incomingCollisionConnectedUpdateOneHopSlots(testCase)
            import matlab.mock.constraints.WasCalled;

            msg.type = MessageTypes.COLLISION;
            currentSlot = 3;
            localTime = 1333;
            testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateCurrentSlotNum()), currentSlot);
            testCase.assignOutputsWhen(withAnyInputs(testCase.clockBehaviour.getLocalTime()), localTime);

            testCase.messageHandler.handleCollisionConnected(msg);

            testCase.verifyThat(testCase.slotMapBehaviour.updateOneHopSlotMap(msg, currentSlot, localTime), WasCalled('WithCount', 1));
         end

         function incomingCollisionConnectedRecordsTime(testCase)
            import matlab.mock.constraints.WasCalled;
            localTime = 1333;
            testCase.assignOutputsWhen(withAnyInputs(testCase.clockBehaviour.getLocalTime()), localTime);

            msg.type = MessageTypes.COLLISION;

            testCase.messageHandler.handleCollisionConnected(msg);

            testCase.verifyThat(testCase.slotMapBehaviour.recordCollisionTime(msg, localTime), WasCalled('WithCount', 1));
         end

         function releasesOwnSlotIfCollisionDuringOwnSlot(testCase)
            import matlab.mock.constraints.WasCalled;
            
            testCurrentSlot = 2;
            testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateCurrentSlotNum()), testCurrentSlot);
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.isOwnSlot()), true);
            msg.type = MessageTypes.COLLISION;

            testCase.messageHandler.handleCollisionConnected(msg);

            testCase.verifyThat(testCase.slotMapBehaviour.releaseOwnSlots(testCurrentSlot), WasCalled('WithCount', 1));
         end

         function dontReleaseOwnSlotIfCollisionNotDuringOwnSlot(testCase)
            import matlab.mock.constraints.WasCalled;
            testCurrentSlot = 2;
            testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateCurrentSlotNum()), testCurrentSlot);
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.isOwnSlot()), false);
           
            msg.type = MessageTypes.COLLISION;

            testCase.messageHandler.handleCollisionConnected(msg);

            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.releaseOwnSlots()));
         end

         function usesTimeKeepingToGetCurrentSlot(testCase)
            import matlab.mock.constraints.WasCalled;
            testCurrentSlot = 3;
            testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateCurrentSlotNum()), testCurrentSlot);
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.isOwnSlot()), true);
           
            msg.type = MessageTypes.COLLISION;

            testCase.messageHandler.handleCollisionConnected(msg);

            testCase.verifyThat(testCase.slotMapBehaviour.releaseOwnSlots(testCurrentSlot), WasCalled('WithCount', 1));
         end

         function releasesPendingSlotIfCollisionDuringOwnSlot(testCase)
            import matlab.mock.constraints.WasCalled;
            testCurrentSlot = 2;
            testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateCurrentSlotNum()), testCurrentSlot);
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.isPendingSlot()), true);
            msg.type = MessageTypes.COLLISION;

            testCase.messageHandler.handleCollisionConnected(msg);

            testCase.verifyThat(testCase.slotMapBehaviour.releasePendingSlots(testCurrentSlot), WasCalled('WithCount', 1));
         end

         function dontReleasePendingSlotIfCollisionNotDuringOwnSlot(testCase)
            import matlab.mock.constraints.WasCalled;
            testCurrentSlot = 2;
            testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateCurrentSlotNum()), testCurrentSlot);
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.isPendingSlot()), false);
           
            msg.type = MessageTypes.COLLISION;

            testCase.messageHandler.handleCollisionConnected(msg);

            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.releasePendingSlots()));
         end

         %% send ping
         function pingSentContainsCorrectInformation(testCase)
            import matlab.mock.constraints.WasCalled;

            testOneHopSlotMap.status = [1,0,1,0];
            testOneHopSlotMap.ids = [2,0,4,0];

            testTwoHopSlotMap.status = [0,1,0,1];
            testTwoHopSlotMap.ids = [0,2,0,4];
            testSenderId = 1;
            testNetworkId = 5;
            testNetworkAge = 10;
            testCollisionTimes = [100, 200];
            testTimeSinceFrameStart = 678;
                
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.getOneHopSlotMap()), testOneHopSlotMap);
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.getTwoHopSlotMap()), testTwoHopSlotMap);

            testCase.assignOutputsWhen(withAnyInputs(testCase.networkManagerBehaviour.getNetworkId()), testNetworkId);
            testCase.assignOutputsWhen(withAnyInputs(testCase.networkManagerBehaviour.calculateNetworkAge()), testNetworkAge);
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.getCollisionTimes()), testCollisionTimes);
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.isOwnSlot()), false);
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.isPendingSlot()), false);
            testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateTimeSinceFrameStart()), testTimeSinceFrameStart);
            
            msg.type = MessageTypes.PING;
            msg.senderId = testSenderId;
            msg.oneHopSlotsStatus = testOneHopSlotMap.status;
            msg.oneHopSlotsIds = testOneHopSlotMap.ids;
            msg.twoHopSlotsStatus = testTwoHopSlotMap.status;
            msg.twoHopSlotsIds = testTwoHopSlotMap.ids;

            msg.networkId = testNetworkId;
            msg.networkAge = testNetworkAge;
            msg.collisionTimes = testCollisionTimes;
            msg.timeSinceFrameStart = testTimeSinceFrameStart;

            testCase.messageHandler.setId(testSenderId);
            testCase.messageHandler.sendPing();

            testCase.verifyThat(testCase.driverAbstractionLayerBehaviour.transmitPing(msg), WasCalled('WithCount', 1));
         end

         function addSlotToPendingWhenNotAlreadyReserved(testCase)
            import matlab.mock.constraints.WasCalled;
            testCurrentSlot = 5;
            testNeighbors = [];
            localTime = 1234;

            oneHopSlotMap.status = [];
            oneHopSlotMap.ids = [];
            twoHopSlotMap.status = [];
            twoHopSlotMap.ids = [];

            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.getOneHopSlotMap()), oneHopSlotMap);
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.getTwoHopSlotMap()), twoHopSlotMap);
            testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateCurrentSlotNum()), testCurrentSlot);
            testCase.assignOutputsWhen(testCase.slotMapBehaviour.isOwnSlot(testCurrentSlot), false);
            testCase.assignOutputsWhen(testCase.slotMapBehaviour.isPendingSlot(testCurrentSlot), false);
            testCase.assignOutputsWhen(withAnyInputs(testCase.clockBehaviour.getLocalTime()), localTime);
            testCase.messageHandler.setId(42);

            testCase.messageHandler.sendPing();

            testCase.verifyThat(testCase.slotMapBehaviour.addPendingSlot(testCurrentSlot, testNeighbors, localTime), WasCalled('WithCount', 1));
         end

         function dontAddSlotToPendingWhenAlreadyPending(testCase)
             import matlab.mock.constraints.WasCalled;
            testCurrentSlot = 5;
            oneHopSlotMap.status = [];
            oneHopSlotMap.ids = [];
            twoHopSlotMap.status = [];
            twoHopSlotMap.ids = [];

            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.getOneHopSlotMap()), oneHopSlotMap);
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.getTwoHopSlotMap()), twoHopSlotMap);
            testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateCurrentSlotNum()), testCurrentSlot);
            testCase.assignOutputsWhen(testCase.slotMapBehaviour.isPendingSlot(testCurrentSlot), true);
            testCase.assignOutputsWhen(testCase.slotMapBehaviour.isOwnSlot(testCurrentSlot), false);
            testCase.messageHandler.setId(42);

            testCase.messageHandler.sendPing();

            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.addPendingSlot()));
         end
     
         function dontAddSlotToPendingWhenAlreadyOwn(testCase)
            import matlab.mock.constraints.WasCalled;
            testCurrentSlot = 5;
            oneHopSlotMap.status = [];
            oneHopSlotMap.ids = [];
            twoHopSlotMap.status = [];
            twoHopSlotMap.ids = [];

            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.getOneHopSlotMap()), oneHopSlotMap);
            testCase.assignOutputsWhen(withAnyInputs(testCase.slotMapBehaviour.getTwoHopSlotMap()), twoHopSlotMap);
            testCase.assignOutputsWhen(withAnyInputs(testCase.timeKeepingBehaviour.calculateCurrentSlotNum()), testCurrentSlot);
            testCase.assignOutputsWhen(testCase.slotMapBehaviour.isOwnSlot(testCurrentSlot), true);
            testCase.assignOutputsWhen(testCase.slotMapBehaviour.isPendingSlot(testCurrentSlot), false);
            testCase.messageHandler.setId(42);

            testCase.messageHandler.sendPing();

            testCase.verifyNotCalled(withAnyInputs(testCase.slotMapBehaviour.addPendingSlot()));
         end

    end
end
