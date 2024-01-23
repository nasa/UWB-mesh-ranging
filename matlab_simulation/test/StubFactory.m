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

classdef StubFactory

    
    properties
        
    end
    
    methods (Static)
        function this = StubFactory()

        end

        function [schedulerStub, schedulerBehaviour] = makeSchedulerStub(testCase)
            [schedulerStub, schedulerBehaviour] = createMock(testCase, "AddedMethods", ...
                ["pingScheduledToNow", ...
                "nothingScheduledYet", ...
                "scheduleNextPing", ...
                "cancelScheduledPing", ...
                "getSlotOfNextSchedule"]);
        end

        function [guardConditionsStub, guardConditionsBehaviour] = makeGuardConditionsStub(testCase)
            [guardConditionsStub, guardConditionsBehaviour] = createMock(testCase, "AddedMethods", ...
                ["listeningUncToSendingUncAllowed", ...
                "sendingUncToListeningConAllowed", ...
                "listeningConToSendingConAllowed", ...
                "sendingConToListeningConAllowed", ...
                "listeningConToListeningUncAllowed"]);
        end

        function [driverAbstractionLayerStub, driverAbstractionLayerBehaviour] = makeDriverAbstractionLayerStub(testCase)
            [driverAbstractionLayerStub, driverAbstractionLayerBehaviour] = createMock(testCase, "AddedMethods", ...
                ["sendingFinished", ...
                "transmitPing"]);
        end

        function [timeKeepingStub, timeKeepingBehaviour] = makeTimeKeepingStub(testCase)
            [timeKeepingStub, timeKeepingBehaviour] = createMock(testCase, "AddedMethods", ...
                ["initialWaitTimeOver", ...
                "recordPreamble", ...
                "calculateNetworkAgeForLastPreamble", ...
                "setFrameStartTimeForLastPreamble", ...
                "calculateCurrentSlotNum", ...
                "calculateOwnSlotAtTime", ...
                "calculateNextStartOfSlot", ...
                "calculateTimeSinceFrameStart"]);
        end

        function [clockStub, clockBehaviour] = makeClockStub(testCase)
            [clockStub, clockBehaviour] = createMock(testCase, "AddedMethods", ...
                ["getLocalTime"]);
        end

        function [stateActionsStub, stateActionsBehaviour] = makeStateActionsStub(testCase)
            [stateActionsStub, stateActionsBehaviour] = createMock(testCase, "AddedMethods", ...
                ["listeningUnconnectedTimeTicAction", ...
                "listeningConnectedTimeTicAction", ...
                "sendingUnconnectedTimeTicAction", ...
                "sendingConnectedTimeTicAction", ...
                "listeningUnconnectedIncomingMsgAction", ...
                "listeningConnectedIncomingMsgAction"]);
        end

        function [messageHandlerStub, messageHandlerBehaviour] = makeMessageHandlerStub(testCase)
            [messageHandlerStub, messageHandlerBehaviour] = createMock(testCase, "AddedMethods", ...
                ["sendPing", ...
                "sendInitialPing", ...
                "handlePingUnconnected", ...
                "handleCollisionUnconnected", ...
                "handlePreamble", ...
                "handlePingConnected", ...
                "handleCollisionConnected", ...
                "setId"]);
        end

        function [networkManagerStub, networkManagerBehaviour] = makeNetworkManagerStub(testCase)
            [networkManagerStub, networkManagerBehaviour] = createMock(testCase, "AddedMethods", ...
                ["setNetworkStatusToConnected", ...
                "setNetworkId", ...
                "saveNetworkAgeAtJoining", ...
                "isPingFromForeignNetwork", ...
                "isForeignNetworkPreceding", ...
                "getNetworkId", ...
                "calculateNetworkAge", ...
                "saveLocalTimeAtJoining", ...
                "setNodeId"]);
        end

        function [slotMapStub, slotMapBehaviour] = makeSlotMapStub(testCase)
            [slotMapStub, slotMapBehaviour] = createMock(testCase, "AddedMethods", ...
                ["updatePendingSlotAcks", ...
                "checkOwnSlotsForCollisions", ...
                "releaseOwnSlots", ...
                "checkPendingSlotsForCollisions", ...
                "releasePendingSlots", ...
                "updateOneHopSlotMap", ...
                "updateTwoHopSlotMap", ...
                "updateThreeHopSlotMap", ...
                "ownNetworkExists", ...
                "recordCollisionTime", ...
                "isOwnSlot", ...
                "isPendingSlot", ...
                "getOneHopSlotMap", ...
                "getTwoHopSlotMap", ...
                "getCollisionTimes", ...
                "addPendingSlot", ...
                "getOwnSlots", ...
                "slotReservationGoalMet", ...
                "getReservableSlot", ...
                "removeExpiredSlotsFromOneHopSlotMap", ...
                "removeExpiredSlotsFromTwoHopSlotMap", ...
                "removeExpiredSlotsFromThreeHopSlotMap", ...
                "removeExpiredPendingSlots", ...
                "removeExpiredOwnSlots", ...
                "addAcknowledgedPendingSlotsToOwn", ...
                "setId"]);
        end

        function [randomNumbersStub, randomNumbersBehaviour] = makeRandomNumbersStub(testCase)
            [randomNumbersStub, randomNumbersBehaviour] = createMock(testCase, "AddedMethods", ...
                ["getRandomIntBetween", ...
                "getRandomElementFrom"]);
        end

        function [stateMachineStub, stateMachineBehaviour] = makeStateMachineStub(testCase)
            [stateMachineStub, stateMachineBehaviour] = createMock(testCase, "AddedMethods", ...
                ["run", ...
                "getId", ...
                "getState"]);
        end

        function [communicationChannelStub, communicationChannelBehaviour] = makeCommunicationChannelStub(testCase)
            [communicationChannelStub, communicationChannelBehaviour] = createMock(testCase, "AddedMethods", ...
                ["execute"]);
        end
    end

end


