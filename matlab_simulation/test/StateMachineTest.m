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

classdef StateMachineTest < matlab.mock.TestCase

    properties
        stateMachine;

        schedulerStub;
        schedulerBehaviour;
        guardConditionsStub;
        guardConditionsBehaviour;
        driverAbstractionLayerStub;
        driverAbstractionLayerBehaviour;
        timeKeepingStub;
        timeKeepingBehaviour;
        stateActionsStub;
        stateActionsBehaviour;
    end

    methods(TestMethodSetup)
        function addSrcPath(testCase)
            addpath('../src');
        end

        function setUpTest(testCase)
            % create stubs
            [testCase.schedulerStub, testCase.schedulerBehaviour] = StubFactory.makeSchedulerStub(testCase);
            [testCase.guardConditionsStub, testCase.guardConditionsBehaviour] = StubFactory.makeGuardConditionsStub(testCase);
            [testCase.driverAbstractionLayerStub, testCase.driverAbstractionLayerBehaviour] = StubFactory.makeDriverAbstractionLayerStub(testCase);
            [testCase.timeKeepingStub, testCase.timeKeepingBehaviour] = StubFactory.makeTimeKeepingStub(testCase);
            [testCase.stateActionsStub, testCase.stateActionsBehaviour] = StubFactory.makeStateActionsStub(testCase);

            testCase.stateMachine = StateMachine(testCase.schedulerStub, ...
                testCase.guardConditionsStub, ...
                testCase.driverAbstractionLayerStub, ...
                testCase.timeKeepingStub, ...
                testCase.stateActionsStub);
        end
    end

    methods(TestMethodTeardown)
        function clearPersistenVariables(testCase)
            StateMachine.getNewId(1); % clear the counter
        end
    end

    methods(Test)
        
        function offOnCreation(testCase)
            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.OFF);
        end

        function noStateChangeOnTimeTicWhenOff(testCase)
            testCase.stateMachine.run(Events.TIME_TIC);

            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.OFF);
        end

        function noStateChangeOnIncomingMsgWhenOff(testCase)
            testCase.stateMachine.run(Events.INCOMING_MSG);

            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.OFF)
        end

        function hasIdAfterTurnedOn(testCase)
            testCase.stateMachine.run(Events.TURN_ON);
            id = testCase.stateMachine.getId();
            testCase.verifyNotEmpty(id);
        end

        function idStaysTheSameWhenStateMachineRuns(testCase)
            testCase.stateMachine.run(Events.TURN_ON);
            id1 = testCase.stateMachine.getId();
            testCase.stateMachine.run(Events.TIME_TIC);
            id2 = testCase.stateMachine.getId();
            testCase.verifyEqual(id1, id2);
        end

        function eachObjectHasIndividualId(testCase)
            stateMachine2 = StateMachine(testCase.schedulerStub, ...
                testCase.guardConditionsStub, testCase.driverAbstractionLayerStub, ...
                testCase.timeKeepingStub, testCase.stateActionsStub);
            stateMachine3 = StateMachine(testCase.schedulerStub, ...
                testCase.guardConditionsStub, testCase.driverAbstractionLayerStub, ...
                testCase.timeKeepingStub, testCase.stateActionsStub);
            
            testCase.stateMachine.run(Events.TURN_ON);
            stateMachine2.run(Events.TURN_ON);
            stateMachine3.run(Events.TURN_ON);

            id1 = testCase.stateMachine.getId();
            id2 = stateMachine2.getId();
            id3 = stateMachine3.getId();

            testCase.verifyNotEqual(id1, id2);
            testCase.verifyNotEqual(id2, id3);
            testCase.verifyNotEqual(id1, id3);
        end

        function firstIdIsOne(testCase)
            testCase.stateMachine.run(Events.TURN_ON);

            id = testCase.stateMachine.getId();
            testCase.verifyEqual(id, 1);
        end

        function stateIsListeningUnconnectedAfterTurnOn(testCase)
            testCase.stateMachine.run(Events.TURN_ON);

            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.LISTENING_UNCONNECTED);
        end

        function noStateChangeOnTurnOnWhenListeningUnconnected(testCase)
            testCase.stateMachine.run(Events.TURN_ON);
            testCase.stateMachine.run(Events.TURN_ON);

            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.LISTENING_UNCONNECTED);
        end

        function changeToListeningConnectedOnIncomingMsgInListeningUnconnected(testCase)
            testCase.stateMachine.run(Events.TURN_ON);
            testCase.stateMachine.run(Events.INCOMING_MSG, []);

            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.LISTENING_CONNECTED);
        end

        function changeToSendingUnconnectedPingScheduled(testCase)
            % on time tic: when listening unconnected and ping is scheduled 
            % and guard conditions are satisfied
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.pingScheduledToNow()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.listeningUncToSendingUncAllowed()), true);

            testCase.stateMachine.run(Events.TURN_ON);
            testCase.stateMachine.run(Events.TIME_TIC);

            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.SENDING_UNCONNECTED);
        end

        function dontChangeToSendingUnconnectedPingNotScheduled(testCase)
            % on time tic: when listening unconnected and ping is not 
            % scheduled and guard conditions are satisfied
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.pingScheduledToNow()), false);
            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.listeningUncToSendingUncAllowed()), true);

            testCase.stateMachine.run(Events.TURN_ON);
            testCase.stateMachine.run(Events.TIME_TIC);

            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.LISTENING_UNCONNECTED);
        end

        function dontChangeToSendingUnconnectedGuardsNotSatisfied(testCase)
            % on time tic: when listening unconnected, ping is scheduled
            % and guard conditions are not satisfied
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.pingScheduledToNow()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.listeningUncToSendingUncAllowed()), false);
            
            testCase.stateMachine.run(Events.TURN_ON);
            testCase.stateMachine.run(Events.TIME_TIC);

            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.LISTENING_UNCONNECTED);
        end

        function changeToListeningConnectedWhenSendingUnconnectedFinished(testCase)
            % on time tic: when sending unconnected is finished and guard 
            % conditions are satisfied
            initializeToSendingUnconnected(testCase);

            % then finish sending
            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.sendingUncToListeningConAllowed()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.driverAbstractionLayerBehaviour.sendingFinished()), true);

            testCase.stateMachine.run(Events.TIME_TIC);

            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.LISTENING_CONNECTED);
        end

        function noStateChangeSendingUnconnectedWhenSendingNotFinished(testCase)
            initializeToSendingUnconnected(testCase);

            % then finish sending
            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.sendingUncToListeningConAllowed()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.driverAbstractionLayerBehaviour.sendingFinished()), false);

            testCase.stateMachine.run(Events.TIME_TIC);

            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.SENDING_UNCONNECTED);
        end

        function noStateChangeOnTurnOnWhenSendingUnconnected(testCase)
            initializeToSendingUnconnected(testCase);

            testCase.stateMachine.run(Events.TURN_ON);
            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.SENDING_UNCONNECTED);
        end

        function noStateChangeOnIncomingMsgWhenSendingUnconnected(testCase)
            initializeToSendingUnconnected(testCase);

            testCase.stateMachine.run(Events.INCOMING_MSG);
            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.SENDING_UNCONNECTED);
        end

        function noStateChangeListeningConnectedWhenNotTimedOut(testCase)
            initializeToListeningConnected(testCase);
            
            testCase.assignOutputsWhen(withExactInputs(testCase.timeKeepingBehaviour.networkConnectionTimeout()), false);

            testCase.stateMachine.run(Events.TIME_TIC);

            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.LISTENING_CONNECTED);
        end

        function changeToListeningUnconnectedWhenGuardConditionSatisfied(testCase)
            initializeToListeningConnected(testCase);

            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.listeningConToSendingConAllowed()), false);
            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.listeningConToListeningUncAllowed()), true);

            testCase.stateMachine.run(Events.TIME_TIC);

            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.LISTENING_UNCONNECTED);
        end

        function noStateChangeListeningConnectedOnIncomingMsg(testCase)
            initializeToListeningConnected(testCase);
            testCase.assignOutputsWhen(withExactInputs(testCase.timeKeepingBehaviour.networkConnectionTimeout()), true);

            testCase.stateMachine.run(Events.INCOMING_MSG, []);

            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.LISTENING_CONNECTED);            
        end

        function changeToSendingConnectedPingScheduled(testCase)
            % on time tic: when listening connected and ping is scheduled 
            % and guard conditions are satisfied
            initializeToListeningConnected(testCase);
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.pingScheduledToNow()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.listeningConToSendingConAllowed()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.timeKeepingBehaviour.networkConnectionTimeout()), false);

            testCase.stateMachine.run(Events.TIME_TIC);

            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.SENDING_CONNECTED);
        end

        function noStateChangeListeningConnectedPingNotScheduled(testCase)
            % on time tic: when listening connected and ping is NOT 
            % scheduled and guard conditions are satisfied
            initializeToListeningConnected(testCase);
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.pingScheduledToNow()), false);
            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.listeningConToSendingConAllowed()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.timeKeepingBehaviour.networkConnectionTimeout()), false);

            testCase.stateMachine.run(Events.TIME_TIC);

            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.LISTENING_CONNECTED);
        end

        function noStateChangeListeningConnectedGuardsNotSatisfied(testCase)
            % on time tic: when listening connected and ping is 
            % scheduled and guard conditions are NOT satisfied
            initializeToListeningConnected(testCase);
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.pingScheduledToNow()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.listeningConToSendingConAllowed()), false);
            testCase.assignOutputsWhen(withExactInputs(testCase.timeKeepingBehaviour.networkConnectionTimeout()), false);

            testCase.stateMachine.run(Events.TIME_TIC);

            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.LISTENING_CONNECTED);
        end

        function changeToListeningConnectedWhenSendingConnectedFinished(testCase)
            initializeToListeningConnected(testCase);
            % first go to sending connected
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.pingScheduledToNow()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.listeningConToSendingConAllowed()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.timeKeepingBehaviour.networkConnectionTimeout()), false);

            testCase.stateMachine.run(Events.TIME_TIC);

            testCase.assignOutputsWhen(withExactInputs(testCase.driverAbstractionLayerBehaviour.sendingFinished()), true);

            testCase.stateMachine.run(Events.TIME_TIC);
            
            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.LISTENING_CONNECTED);
        end

        function noStateChangeSendingConnectedWhenSendingNotFinished(testCase)
            initializeToSendingConnected(testCase);
            testCase.assignOutputsWhen(withExactInputs(testCase.driverAbstractionLayerBehaviour.sendingFinished()), false);

            testCase.stateMachine.run(Events.TIME_TIC);
            
            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.SENDING_CONNECTED);
        end

        function noStateChangeSendingConnectedOnIncomingMsg(testCase)
            initializeToSendingConnected(testCase);
            testCase.assignOutputsWhen(withExactInputs(testCase.driverAbstractionLayerBehaviour.sendingFinished()), true);

            testCase.stateMachine.run(Events.INCOMING_MSG);
            
            currentState = testCase.stateMachine.getState();
            testCase.verifyEqual(currentState, States.SENDING_CONNECTED);
        end

        function callListeningUnconnectedActionOnTurnOn(testCase)
            initializeToListeningUnconnected(testCase);

            testCase.verifyCalled(withAnyInputs(testCase.stateActionsBehaviour.listeningUnconnectedTimeTicAction()));
        end

        function dontCallOtherActionsOnTurnOnListeningUnconnected(testCase)
            initializeToListeningUnconnected(testCase);

            testCase.verifyNotCalled(withAnyInputs(testCase.stateActionsBehaviour.listeningConnectedTimeTicAction()));
            testCase.verifyNotCalled(withAnyInputs(testCase.stateActionsBehaviour.sendingUnconnectedTimeTicAction()));
            testCase.verifyNotCalled(withAnyInputs(testCase.stateActionsBehaviour.sendingConnectedTimeTicAction()));
        end

        function callListeningUnconnectedActionOnTimeTic(testCase)
            import matlab.mock.constraints.WasCalled;

            initializeToListeningUnconnected(testCase);
            testCase.stateMachine.run(Events.TIME_TIC);

            testCase.verifyThat(withAnyInputs(testCase.stateActionsBehaviour.listeningUnconnectedTimeTicAction()), WasCalled('WithCount', 2));
            testCase.verifyNotCalled(withAnyInputs(testCase.stateActionsBehaviour.listeningConnectedTimeTicAction()));
            testCase.verifyNotCalled(withAnyInputs(testCase.stateActionsBehaviour.sendingUnconnectedTimeTicAction()));
            testCase.verifyNotCalled(withAnyInputs(testCase.stateActionsBehaviour.sendingConnectedTimeTicAction()));
        end

        function dontCallOtherActionsOnTimeTicListeningUnconnected(testCase)
            initializeToListeningUnconnected(testCase);
            testCase.stateMachine.run(Events.TIME_TIC);

            testCase.verifyNotCalled(withAnyInputs(testCase.stateActionsBehaviour.listeningConnectedTimeTicAction()));
            testCase.verifyNotCalled(withAnyInputs(testCase.stateActionsBehaviour.sendingUnconnectedTimeTicAction()));
            testCase.verifyNotCalled(withAnyInputs(testCase.stateActionsBehaviour.sendingConnectedTimeTicAction()));
        end

        function callSendingUnconnectedActionOnStateChange(testCase)
            initializeToSendingUnconnected(testCase);

            testCase.verifyCalled(withAnyInputs(testCase.stateActionsBehaviour.sendingUnconnectedTimeTicAction()));
        end

        function callSendingUnconnectedActionOnTimeTic(testCase)
            import matlab.mock.constraints.WasCalled;

            initializeToSendingUnconnected(testCase);
            testCase.stateMachine.run(Events.TIME_TIC);

            testCase.verifyThat(withAnyInputs(testCase.stateActionsBehaviour.sendingUnconnectedTimeTicAction()), WasCalled('WithCount', 2));
        end

        function dontCallOtherActionsOnTimeTicSendingUnconnected(testCase)
            import matlab.mock.constraints.WasCalled;

            initializeToSendingUnconnected(testCase);
            testCase.stateMachine.run(Events.TIME_TIC);

            testCase.verifyThat(withAnyInputs(testCase.stateActionsBehaviour.listeningUnconnectedTimeTicAction()), WasCalled('WithCount', 1));
            testCase.verifyNotCalled(withAnyInputs(testCase.stateActionsBehaviour.listeningConnectedTimeTicAction()));
            testCase.verifyNotCalled(withAnyInputs(testCase.stateActionsBehaviour.sendingConnectedTimeTicAction()));
        end

        function callListeningConnectedActionOnStateChangeListeningUnconnected(testCase)
            initializeToListeningConnected(testCase);

            testCase.verifyCalled(withAnyInputs(testCase.stateActionsBehaviour.listeningUnconnectedIncomingMsgAction()));
        end
        
        function dontCallOtherActionsOnStateChangeFromListeningUnconnected(testCase)
            % only call listening connected and the functions needed for
            % initialization (not more than specified count)
            import matlab.mock.constraints.WasCalled;

            initializeToListeningConnected(testCase);

            testCase.verifyThat(withAnyInputs(testCase.stateActionsBehaviour.listeningUnconnectedTimeTicAction()), WasCalled('WithCount', 1));
            testCase.verifyNotCalled(withAnyInputs(testCase.stateActionsBehaviour.sendingConnectedTimeTicAction()));
            testCase.verifyNotCalled(withAnyInputs(testCase.stateActionsBehaviour.sendingUnconnectedTimeTicAction()));
        end

        function callListeningConnectedActionOnStateChangeFromSendingUnconnected(testCase)
            initializeToSendingUnconnected(testCase);
            
            % finish sending
            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.sendingUncToListeningConAllowed()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.driverAbstractionLayerBehaviour.sendingFinished()), true);
            testCase.stateMachine.run(Events.TIME_TIC);

            testCase.verifyCalled(withAnyInputs(testCase.stateActionsBehaviour.listeningConnectedTimeTicAction()));
        end

        function dontCallOtherActionsOnStateChangeFromSendingUnconnected(testCase)
            % only call listening connected action and the functions needed
            % for initialization (not more than the specified count)
            import matlab.mock.constraints.WasCalled;

            initializeToSendingUnconnected(testCase);

            % finish sending
            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.sendingUncToListeningConAllowed()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.driverAbstractionLayerBehaviour.sendingFinished()), true);
            testCase.stateMachine.run(Events.TIME_TIC);

            testCase.verifyThat(withAnyInputs(testCase.stateActionsBehaviour.listeningUnconnectedTimeTicAction()), WasCalled('WithCount', 1));
            testCase.verifyThat(withAnyInputs(testCase.stateActionsBehaviour.sendingUnconnectedTimeTicAction()), WasCalled('WithCount', 1));
            testCase.verifyNotCalled(withAnyInputs(testCase.stateActionsBehaviour.sendingConnectedTimeTicAction()));
        end

        function callListeningConnectedActionOnStateChangeFromSendingConnected(testCase)
            import matlab.mock.constraints.WasCalled;

            initializeToSendingConnected(testCase);
            
            % finish sending
            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.sendingConToListeningConAllowed()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.driverAbstractionLayerBehaviour.sendingFinished()), true);
            testCase.stateMachine.run(Events.TIME_TIC);

            testCase.verifyThat(withAnyInputs(testCase.stateActionsBehaviour.listeningUnconnectedIncomingMsgAction()), WasCalled('WithCount', 1));
            testCase.verifyThat(withAnyInputs(testCase.stateActionsBehaviour.listeningConnectedTimeTicAction()), WasCalled('WithCount', 1));
        end

        function dontCallOtherActionsOnStateChangeFromSendingConnected(testCase)
            % only call listening connected action and the functions needed
            % for initialization (not more than the specified count)
            import matlab.mock.constraints.WasCalled;

            initializeToSendingConnected(testCase);

            % finish sending
            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.sendingConToListeningConAllowed()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.driverAbstractionLayerBehaviour.sendingFinished()), true);
            testCase.stateMachine.run(Events.TIME_TIC);

            testCase.verifyThat(withAnyInputs(testCase.stateActionsBehaviour.listeningUnconnectedTimeTicAction()), WasCalled('WithCount', 1));
            testCase.verifyNotCalled(withAnyInputs(testCase.stateActionsBehaviour.sendingUnconnectedTimeTicAction()));
            testCase.verifyThat(withAnyInputs(testCase.stateActionsBehaviour.sendingConnectedTimeTicAction()), WasCalled('WithCount', 1));
        end

        function callSendingConnectedActionOnStateChangeFromListeningConnected(testCase)
            initializeToSendingConnected(testCase);

            testCase.verifyCalled(withAnyInputs(testCase.stateActionsBehaviour.sendingConnectedTimeTicAction()));
        end

        function dontCallOtherActionsOnStateChangeFromSendingListeningConnected(testCase)
            % only call sending connected action and the functions needed
            % for initialization (not more than the specified count)
            import matlab.mock.constraints.WasCalled;

            initializeToSendingConnected(testCase);

            testCase.verifyThat(withAnyInputs(testCase.stateActionsBehaviour.listeningUnconnectedTimeTicAction()), WasCalled('WithCount', 1));
            testCase.verifyThat(withAnyInputs(testCase.stateActionsBehaviour.listeningUnconnectedIncomingMsgAction()), WasCalled('WithCount', 1));
            testCase.verifyNotCalled(withAnyInputs(testCase.stateActionsBehaviour.sendingUnconnectedTimeTicAction()));
        end

        function callListeningUnconnectedActionOnStateChangeFromListeningConn(testCase)
            import matlab.mock.constraints.WasCalled;

            initializeToListeningConnected(testCase);

            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.listeningConToListeningUncAllowed()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.timeKeepingBehaviour.networkConnectionTimeout()), true);
            
            testCase.stateMachine.run(Events.TIME_TIC);

            testCase.verifyThat(withAnyInputs(testCase.stateActionsBehaviour.listeningUnconnectedTimeTicAction()), WasCalled('WithCount', 2));
        end

        function dontCallOtherActionsOnStateChangeFromListeningConn(testCase)
            % only call listening unconnected action and the functions needed
            % for initialization (not more than the specified count)
            import matlab.mock.constraints.WasCalled;

            initializeToListeningConnected(testCase);

            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.listeningConToListeningUncAllowed()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.timeKeepingBehaviour.networkConnectionTimeout()), true);
            
            testCase.stateMachine.run(Events.TIME_TIC);

            testCase.verifyThat(withAnyInputs(testCase.stateActionsBehaviour.listeningUnconnectedIncomingMsgAction()), WasCalled('WithCount', 1));
            testCase.verifyNotCalled(withAnyInputs(testCase.stateActionsBehaviour.sendingUnconnectedTimeTicAction()));
            testCase.verifyNotCalled(withAnyInputs(testCase.stateActionsBehaviour.sendingConnectedTimeTicAction()));
        end


        function stateMachineAcceptsMessageInput(testCase)
            
            msg.type = MessageTypes.PING;
            testCase.stateMachine.run(Events.INCOMING_MSG, msg);

        end

        function incomingMessageIsPassedToStateActionUnconnected(testCase)
            import matlab.mock.constraints.WasCalled;
            initializeToListeningUnconnected(testCase);
            msg.type = MessageTypes.PING;
            msg.senderId = 4;

            testCase.stateMachine.run(Events.INCOMING_MSG, msg);

            testCase.verifyThat(testCase.stateActionsBehaviour.listeningUnconnectedIncomingMsgAction(msg), WasCalled('WithCount', 1));
        end

        function incomingMessageIsPassedToStateActionConnected(testCase)
            import matlab.mock.constraints.WasCalled;
            initializeToListeningConnected(testCase);
            msg.type = MessageTypes.PING;
            msg.senderId = 4;

            testCase.stateMachine.run(Events.INCOMING_MSG, msg);

            testCase.verifyThat(testCase.stateActionsBehaviour.listeningConnectedIncomingMsgAction(msg), WasCalled('WithCount', 1));
        end

        %% ranging poll

        %% 
        
        %% helper functions

        function initializeToListeningUnconnected(testCase)
            testCase.stateMachine.run(Events.TURN_ON);
        end
          
        function initializeToListeningConnected(testCase)
            testCase.stateMachine.run(Events.TURN_ON);
            testCase.stateMachine.run(Events.INCOMING_MSG, []);
        end

        function initializeToSendingUnconnected(testCase)
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.pingScheduledToNow()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.listeningUncToSendingUncAllowed()), true);

            testCase.stateMachine.run(Events.TURN_ON);
            testCase.stateMachine.run(Events.TIME_TIC);
        end

        function initializeToSendingConnected(testCase)
            initializeToListeningConnected(testCase);
            testCase.assignOutputsWhen(withExactInputs(testCase.schedulerBehaviour.pingScheduledToNow()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.guardConditionsBehaviour.listeningConToSendingConAllowed()), true);
            testCase.assignOutputsWhen(withExactInputs(testCase.timeKeepingBehaviour.networkConnectionTimeout()), false);

            testCase.stateMachine.run(Events.TIME_TIC);
        end
    end
end












