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

classdef CommunicationChannel_mex < handle

    properties %(Access = private)
        subscribers;
        transmittedMessages;
        ids;
        mlWrapperPointer;
        signalRange = 100;
    end

    methods
        function this = CommunicationChannel_mex(mlWrapperPointer)
            this.subscribers = [];
            this.transmittedMessages = {};
            this.ids = [];
            this.mlWrapperPointer = mlWrapperPointer;
        end

        function subscribe(this, nodeId)
            this.subscribers(end + 1, 1) = nodeId;
            this.transmittedMessages{end + 1, 1} = nodeId;
            this.transmittedMessages{end, 2} = {};
        end

        function transmit(this, msg, globalTime)
            for subIdx = 1:size(this.subscribers, 1)
                if (this.subscribers(subIdx, 1) == msg.senderId)
                    % don't transmit the message to the sender
                    continue;
                end

                % add timestamp of arrival to the message (assuming time of flight is zero, which is true for the time-resolution of this simulation)
                localTimestampOfArrival = MatlabWrapper(12, this.mlWrapperPointer, this.subscribers(subIdx, 1));
                msg.timestamp = localTimestampOfArrival;
                                
                this.transmittedMessages{subIdx, 2}{1, end + 1} = msg;
                this.transmittedMessages{subIdx, 2}{2, end} = globalTime;
                this.transmittedMessages{subIdx, 2}{3, end} = "OKAY";
            end
        end

        function execute(this, globalTime, nodes)
            global collisionsDetectable;
            
            for subIdx = 1:size(this.subscribers, 1)
                for msgIdx = 1:size(this.transmittedMessages{subIdx, 2}, 2)
                    senderIdx = find(this.subscribers == this.transmittedMessages{subIdx, 2}{1, msgIdx}.senderId);

                    % calculate when message arrives (including delay) -
                    % when the message first comes in, not when it is
                    % complete!
                    arrivalTimeThisMessageGlobalTimeframe = this.transmittedMessages{subIdx, 2}{2, msgIdx};

                    if globalTime >= arrivalTimeThisMessageGlobalTimeframe
                                                
                        % if nodes are not in range at anytime while the 
                        % message is transmitted, flag it as out of range
                        if ~this.isInRange(nodes{senderIdx, 2}, nodes{subIdx, 2})
                            this.flagMessageAsOutOfRange(subIdx, msgIdx);
                            % set to "not receiving" again
                            MatlabWrapper(8, this.mlWrapperPointer, this.subscribers(subIdx, 1));
                        end

                        % if receiver is not listening, flag it as
                        % incomplete
                        if ~this.subscriberIsListening(subIdx)
                            this.flagMessageAsIncomplete(subIdx, msgIdx);
                            % set to "not receiving" again
                            MatlabWrapper(8, this.mlWrapperPointer, this.subscribers(subIdx, 1));
                        end
                        
                        if strcmp(this.transmittedMessages{subIdx, 2}{3, msgIdx}, "OKAY")
                            % set receiver to incoming (the receiving node
                            % starts to receive a message, but it is not
                            % complete yet)
                            MatlabWrapper(7, this.mlWrapperPointer, this.subscribers(subIdx, 1));
                        end

                        % if any other message arrives while this message
                        % is incoming, flag it as colliding
                        for otherMsgIdx = 1:size(this.transmittedMessages{subIdx, 2}, 2)
                            otherSenderIdx = find(this.subscribers == this.transmittedMessages{subIdx, 2}{1, otherMsgIdx}.senderId);

%                             otherDist = this.getDistanceBetween(this.subscribers{subIdx, 1}, this.subscribers{otherSenderIdx, 1});
%                             otherTransmissionDelay = this.calculateTransmissionDelay(otherDist);
                            otherMessageArrivalTime = this.transmittedMessages{subIdx, 2}{2, otherMsgIdx};% + otherTransmissionDelay;
                            if (globalTime >= otherMessageArrivalTime) & this.isInRange(nodes{otherSenderIdx, 2}, nodes{subIdx, 2}) & this.isInRange(nodes{senderIdx, 2}, nodes{subIdx, 2})
                                if ~(otherMsgIdx == msgIdx)
                                    this.flagMessageAsColliding(subIdx, msgIdx);
                                end
                            end
                        end
                    end
                end

                % for every message:
                % - if message complete: notify and delete
                msgsToRemove = [];
                for msgIdx = 1:size(this.transmittedMessages{subIdx, 2}, 2)
                    senderIdx = find(this.subscribers == this.transmittedMessages{subIdx, 2}{1, msgIdx}.senderId);
