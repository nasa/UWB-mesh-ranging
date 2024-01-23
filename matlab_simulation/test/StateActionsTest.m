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

classdef StateActionsTest < matlab.mock.TestCase

    properties
        stateActions;

        schedulerStub;
        schedulerBehaviour;
        timeKeepingStub;
        timeKeepingBehaviour;
        messageHandlerStub;
        messageHandlerBehaviour;
        slotMapStub;
        slotMapBehaviour;
        clockStub;
        clockBehaviour;
    end

    methods(TestMethodSetup)
        function addSrcPath(testCase)
            addpath('../src');
        end

        function setUpTest(testCase)
            [testCase.schedulerStub, testCase.schedulerBehaviour] = StubFactory.makeSchedulerStub(testCase);
            [testCase.timeKeepingStub, testCase.timeKeepingBehaviour] = StubFactory.makeTimeKeepingStub(testCase);
            [testCase.messageHandlerStub, testCase.messageHandlerBehaviour] = StubFactory.makeMessageHandlerStub(testCase);
            [testCase.slotMapStub, testCase.slotMapBehaviour] = StubFactory.makeSlotMapStub(testCase);
            [testCase.clockStub, testCase.clockBehaviour] = StubFactory.makeClockStub(testCase);

            testCase.stateActions = StateActions(testCase.schedulerStub, testCase.timeKeepingStub, testCase.messageHandlerStub, testCase.slotMapStub,testCase.clockStub);
        end

    end

    methods(Test)
        
        % listeningUnconnectedTimeTicAction
        function scheduleInitialPingWaitTimeOver(testCase)
            import matlab.mock.constraints.WasCalled;

            testCase.assignOutputsWhen(withExactInputs(testCase.timeKeepingBehaviour.initialWaitTimeOver()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.nothingScheduledYet()), true);
            
            testCase.stateActions.listeningUnconnectedTimeTicAction();

            testCase.verifyThat(testCase.schedulerBehaviour.scheduleNextPing(States.LISTENING_UNCONNECTED), WasCalled('WithCount', 1));
        end

        function dontScheduleInitialPingWaitTimeNotOver(testCase)
            testCase.assignOutputsWhen(withExactInputs(testCase.timeKeepingBehaviour.initialWaitTimeOver()), false);
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.nothingScheduledYet()), true);
            
            testCase.stateActions.listeningUnconnectedTimeTicAction();

            testCase.verifyNotCalled(withAnyInputs(testCase.schedulerBehaviour.scheduleNextPing()));
        end

        function dontScheduleInitialPingAlreadyScheduled(testCase)
            testCase.assignOutputsWhen(withExactInputs(testCase.timeKeepingBehaviour.initialWaitTimeOver()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.nothingScheduledYet()), false);
            
            testCase.stateActions.listeningUnconnectedTimeTicAction();

            testCase.verifyNotCalled(withAnyInputs(testCase.schedulerBehaviour.scheduleNextPing()));
        end

        % sendingUnconnectedTimeTicAction
        function sendPingWhenScheduled(testCase)
            import matlab.mock.constraints.WasCalled;
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.pingScheduledToNow()), true);

            testCase.stateActions.sendingUnconnectedTimeTicAction();

            testCase.verifyThat(withAnyInputs(testCase.messageHandlerBehaviour.sendInitialPing()), WasCalled('WithCount', 1));
        end

        function dontSendPingWhenNotScheduled(testCase)
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.pingScheduledToNow()), false);

            testCase.stateActions.sendingUnconnectedTimeTicAction();

            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.sendPing()));
        end

        function cancelScheduledWhenPingSent(testCase)
            import matlab.mock.constraints.WasCalled;
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.pingScheduledToNow()), true);

            testCase.stateActions.sendingUnconnectedTimeTicAction();

            testCase.verifyThat(withAnyInputs(testCase.schedulerBehaviour.cancelScheduledPing()), WasCalled('WithCount', 1));
        end

        function dontCancelScheduledWhenNotSent(testCase)
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.pingScheduledToNow()), false);

            testCase.stateActions.sendingUnconnectedTimeTicAction();

            testCase.verifyNotCalled(withAnyInputs(testCase.schedulerBehaviour.cancelScheduledPing()));
        end

        % listeningConnectedTimeTicAction
        function schedulePingIfNoneScheduled(testCase)
            import matlab.mock.constraints.WasCalled;
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.nothingScheduledYet()), true);
            
            testCase.stateActions.listeningConnectedTimeTicAction();

            testCase.verifyThat(testCase.schedulerBehaviour.scheduleNextPing(States.LISTENING_CONNECTED), WasCalled('WithCount', 1));
        end

        function dontSchedulePingIfAlreadyScheduled(testCase)
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.nothingScheduledYet()), false);
            
            testCase.stateActions.listeningConnectedTimeTicAction();

            testCase.verifyNotCalled(withAnyInputs(testCase.schedulerBehaviour.scheduleNextPing()));
        end

        function removeExpiredSlotsWhenNotIdledRecently(testCase)
            assumeFail(testCase)
        end

        function removeExpiredSlotsFromSlotMaps(testCase)
            import matlab.mock.constraints.WasCalled;
            
            localTime = 1000;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), localTime);
            testCase.stateActions.listeningConnectedTimeTicAction();

            testCase.verifyThat(testCase.slotMapBehaviour.removeExpiredSlotsFromOneHopSlotMap(localTime), WasCalled('WithCount', 1));
            testCase.verifyThat(testCase.slotMapBehaviour.removeExpiredSlotsFromTwoHopSlotMap(localTime), WasCalled('WithCount', 1));
            testCase.verifyThat(testCase.slotMapBehaviour.removeExpiredSlotsFromThreeHopSlotMap(localTime), WasCalled('WithCount', 1));
        end

        function removeUnacknowledgedPendingSlots(testCase)   
            import matlab.mock.constraints.WasCalled;
            localTime = 1000;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), localTime);

            testCase.stateActions.listeningConnectedTimeTicAction();

            testCase.verifyThat(testCase.slotMapBehaviour.removeExpiredPendingSlots(localTime), WasCalled('WithCount', 1));
        end

        function removeUnacknowledgedOwnSlots(testCase)   
            import matlab.mock.constraints.WasCalled;
            localTime = 1000;
            testCase.assignOutputsWhen(withExactInputs(testCase.clockBehaviour.getLocalTime()), localTime);
            
            testCase.stateActions.listeningConnectedTimeTicAction();

            testCase.verifyThat(testCase.slotMapBehaviour.removeExpiredOwnSlots(localTime), WasCalled('WithCount', 1));
        end

        function removeAbsentNodes(testCase)
            assumeFail(testCase);
        end


        % sendingConnectedTimeTicAction

        function sendPingWhenScheduledConnected(testCase)
            import matlab.mock.constraints.WasCalled;
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.pingScheduledToNow()), true);

            testCase.stateActions.sendingConnectedTimeTicAction();

            testCase.verifyThat(withAnyInputs(testCase.messageHandlerBehaviour.sendPing()), WasCalled('WithCount', 1));
        end

        function dontSendPingWhenNotScheduledConnected(testCase)
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.pingScheduledToNow()), false);

            testCase.stateActions.sendingConnectedTimeTicAction();

            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.sendPing()));
        end

        function cancelScheduledWhenPingSentConnected(testCase)
            import matlab.mock.constraints.WasCalled;
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.pingScheduledToNow()), true);

            testCase.stateActions.sendingConnectedTimeTicAction();

            testCase.verifyThat(withAnyInputs(testCase.schedulerBehaviour.cancelScheduledPing()), WasCalled('WithCount', 1));
        end

        function dontCancelScheduledWhenNotSentConnected(testCase)
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.pingScheduledToNow()), false);

            testCase.stateActions.sendingConnectedTimeTicAction();

            testCase.verifyNotCalled(withAnyInputs(testCase.schedulerBehaviour.cancelScheduledPing()));
        end 

