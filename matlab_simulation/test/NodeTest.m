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

classdef NodeTest < matlab.mock.TestCase

    properties
        stateMachineStub;
        stateMachineBehaviour;
        slotMapStub;
        slotMapBehaviour;
        networkManagerStub;
        networkManagerBehaviour;
        clockStub;
        clockBehaviour;
        messageHandlerStub;
        messageHandlerBehaviour;
        channelStub;
        channelBehaviour;
    end

    methods(TestMethodSetup)
        function addSrcPath(testCase)
            addpath('../src');
        end

        function setUpTest(testCase)
            [testCase.stateMachineStub, testCase.stateMachineBehaviour] = StubFactory.makeStateMachineStub(testCase);
            [testCase.slotMapStub, testCase.slotMapBehaviour] = StubFactory.makeSlotMapStub(testCase);
            [testCase.networkManagerStub, testCase.networkManagerBehaviour] = StubFactory.makeNetworkManagerStub(testCase);
            [testCase.channelStub, testCase.channelBehaviour] = StubFactory.makeCommunicationChannelStub(testCase);
            [testCase.clockStub, testCase.clockBehaviour] = StubFactory.makeClockStub(testCase);
            [testCase.messageHandlerStub, testCase.messageHandlerBehaviour] = StubFactory.makeMessageHandlerStub(testCase);
        end

    end

    methods(Test)

        function createNode(testCase)
            % with position
            nodeConfig.x = 3;
            nodeConfig.y = 2;
            config = [];

            node = Node(config, nodeConfig, testCase.stateMachineStub, testCase.slotMapStub, testCase.networkManagerStub, testCase.channelStub, testCase.clockStub, testCase.messageHandlerStub);
            
            actualPosition = node.getPosition();

            testCase.verifyEqual(actualPosition, nodeConfig);
        end

        function hasIdAfterCreation(testCase)
            % with position
            nodeConfig.x = 3;
            nodeConfig.y = 2;
            testId = 42;
            config = [];

            testCase.assignOutputsWhen(withExactInputs(testCase.stateMachineBehaviour.getId()), testId);

            node = Node(config, nodeConfig, testCase.stateMachineStub, testCase.slotMapStub, testCase.networkManagerStub, testCase.channelStub, testCase.clockStub, testCase.messageHandlerStub);
            id = node.getId();

            testCase.verifyEqual(id, testId);
        end

        function canCallStateMachineOnIncomingMsg(testCase)
            import matlab.mock.constraints.WasCalled;
            % with position and callbacks
            nodeConfig.x = 3;
            nodeConfig.y = 2;
            config = [];

            node = Node(config, nodeConfig, testCase.stateMachineStub, testCase.slotMapStub, testCase.networkManagerStub, testCase.channelStub, testCase.clockStub, testCase.messageHandlerStub);
            msg.type = MessageTypes.PING;
            msg.senderId = 3;
            node.notify(msg);

            testCase.verifyThat(testCase.stateMachineBehaviour.run(Events.INCOMING_MSG, msg), WasCalled('WithCount', 1));
        end

        function canCallStateMachineRegularly(testCase)
            import matlab.mock.constraints.WasCalled;
            % with position and callbacks
            nodeConfig.x = 3;
            nodeConfig.y = 2;
            config = [];
            event = Events.TIME_TIC;

            node = Node(config, nodeConfig, testCase.stateMachineStub, testCase.slotMapStub, testCase.networkManagerStub, testCase.channelStub, testCase.clockStub, testCase.messageHandlerStub);
            node.runStateMachine(event);

            testCase.verifyThat(withAnyInputs(testCase.stateMachineBehaviour.run()), WasCalled('WithCount', 1));
        end
            
    end

end