%                     dist = this.getDistanceBetween(this.subscribers{subIdx, 1}, this.subscribers{senderIdx, 1});
%                     transmissionDelay = this.calculateTransmissionDelay(dist);

                    % proper comparisons with enums take extremely long in
                    % MATLAB, so we have to use magic numbers...
                    
                    % 1 = LISTENING_UNCONNECTED
                    % 2 = LISTENING_CONNECTED
                    % 6 = RANGING_LISTENING
                    
                    switch this.transmittedMessages{subIdx, 2}{1, msgIdx}.type
                        case 0 % 0 = PING
                            msgSize = 10; % 10 = PING_SIZE
                        case 2 % 2 = RANGING_POLL
                            msgSize = 9; % 9 = RANGING_POLL_SIZE;
                        case 3 % 3 = RANGING_RESP
                            msgSize = 12; % 12 = RANGING_RESP_SIZE;
                        case 4 % 4 = RANGING_FINAL
                            msgSize = 15; % 15 = RANGING_FINAL_SIZE;
                        case 5 % 5 = RANGING_RESULT
                            msgSize = 2; % 2 = RANGING_RESULT_SIZE;    
                            
%                         case MessageTypes_mex.PING
%                             msgSize = MessageSizes.PING_SIZE;
%                         case MessageTypes_mex.RANGING_POLL
%                             msgSize = MessageSizes.RANGING_POLL_SIZE;
%                         case MessageTypes_mex.RANGING_RESP
%                             msgSize = MessageSizes.RANGING_RESP_SIZE;
%                         case MessageTypes_mex.RANGING_FINAL
%                             msgSize = MessageSizes.RANGING_FINAL_SIZE;
%                         case MessageTypes_mex.RANGING_RESULT
%                             msgSize = MessageSizes.RANGING_RESULT_SIZE;   
                    end

                    messageCompleteAt = (this.transmittedMessages{subIdx, 2}{2, msgIdx} + msgSize);
                    
                    if globalTime >= messageCompleteAt
                        if strcmp(this.transmittedMessages{subIdx, 2}{3, msgIdx}, "OKAY")
%                             this.subscribers{subIdx, 1}.notify(this.transmittedMessages{subIdx, 2}{1, msgIdx});
                            receivingNodeId = this.subscribers(subIdx, 1);
                            sendingNodeId = this.subscribers(senderIdx, 1);
                            % run state machine with incoming msg (deliver the
                            % message)
                            MatlabWrapper(4, this.mlWrapperPointer, receivingNodeId, sendingNodeId, this.transmittedMessages{subIdx, 2}{1, 1}.timestamp, this.transmittedMessages{subIdx, 2}{1, msgIdx});
                            % set to "not receiving" again
                            MatlabWrapper(8, this.mlWrapperPointer, this.subscribers(subIdx, 1));
                        elseif strcmp(this.transmittedMessages{subIdx, 2}{3, msgIdx}, "COLLIDING")
                            if this.isInRange(nodes{senderIdx, 2}, nodes{subIdx, 2})
                                if collisionsDetectable
                                    MatlabWrapper(6, this.mlWrapperPointer, this.subscribers(subIdx, 1)); % send COLLISION
                                end
                                % set to "not receiving" again
                                MatlabWrapper(8, this.mlWrapperPointer, this.subscribers(subIdx, 1));
                            end
                        end
                        msgsToRemove(end+1, 1) = msgIdx;
                    end
                end
                this.transmittedMessages{subIdx, 2}(:, msgsToRemove) = [];
            end
        end

    end

    methods (Access = private)
        
        function distance = getDistanceBetween(this, node1, node2)
            % calculate euclidean distance
            distance = sqrt((node1.x - node2.x)^2 + (node1.y - node2.y)^2);
        end

        function flagMessageAsIncomplete(this, receiverIdx, msgIdx)
            this.transmittedMessages{receiverIdx, 2}{3, msgIdx} = "INCOMPLETE";
        end
        
        function flagMessageAsColliding(this, receiverIdx, msgIdx)
            this.transmittedMessages{receiverIdx, 2}{3, msgIdx} = "COLLIDING";
        end
        
        function flagMessageAsOutOfRange(this, receiverIdx, msgIdx)
            this.transmittedMessages{receiverIdx, 2}{3, msgIdx} = "OOR";
        end

        function isListening = subscriberIsListening(this, subIdx)
            nodeId = this.subscribers(subIdx, 1);
            state = MatlabWrapper(11, this.mlWrapperPointer, nodeId);
%             isListening = (state == States_mex.LISTENING_CONNECTED ...
%                 | state == States_mex.LISTENING_UNCONNECTED ...
%                 | state == States_mex.LISTENING_RANGING);
            %... | state == States_mex.IDLE);
            
            % proper comparisons with enums take extremely long in
            % MATLAB, so we have to use magic numbers...
            % 1 = LISTENING_UNCONNECTED
            % 2 = LISTENING_CONNECTED
            % 6 = RANGING_LISTENING
              isListening = (state == 1 | state == 2 | state == 6);
        end
    end

    methods (Access = public)
        function inRange = isInRange(this, sender, receiver)
            dist = this.getDistanceBetween(sender, receiver);

            if (dist <= this.signalRange)
                inRange = true;
            else
                inRange = false;
            end
        end  
    end

end