%         function scheduleNextPingWhenSentConnected(testCase)
%             import matlab.mock.constraints.WasCalled;
%             testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.pingScheduledToNow()), true);
% 
%             testCase.stateActions.sendingConnectedTimeTicAction();
% 
%             testCase.verifyThat(withAnyInputs(testCase.schedulerBehaviour.schedulePing()), WasCalled('WithCount', 1));
%         end

        % listeningUnconnectedIncomingMsgAction

        function incomingPingUnconnected(testCase)
            import matlab.mock.constraints.WasCalled;

            msg.type = MessageTypes.PING;

            testCase.stateActions.listeningUnconnectedIncomingMsgAction(msg);

            testCase.verifyThat(testCase.messageHandlerBehaviour.handlePingUnconnected(msg), WasCalled('WithCount', 1));
        end

        function incomingCollisionUnconnected(testCase)
            import matlab.mock.constraints.WasCalled;

            msg.type = MessageTypes.COLLISION;

            testCase.stateActions.listeningUnconnectedIncomingMsgAction(msg);

            testCase.verifyThat(testCase.messageHandlerBehaviour.handleCollisionUnconnected(msg), WasCalled('WithCount', 1));
        end

        function incomingPreambleUnconnected(testCase)
            import matlab.mock.constraints.WasCalled;

            msg.type = MessageTypes.PREAMBLE;

            testCase.stateActions.listeningUnconnectedIncomingMsgAction(msg);

            testCase.verifyThat(testCase.messageHandlerBehaviour.handlePreamble(msg), WasCalled('WithCount', 1));
        end

        function dontCallUnrelatedMessageHandlerFunsPingUnc(testCase)
            msg.type = MessageTypes.PING;

            testCase.stateActions.listeningUnconnectedIncomingMsgAction(msg);

            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handleCollisionUnconnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handleCollisionConnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handlePingConnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handlePreamble()));
        end

        function dontCallUnrelatedMessageHandlerFunsCollisionUnc(testCase)
            msg.type = MessageTypes.COLLISION;

            testCase.stateActions.listeningUnconnectedIncomingMsgAction(msg);

            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handlePingUnconnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handlePingConnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handleCollisionConnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handlePreamble()));            
        end


        function dontCallUnrelatedMessageHandlerFunsPreambleUnc(testCase)
            msg.type = MessageTypes.PREAMBLE;

            testCase.stateActions.listeningUnconnectedIncomingMsgAction(msg);

            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handlePingUnconnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handlePingConnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handleCollisionUnconnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handleCollisionConnected()));
        end

        % listeningConnectedIncomingMsgAction

        function incomingPingConnected(testCase)
            import matlab.mock.constraints.WasCalled;

            msg.type = MessageTypes.PING;

            testCase.stateActions.listeningConnectedIncomingMsgAction(msg);

            testCase.verifyThat(testCase.messageHandlerBehaviour.handlePingConnected(msg), WasCalled('WithCount', 1));
        end

        function incomingCollisionConnected(testCase)
            import matlab.mock.constraints.WasCalled;

            msg.type = MessageTypes.COLLISION;

            testCase.stateActions.listeningConnectedIncomingMsgAction(msg);

            testCase.verifyThat(testCase.messageHandlerBehaviour.handleCollisionConnected(msg), WasCalled('WithCount', 1));
        end

        function incomingPreambleConnected(testCase)
            import matlab.mock.constraints.WasCalled;

            msg.type = MessageTypes.PREAMBLE;

            testCase.stateActions.listeningConnectedIncomingMsgAction(msg);

            testCase.verifyThat(testCase.messageHandlerBehaviour.handlePreamble(msg), WasCalled('WithCount', 1));
        end

        function dontCallUnrelatedMessageHandlerFunsPingCon(testCase)
            msg.type = MessageTypes.PING;

            testCase.stateActions.listeningConnectedIncomingMsgAction(msg);

            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handleCollisionUnconnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handleCollisionConnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handlePingUnconnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handlePreamble()));
        end

        function dontCallUnrelatedMessageHandlerFunsCollisionCon(testCase)
            msg.type = MessageTypes.COLLISION;

            testCase.stateActions.listeningConnectedIncomingMsgAction(msg);

            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handlePingUnconnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handlePingConnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handleCollisionUnconnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handlePreamble()));            
        end


        function dontCallUnrelatedMessageHandlerFunsPreambleCon(testCase)
            msg.type = MessageTypes.PREAMBLE;

            testCase.stateActions.listeningConnectedIncomingMsgAction(msg);

            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handlePingUnconnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handlePingConnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handleCollisionUnconnected()));
            testCase.verifyNotCalled(withAnyInputs(testCase.messageHandlerBehaviour.handleCollisionConnected()));
        end

        %% rangingPollTimeTicAction


        %% 


    end

end



