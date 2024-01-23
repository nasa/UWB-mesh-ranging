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

classdef MessageHandler < handle
    
    properties %(Access = private)
        networkManager;
        timeKeeping;
        scheduler;
        slotMap;
        driverAbstraction;
        clock; 
        neighborhood;

        id;
        lastMessageSent;
        lastTimeSent;
    end

    methods
        function this = MessageHandler(networkManager, timeKeeping, scheduler, slotMap, driverAbstraction, clock, neighborhood)
            this.networkManager = networkManager;
            this.timeKeeping = timeKeeping;
            this.scheduler = scheduler;
            this.slotMap = slotMap;
            this.driverAbstraction = driverAbstraction;
            this.clock = clock;
            this.neighborhood = neighborhood;
        end

        function setId(this, id)
            this.id = id;
        end

        function handlePreamble(this, msg)
            this.timeKeeping.recordPreamble(msg);
        end
        
        function handlePingUnconnected(this, msg)
            % join the network
            this.joinNetwork(msg);
            this.updateSlots(msg);

            % add neighbor
            localTime = this.clock.getLocalTime();
            this.neighborhood.addOrUpdateOneHopNeighbor(msg.senderId, localTime);      

            % cancel schedules to prevent interfering with the new network
            this.scheduler.cancelScheduledPing();
        end

        function handlePingConnected(this, msg)
            % add neighbor
            localTime = this.clock.getLocalTime();
            this.neighborhood.addOrUpdateOneHopNeighbor(msg.senderId, localTime);   

            receivedPingNetAgeNow = this.timeKeeping.calculateNetworkAgeForLastPreamble(msg.networkAge);
            isForeignPing = this.networkManager.isPingFromForeignNetwork(msg, localTime, receivedPingNetAgeNow);

            if isForeignPing
                ownNetworkAge = this.networkManager.calculateNetworkAge(localTime);
                foreignNetPrecedes = receivedPingNetAgeNow > ownNetworkAge;
                
                if foreignNetPrecedes
                    this.switchNetwork(msg);
                    this.updateSlots(msg);
                elseif ownNetworkAge == receivedPingNetAgeNow
                    % both created at the exact same time, but different
                    % IDs; go back to unconnected listening
                    this.networkManager.disconnect();
                    this.scheduler.cancelScheduledPing();
                else
                    translatedCollisionTimes = this.timeKeeping.translateTimeOfCollisionReports(msg);
                    collidingSlots = zeros(1, size(translatedCollisionTimes, 2));
                    for i = 1:size(translatedCollisionTimes, 2)
                        time = translatedCollisionTimes(1, i);
                        collidingSlots(1, i) = this.timeKeeping.calculateOwnSlotAtTime(time);
                    end

                    if ~this.slotMap.ownNetworkExists(collidingSlots)
                        this.switchNetwork(msg);
                        this.updateSlots(msg);
                    end
                end
            else
                this.updateSlots(msg);
            end
        end

        function handleCollisionUnconnected(this, msg)
            localTime = this.clock.getLocalTime();
            this.slotMap.recordCollisionTime(localTime);
        end

        function handleCollisionConnected(this, msg)
            localTime = this.clock.getLocalTime();
            currentSlot = this.timeKeeping.calculateCurrentSlotNum();

            this.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime);
            this.slotMap.recordCollisionTime(localTime);

            currentSlot = this.timeKeeping.calculateCurrentSlotNum();
            if this.slotMap.isOwnSlot(currentSlot)
                this.slotMap.releaseOwnSlots(currentSlot);
            end

            if this.slotMap.isPendingSlot(currentSlot)
                this.slotMap.releasePendingSlots(currentSlot);
            end
        end

        function handleRangingResult(this, msg)
            localTime = this.clock.getLocalTime();
            this.neighborhood.updateRanging(msg.senderId, localTime);
        end

        function sendInitialPing(this)
            localTime = this.clock.getLocalTime();
            this.networkManager.createNetwork(localTime);
            this.timeKeeping.setFrameStartToTime(localTime);
            this.sendPing();
        end

        function sendPing(this)
            msg = this.createPingMessage();
            this.driverAbstraction.transmitPing(msg);
            this.lastMessageSent = msg;
            this.lastTimeSent = this.clock.getLocalTime();
            
            currentSlot = this.timeKeeping.calculateCurrentSlotNum();
            localTime = this.clock.getLocalTime();
            neighbors = this.neighborhood.getOneHopNeighbors();
            isOwn = this.slotMap.isOwnSlot(currentSlot);
            isPending = this.slotMap.isPendingSlot(currentSlot);

            if ~isOwn && ~isPending
                this.slotMap.addPendingSlot(currentSlot, neighbors, localTime);
            end
            assert(~(isOwn & isPending), "Error in MessageHandler::sendPing(): Slot is both own and pending");
        end

        function sendRangingPollMsg(this)
            msg = this.createRangingPollMessage();
            this.driverAbstraction.transmitRangingPoll(msg);
            this.lastMessageSent = msg;
            this.lastTimeSent = this.clock.getLocalTime();
        end

        function sendRangingResponseMsg(this, inMsg)
            msg = this.createRangingResponseMessage(inMsg);
            this.driverAbstraction.transmitRangingResponse(msg);
            this.lastMessageSent = msg;
            this.lastTimeSent = this.clock.getLocalTime();
        end

        function sendRangingFinalMsg(this, inMsg)
            msg = this.createRangingFinalMessage(inMsg);
            this.driverAbstraction.transmitRangingFinal(msg);
            this.lastMessageSent = msg;
            this.lastTimeSent = this.clock.getLocalTime();
        end

        function sendRangingResultMsg(this, inMsg)
            msg = this.createRangingResultMessage(inMsg);
            this.driverAbstraction.transmitRangingResult(msg);
            this.lastMessageSent = msg;
            this.lastTimeSent = this.clock.getLocalTime();

            localTime = this.clock.getLocalTime();
            this.neighborhood.updateRanging(msg.recipient, localTime);
        end

        function lastMsgSent = getLastMessageSent(this)
            lastMsgSent = this.lastMessageSent;
        end

        function lastTimeSent = getLastTimeSent(this)
            lastTimeSent = this.lastTimeSent;
        end

    end

    methods (Access = private)
        function switchNetwork(this, msg)
            % slot shifting is currently not done
