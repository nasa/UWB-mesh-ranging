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

classdef StateActions < handle
    
    properties %(Access = private)
        scheduler;
        timeKeeping;
        messageHandler;
        slotMap;
        clock;
        rangingManager;
        neighborhood;
        config;
    end

    methods

        function this = StateActions(scheduler, timeKeeping, messageHandler, slotMap, clock, rangingManager, neighborhood, config)
            this.scheduler = scheduler;
            this.timeKeeping = timeKeeping;
            this.messageHandler = messageHandler;
            this.slotMap = slotMap;
            this.clock = clock;
            this.rangingManager = rangingManager;
            this.neighborhood = neighborhood;
            this.config = config;
        end

        function listeningUnconnectedTimeTicAction(this)
            localTime = this.clock.getLocalTime();
            waitTimeOver = this.timeKeeping.initialWaitTimeOver();
            nothingScheduled = this.scheduler.nothingScheduledYet();

            if waitTimeOver & nothingScheduled
                this.scheduler.scheduleNextPing(States.LISTENING_UNCONNECTED);
            end

            % in case a schedule was missed, cancel the schedule
            if localTime > this.scheduler.getTimeNextPingScheduled()
                this.scheduler.cancelScheduledPing();
            end
        end

        function sendingUnconnectedTimeTicAction(this)
            scheduledNow = this.scheduler.pingScheduledToNow();
            if scheduledNow
                this.messageHandler.sendInitialPing();
                this.scheduler.cancelScheduledPing();
            end
        end

        function listeningConnectedTimeTicAction(this)
            localTime = this.clock.getLocalTime();
            
            nothingScheduled = this.scheduler.nothingScheduledYet();
            if nothingScheduled
                this.scheduler.scheduleNextPing(States.LISTENING_CONNECTED);
            end

            % remove expired slots from slot maps (nodes that occupied the
            % slots have not send a message for a certain period of time)
            this.slotMap.removeExpiredSlotsFromOneHopSlotMap(localTime);
            this.slotMap.removeExpiredSlotsFromTwoHopSlotMap(localTime);
            this.slotMap.removeExpiredSlotsFromThreeHopSlotMap(localTime);

            % remove expired pending and own slots
            this.slotMap.removeExpiredPendingSlots(localTime);
            this.slotMap.removeExpiredOwnSlots(localTime);

            % remove neighbors that were not seen for a certain period of
            % time
            timeout = this.config.absentNeighborTimeout;
            this.neighborhood.removeAbsentNeighbors(timeout, localTime);

            % in case a schedule was missed, cancel the schedule
            if localTime > this.scheduler.getTimeNextPingScheduled()
                this.scheduler.cancelScheduledPing();
            end
        end 

        function sendingConnectedTimeTicAction(this)
            scheduledNow = this.scheduler.pingScheduledToNow();
            if scheduledNow
                this.messageHandler.sendPing();
                this.scheduler.cancelScheduledPing();
            end
        end

        function listeningUnconnectedIncomingMsgAction(this, msg)
            switch msg.type
                case MessageTypes.PING
                    this.messageHandler.handlePingUnconnected(msg);
                case MessageTypes.COLLISION
                    this.messageHandler.handleCollisionUnconnected(msg);
                case MessageTypes.PREAMBLE
                    this.messageHandler.handlePreamble(msg);
            end
        end

        function listeningConnectedIncomingMsgAction(this, msg)
            switch msg.type
                case MessageTypes.PING
                    this.messageHandler.handlePingConnected(msg);
                case MessageTypes.COLLISION
                    this.messageHandler.handleCollisionConnected(msg);
                case MessageTypes.PREAMBLE
                    this.messageHandler.handlePreamble(msg);
                case MessageTypes.RANGING_POLL
                    this.rangingManager.recordRangingMsg(msg);
            end
        end

        function listeningRangingIncomingMsgAction(this, msg)
            switch msg.type
                case MessageTypes.RANGING_RESP
                    this.rangingManager.recordRangingMsg(msg);
                case MessageTypes.RANGING_FINAL
                    this.rangingManager.recordRangingMsg(msg);
                case MessageTypes.RANGING_RESULT
                    this.rangingManager.recordRangingMsg(msg);
                    this.messageHandler.handleRangingResult(msg);
            end
        end

        function rangingPollTimeTicAction(this)
%             this.stateData = "POLL";
%             if ~this.pingSentFlag
                oneHopNeighbors = this.neighborhood.getOneHopNeighbors();
                if ~isempty(oneHopNeighbors)
                    this.messageHandler.sendRangingPollMsg();
                end
%                 this.lastSendTime = this.time.getLocalTime();
%             end
%             this.rangingOngoing = true;
%             this.pingSentFlag = true;
        end

        function rangingResponseTimeTicAction(this, inMsg)
%             this.stateData = "RESP";
%             if ~this.pingSentFlag
                this.messageHandler.sendRangingResponseMsg(inMsg);
%                 this.lastSendTime = this.time.getLocalTime();
%             end
%             this.pingSentFlag = true;
        end

        function rangingFinalTimeTicAction(this, inMsg)
%             this.stateData = "FINAL";
%             if ~this.pingSentFlag
                this.messageHandler.sendRangingFinalMsg(inMsg);
%                 this.lastSendTime = this.time.getLocalTime();
%             end
%             this.pingSentFlag = true;
        end

        function rangingResultTimeTicAction(this, inMsg)
%             this.stateData = "RESULT";
%             if ~this.pingSentFlag
                this.messageHandler.sendRangingResultMsg(inMsg);
%                 this.lastSendTime = this.time.getLocalTime();
%             end
%             this.pingSentFlag = true;
        end
        
        function idleTimeTicAction(this)
            
        end
        
        function idleIncomingMsgAction(this, msg)
            this.listeningConnectedIncomingMsgAction(msg);
        end
      
    end
end











