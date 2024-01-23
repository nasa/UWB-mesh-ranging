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

classdef Node < handle
    % Node object is used to address the different nodes (get and change
    % their positions, send messages to them etc.); not part of the
    % protocol, but needed for the simulation

    properties %(Access = private)
        slotMap;
        networkManager;
        channel;
        clock;
        messageHandler;
        timeKeeping;
        driverAbstraction;

        config;
        nodeConfig;
        position;
        id;
    end

    properties
        stateMachine;
    end

    methods
        function this = Node(config, nodeConfig, stateMachine, slotMap, networkManager, channel, clock, messageHandler, timeKeeping, driverAbstraction)
            this.config = config;
            this.nodeConfig = nodeConfig;
            position.x = nodeConfig.x;
            position.y = nodeConfig.y;

            this.position = position;
            this.stateMachine = stateMachine;
            this.slotMap = slotMap;
            this.networkManager = networkManager;
            this.channel = channel;
            this.clock = clock;
            this.messageHandler = messageHandler;
            this.timeKeeping = timeKeeping;
            this.driverAbstraction = driverAbstraction;

            this.id = stateMachine.getId;
            
            % set IDs in other objects
            this.slotMap.setId(this.id);
            this.networkManager.setNodeId(this.id);
            this.messageHandler.setId(this.id);
            this.driverAbstraction.setId(this.id);

            % set stateMachine for driver
            this.driverAbstraction.setStateMachine(this.stateMachine);
        end

        function initialize(this)
            % subscribe to the channel
            this.channel.subscribe(this);
        end

        function move(this, globalTime)
            % move node if configured
            mvmtIdx = find(globalTime == this.nodeConfig.movementTimes, 1);
            if ~isempty(mvmtIdx)
                this.position.x = this.position.x + this.nodeConfig.movementsX(1, mvmtIdx);
                this.position.y = this.position.y + this.nodeConfig.movementsY(1, mvmtIdx);
            end
        end

        function position = getPosition(this)
            position = this.position;
        end

        function runStateMachine(this, event)
            this.stateMachine.run(event);
        end

        function notify(this, msg)
            % callback function for communication channel; in real
            % implementation, this will probably be implemented in an
            % additional module and could create msg-structures from the
            % incoming data that the communication protocol understands
            
            this.driverAbstraction.notify(msg);
%             global debugGlobalTime;
% 
%             if SimConfigs.VERBOSE
%                 switch msg.type
%                     case MessageTypes.PING
%                         disp(strcat(num2str(debugGlobalTime), ": Node ", num2str(this.id), " received ping from Node ", num2str(msg.senderId)));
%                     case MessageTypes.COLLISION
%                         disp(strcat(num2str(debugGlobalTime), ": Node ", num2str(this.id), " received collision"));
%                     case MessageTypes.RANGING_POLL
%                         disp(strcat(num2str(debugGlobalTime), ": Node ", num2str(this.id), " received poll from Node ", num2str(msg.senderId)));    
%                     case MessageTypes.RANGING_RESP
%                         disp(strcat(num2str(debugGlobalTime), ": Node ", num2str(this.id), " received response from Node ", num2str(msg.senderId)));
%                     case MessageTypes.RANGING_FINAL
%                         disp(strcat(num2str(debugGlobalTime), ": Node ", num2str(this.id), " received final from Node ", num2str(msg.senderId)));
%                     case MessageTypes.RANGING_RESULT
%                         disp(strcat(num2str(debugGlobalTime), ": Node ", num2str(this.id), " received result from Node ", num2str(msg.senderId)));
%                 end
%             end
% 
%             this.stateMachine.run(Events.INCOMING_MSG, msg);
        end

        % functions used by simulation components (Wrapper, Animation, Diagram, ...)
        function id = getId(this)
            id = this.id;
        end

        function state = getState(this)
            state = this.stateMachine.getState();
        end

        function enterTime = getEnterTime(this)
            enterTime = this.nodeConfig.enterTime;
        end

        function range = getSignalRange(this)
            range = this.config.signalRange;
        end

        function ownSlots = getOwnSlots(this)
            ownSlots = this.slotMap.getOwnSlots();
        end

        function netId = getNetworkId(this)
            netId = this.networkManager.getNetworkId();
        end

        function netAge = calculateNetworkAge(time)
            netAge = this.networkManager.calculateNetworkAge(time);
        end

        function inRange = isInRange(this, sender, receiver)
            inRange = this.channel.isInRange(sender, receiver);
        end

        function frameStartTime = getFrameStartTime(this)
            frameStartTime = this.timeKeeping.getFrameStartTime();
        end

        function time = getLocalTime(this)
            time = this.clock.getLocalTime();
        end

        function times = getMovementTimes(this)
            times = this.nodeConfig.movementTimes;
        end

        function tic(this)
            this.clock.increment();
        end
    end

end