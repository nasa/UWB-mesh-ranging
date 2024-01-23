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

classdef CommunicationChannelTest < matlab.mock.TestCase

    properties
        channel;

        stateMachineStub;
        stateMachineStub2;
        stateMachineStub3;
        stateMachineBehaviour;
        stateMachineBehaviour2;
        stateMachineBehaviour3;

        slotMapStub;
        slotMapBehaviour;
        networkManagerStub;
        networkManagerBehaviour;
        clockStub;
        clockBehaviour;
        messageHandlerStub;
        messageHandlerBehaviour;
    end

    methods(TestMethodSetup)
        function addSrcPath(testCase)
            addpath('../src');
        end

        function setUpTest(testCase)
            testCase.channel = CommunicationChannel();

            [testCase.stateMachineStub, testCase.stateMachineBehaviour] = StubFactory.makeStateMachineStub(testCase);
            [testCase.stateMachineStub2, testCase.stateMachineBehaviour2] = StubFactory.makeStateMachineStub(testCase);
            [testCase.stateMachineStub3, testCase.stateMachineBehaviour3] = StubFactory.makeStateMachineStub(testCase);

            [testCase.slotMapStub, testCase.slotMapBehaviour] = StubFactory.makeSlotMapStub(testCase);
            [testCase.networkManagerStub, testCase.networkManagerBehaviour] = StubFactory.makeNetworkManagerStub(testCase);
            [testCase.clockStub, testCase.clockBehaviour] = StubFactory.makeClockStub(testCase);
            [testCase.messageHandlerStub, testCase.messageHandlerBehaviour] = StubFactory.makeMessageHandlerStub(testCase);

        end

    end

    methods(Test)

        function transmitToAllSubscribersButSender(testCase)
            import matlab.mock.constraints.WasCalled;
            globalTime = 0;

            position.x = 1;
            position.y = 1;
            config.signalRange = 10;

            testCase.assignOutputsWhen(withExactInputs(testCase.stateMachineBehaviour.getId()), 1);
            testCase.assignOutputsWhen(withExactInputs(testCase.stateMachineBehaviour2.getId()), 2);

            node1 = Node(config, position, testCase.stateMachineStub, testCase.slotMapStub, testCase.networkManagerStub, testCase.channel, testCase.clockStub, testCase.messageHandlerStub);
            node2 = Node(config, position, testCase.stateMachineStub2, testCase.slotMapStub, testCase.networkManagerStub, testCase.channel, testCase.clockStub, testCase.messageHandlerStub);

            testCase.channel.subscribe(node1);
            testCase.channel.subscribe(node2);

            msg.type = MessageTypes.PING;
            msg.senderId = 1;

            testCase.channel.transmit(msg, globalTime);
            testCase.channel.execute(globalTime + MessageSizes.PING_SIZE);

            testCase.verifyNotCalled(testCase.stateMachineBehaviour.run(Events.INCOMING_MSG, msg));
            testCase.verifyThat(testCase.stateMachineBehaviour2.run(Events.INCOMING_MSG, msg), WasCalled('WithCount', 1));
        end

        function transmitOnExecute(testCase)
            % message should not be transmitted if execute() is not called
            import matlab.mock.constraints.WasCalled;
            globalTime = 0;

            position.x = 1;
            position.y = 1;
            config.signalRange = 10;

            testCase.assignOutputsWhen(withExactInputs(testCase.stateMachineBehaviour.getId()), 1);
            testCase.assignOutputsWhen(withExactInputs(testCase.stateMachineBehaviour2.getId()), 2);

            node1 = Node(config, position, testCase.stateMachineStub, testCase.slotMapStub, testCase.networkManagerStub, testCase.channel, testCase.clockStub, testCase.messageHandlerStub);
            node2 = Node(config, position, testCase.stateMachineStub2, testCase.slotMapStub, testCase.networkManagerStub, testCase.channel, testCase.clockStub, testCase.messageHandlerStub);

            testCase.channel.subscribe(node1);
            testCase.channel.subscribe(node2);

            msg.type = MessageTypes.PING;
            msg.senderId = 1;
            testCase.channel.transmit(msg, globalTime);

            testCase.verifyNotCalled(testCase.stateMachineBehaviour.run(Events.INCOMING_MSG, msg));
            testCase.verifyNotCalled(testCase.stateMachineBehaviour2.run(Events.INCOMING_MSG, msg));
        end

        function dontTransmitWhenMessageNotFinished(testCase)
            import matlab.mock.constraints.WasCalled;
            globalTime = 0;

            position.x = 1;
            position.y = 1;
            config.signalRange = 10;

            testCase.assignOutputsWhen(withExactInputs(testCase.stateMachineBehaviour.getId()), 1);
            testCase.assignOutputsWhen(withExactInputs(testCase.stateMachineBehaviour2.getId()), 2);

            node1 = Node(config, position, testCase.stateMachineStub, testCase.slotMapStub, testCase.networkManagerStub, testCase.channel, testCase.clockStub, testCase.messageHandlerStub);
            node2 = Node(config, position, testCase.stateMachineStub2, testCase.slotMapStub, testCase.networkManagerStub, testCase.channel, testCase.clockStub, testCase.messageHandlerStub);


            testCase.channel.subscribe(node1);
            testCase.channel.subscribe(node2);

            msg.type = MessageTypes.PING;
            msg.senderId = 1;

            testCase.channel.transmit(msg, globalTime);
            testCase.channel.execute(globalTime + MessageSizes.PING_SIZE - 1);

            testCase.verifyNotCalled(testCase.stateMachineBehaviour.run(Events.INCOMING_MSG, msg));
            testCase.verifyNotCalled(testCase.stateMachineBehaviour2.run(Events.INCOMING_MSG, msg));
        end

        function dontTransmitToNodesNotInRange(testCase)
            import matlab.mock.constraints.WasCalled;
            globalTime = 0;

            position1.x = 1;
            position1.y = 1;
            position2.x = 20;
            position2.y = 1;
            position3.x = 5;
            position3.y = 1;
            config.signalRange = 10;

            testCase.assignOutputsWhen(withExactInputs(testCase.stateMachineBehaviour.getId()), 1);
            testCase.assignOutputsWhen(withExactInputs(testCase.stateMachineBehaviour2.getId()), 2);
            testCase.assignOutputsWhen(withExactInputs(testCase.stateMachineBehaviour3.getId()), 3);

            node1 = Node(config, position1, testCase.stateMachineStub, testCase.slotMapStub, testCase.networkManagerStub, testCase.channel, testCase.clockStub, testCase.messageHandlerStub);
            node2 = Node(config, position2, testCase.stateMachineStub2, testCase.slotMapStub, testCase.networkManagerStub, testCase.channel, testCase.clockStub, testCase.messageHandlerStub);
            node3 = Node(config, position3, testCase.stateMachineStub3, testCase.slotMapStub, testCase.networkManagerStub, testCase.channel, testCase.clockStub, testCase.messageHandlerStub);


            testCase.channel.subscribe(node1);
            testCase.channel.subscribe(node2);
            testCase.channel.subscribe(node3);

            msg.type = MessageTypes.PING;
            msg.senderId = 1;

            testCase.channel.transmit(msg, globalTime);
            testCase.channel.execute(globalTime + MessageSizes.PING_SIZE);

            testCase.verifyNotCalled(testCase.stateMachineBehaviour.run(Events.INCOMING_MSG, msg));
            testCase.verifyNotCalled(testCase.stateMachineBehaviour2.run(Events.INCOMING_MSG, msg));
            testCase.verifyThat(testCase.stateMachineBehaviour3.run(Events.INCOMING_MSG, msg), WasCalled('WithCount', 1));
        end

        function dontTransmitToNodesNotListening(testCase)
            import matlab.mock.constraints.WasCalled;
            globalTime = 0;

            position.x = 1;
            position.y = 1;
            config.signalRange = 10;

            testCase.assignOutputsWhen(withExactInputs(testCase.stateMachineBehaviour.getId()), 1);
            testCase.assignOutputsWhen(withExactInputs(testCase.stateMachineBehaviour2.getId()), 2);

            node1 = Node(config, position, testCase.stateMachineStub, testCase.slotMapStub, testCase.networkManagerStub, testCase.channel, testCase.clockStub, testCase.messageHandlerStub);
            node2 = Node(config, position, testCase.stateMachineStub2, testCase.slotMapStub, testCase.networkManagerStub, testCase.channel, testCase.clockStub, testCase.messageHandlerStub);


            testCase.channel.subscribe(node1);
            testCase.channel.subscribe(node2);

            msg.type = MessageTypes.PING;
            msg.senderId = 1;

            testCase.channel.transmit(msg, globalTime);
            testCase.assignOutputsWhen(withExactInputs(testCase.stateMachineBehaviour2.getState()), States.SENDING_CONNECTED);

            testCase.channel.execute(globalTime + MessageSizes.PING_SIZE - 5);

            testCase.assignOutputsWhen(withExactInputs(testCase.stateMachineBehaviour2.getState()), States.LISTENING_CONNECTED);
            testCase.channel.execute(globalTime + MessageSizes.PING_SIZE);

            testCase.verifyNotCalled(testCase.stateMachineBehaviour.run(Events.INCOMING_MSG, msg));
            testCase.verifyNotCalled(testCase.stateMachineBehaviour2.run(Events.INCOMING_MSG, msg));
        end
        
        function sendCollisionIfTwoMessagesInboundSimultaneously(testCase)
            assumeFail(testCase);
        end
        
    end

end