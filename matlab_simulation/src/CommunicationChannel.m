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

classdef CommunicationChannel < handle

    properties %(Access = private)
        subscribers;
        transmittedMessages;
        ids;
    end

    methods
        function this = CommunicationChannel()
            this.subscribers = {};
            this.transmittedMessages = {};
            this.ids = [];
        end

        function subscribe(this, node)
            this.subscribers{end + 1, 1} = node;
            this.transmittedMessages{end + 1, 1} = node.getId();
            this.transmittedMessages{end, 2} = {};
            this.ids(end + 1, 1) = node.getId();
        end

        function transmit(this, msg, globalTime)
            for subIdx = 1:size(this.subscribers, 1)
                if (this.subscribers{subIdx, 1}.getId() == msg.senderId)
                    % don't transmit the message to the sender
                    continue;
                end

                this.transmittedMessages{subIdx, 2}{1, end + 1} = msg;
                this.transmittedMessages{subIdx, 2}{2, end} = globalTime;
                this.transmittedMessages{subIdx, 2}{3, end} = "OKAY";
            end
        end

        function execute(this, globalTime)
            for subIdx = 1:size(this.subscribers, 1)
                for msgIdx = 1:size(this.transmittedMessages{subIdx, 2}, 2)
                    senderIdx = find(this.ids == this.transmittedMessages{subIdx, 2}{1, msgIdx}.senderId);

                    % calculate when message arrives (including delay) -
                    % when the message first comes in, not when it is
                    % complete!
                    arrivalTimeThisMessageGlobalTimeframe = this.transmittedMessages{subIdx, 2}{2, msgIdx};

                    if globalTime >= arrivalTimeThisMessageGlobalTimeframe
                        % if nodes are not in range at anytime while the 
                        % message is transmitted, flag it as out of range
                        if ~this.isInRange(this.subscribers{senderIdx}, this.subscribers{subIdx, 1})
                            this.flagMessageAsOutOfRange(subIdx, msgIdx);
                        end

                        % if receiver is not listening, flag it as
                        % incomplete
                        if ~this.subscriberIsListening(subIdx)
                            this.flagMessageAsIncomplete(subIdx, msgIdx);
                        end

                        % if any other message arrives while this message
                        % is incoming, flag it as incomplete
                        for otherMsgIdx = 1:size(this.transmittedMessages{subIdx, 2}, 2)
                            otherSenderIdx = find(this.ids == this.transmittedMessages{subIdx, 2}{1, otherMsgIdx}.senderId);

                            otherDist = this.getDistanceBetween(this.subscribers{subIdx, 1}, this.subscribers{otherSenderIdx, 1});
%                             otherTransmissionDelay = this.calculateTransmissionDelay(otherDist);
                            otherMessageArrivalTime = this.transmittedMessages{subIdx, 2}{2, otherMsgIdx};% + otherTransmissionDelay;
                            if (globalTime >= otherMessageArrivalTime) & this.isInRange(this.subscribers{otherSenderIdx}, this.subscribers{subIdx, 1}) & this.isInRange(this.subscribers{senderIdx}, this.subscribers{subIdx, 1})
                                if ~(otherMsgIdx == msgIdx)
                                    this.flagMessageAsIncomplete(subIdx, msgIdx);
                                    
%                                     if this.simConfig.collisionDetection
                                        % send collision
                                        msg = [];

                                        msg.type = MessageTypes.COLLISION;
                                        this.subscribers{subIdx, 1}.notify(msg); 
%                                     end
                                end
                            end
                        end

                        % if message is still okay, deliver a preamble
                        % message to simulate that a node would start
                        % receiving an incoming transmission
                        if globalTime == arrivalTimeThisMessageGlobalTimeframe & (strcmp(this.transmittedMessages{subIdx, 2}{3, msgIdx}, "OKAY"))
                            msg.type = MessageTypes.PREAMBLE;
                            msg.senderId = this.transmittedMessages{subIdx, 2}{1, msgIdx}.senderId;
                            this.subscribers{subIdx, 1}.notify(msg);
                        end
                    end
                end

                % for every message:
                % - if message complete: notify and delete
                msgsToRemove = [];
                for msgIdx = 1:size(this.transmittedMessages{subIdx, 2}, 2)
                    senderIdx = find(this.ids == this.transmittedMessages{subIdx, 2}{1, msgIdx}.senderId);
                    dist = this.getDistanceBetween(this.subscribers{subIdx, 1}, this.subscribers{senderIdx, 1});
%                     transmissionDelay = this.calculateTransmissionDelay(dist);


                    switch this.transmittedMessages{subIdx, 2}{1, msgIdx}.type
                        case MessageTypes.PING
                            msgSize = MessageSizes.PING_SIZE;
                        case MessageTypes.RANGING_POLL
                            msgSize = MessageSizes.RANGING_POLL_SIZE;
                        case MessageTypes.RANGING_RESP
                            msgSize = MessageSizes.RANGING_RESP_SIZE;
                        case MessageTypes.RANGING_FINAL
                            msgSize = MessageSizes.RANGING_FINAL_SIZE;
                        case MessageTypes.RANGING_RESULT
                            msgSize = MessageSizes.RANGING_RESULT_SIZE;                            
                    end

                    messageCompleteAt = (this.transmittedMessages{subIdx, 2}{2, msgIdx} + msgSize);
                    
                    if globalTime >= messageCompleteAt
                        if strcmp(this.transmittedMessages{subIdx, 2}{3, msgIdx}, "OKAY")
                            this.subscribers{subIdx, 1}.notify(this.transmittedMessages{subIdx, 2}{1, msgIdx});
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
            pos1 = node1.getPosition();
            pos2 = node2.getPosition();
            distance = sqrt((pos1.x - pos2.x)^2 + (pos1.y - pos2.y)^2);
        end

        function flagMessageAsIncomplete(this, receiverIdx, msgIdx)
            this.transmittedMessages{receiverIdx, 2}{3, msgIdx} = "INCOMPLETE";
        end

        function flagMessageAsOutOfRange(this, receiverIdx, msgIdx)
            this.transmittedMessages{receiverIdx, 2}{3, msgIdx} = "OOR";
        end

        function isListening = subscriberIsListening(this, subIdx)
            isListening = (this.subscribers{subIdx,1}.stateMachine.getState() == States.LISTENING_CONNECTED ...
                | this.subscribers{subIdx,1}.stateMachine.getState() == States.LISTENING_UNCONNECTED ...
                | this.subscribers{subIdx,1}.stateMachine.getState() == States.LISTENING_RANGING ...
                | this.subscribers{subIdx,1}.stateMachine.getState() == States.IDLE);
        end
    end

    methods (Access = public)
        function inRange = isInRange(this, sender, receiver)
            dist = this.getDistanceBetween(sender, receiver);

            if (dist <= sender.getSignalRange())
                inRange = true;
            else
                inRange = false;
            end
        end  
    end

end