%             % shift slots to adapt to new network
%             offset = this.timeKeeping.calculateSlotOffset(msg);
%             this.slotMap.shiftSlotMap(offset);
%             this.slotMap.shiftOwnSlots(offset);
            
            % join the network
            this.joinNetwork(msg);
            this.scheduler.cancelScheduledPing();
        end

        function joinNetwork(this, msg)
            this.networkManager.setNetworkStatusToConnected();
            this.networkManager.setNetworkId(msg.networkId);
            netAgeNow = this.timeKeeping.calculateNetworkAgeForLastPreamble(msg.networkAge);
            this.networkManager.saveNetworkAgeAtJoining(netAgeNow);

            localTime = this.clock.getLocalTime();
            this.networkManager.saveLocalTimeAtJoining(localTime);
            this.timeKeeping.setFrameStartTimeForLastPreamble(msg.timeSinceFrameStart);
            
            % release own and pending slots
            ownSlots = this.slotMap.getOwnSlots();
            if ~isempty(ownSlots)
                for i = 1:size(ownSlots)
                    this.slotMap.releaseOwnSlots(ownSlots(1, i));
                end
            end
            
            pendingSlots = this.slotMap.getPendingSlots();
            if ~isempty(pendingSlots)
                for i = 1:size(pendingSlots)
                    this.slotMap.releasePendingSlots(pendingSlots(1, i));
                end
            end
        end

        function updateSlots(this, msg)
            this.slotMap.updatePendingSlotAcks(msg);
            this.slotMap.addAcknowledgedPendingSlotsToOwn();

            collidingOwnSlots = this.slotMap.checkOwnSlotsForCollisions(msg);
            this.slotMap.releaseOwnSlots(collidingOwnSlots);

            collidingPendingSlots = this.slotMap.checkPendingSlotsForCollisions(msg);
            this.slotMap.releasePendingSlots(collidingPendingSlots);

            % update slot maps
            localTime = this.clock.getLocalTime();
            currentSlot = this.timeKeeping.calculateCurrentSlotNum();

            this.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime);
            this.slotMap.updateTwoHopSlotMap(msg, localTime);
            this.slotMap.updateThreeHopSlotMap(msg, localTime);

            % cancel schedule if the slot is colliding
            nextScheduledSlot = this.scheduler.getSlotOfNextSchedule();
            nextScheduledColliding = fastIntersect(nextScheduledSlot, [collidingOwnSlots, collidingPendingSlots]);
            if ~isempty(nextScheduledColliding)
                this.scheduler.cancelScheduledPing();
            end
        end

        function msg = createPingMessage(this)
            localTime = this.clock.getLocalTime();

            msg.type = MessageTypes.PING;
            msg.senderId = this.id;
            assert(~isempty(this.id), "Error in MessageHandler::createPingMessage(): ID is not set");
            
            oneHopSlotMap = this.slotMap.getOneHopSlotMap();
            msg.oneHopSlotsStatus = oneHopSlotMap.status;
            msg.oneHopSlotsIds = oneHopSlotMap.ids;

            twoHopSlotMap = this.slotMap.getTwoHopSlotMap();
            msg.twoHopSlotsStatus = twoHopSlotMap.status;
            msg.twoHopSlotsIds = twoHopSlotMap.ids;

            msg.timeSinceFrameStart = this.timeKeeping.calculateTimeSinceFrameStart();

            msg.networkId = this.networkManager.getNetworkId();

            msg.networkAge = this.networkManager.calculateNetworkAge(localTime);
            msg.collisionTimes = this.slotMap.getCollisionTimes(localTime);
        end

        function msg = createRangingPollMessage(this)
            nextRangingNeighbor = this.neighborhood.getNextRangingNeighbor();
            if ~isempty(nextRangingNeighbor)
                msg.recipient = nextRangingNeighbor;
            else
                warning('neighborhood empty, but ranging initiated');
            end
            
            msg.type = MessageTypes.RANGING_POLL;
            msg.senderId = this.id;
        end

        function msg = createRangingResponseMessage(this, inMsg)
            msg.type = MessageTypes.RANGING_RESP;
            msg.senderId = this.id;
            msg.recipient = inMsg.senderId;
        end

        function msg = createRangingFinalMessage(this, inMsg)
            msg.type = MessageTypes.RANGING_FINAL;
            msg.senderId = this.id;
            msg.recipient = inMsg.senderId;
        end

        function msg = createRangingResultMessage(this, inMsg)
            msg.type = MessageTypes.RANGING_RESULT;
            msg.senderId = this.id;
            msg.recipient = inMsg.senderId;
            msg.result = 1337;
        end
    end
end

function intersection = fastIntersect(firstMat, secondMat)
    intersection = firstMat(ismember(firstMat, secondMat));
end
