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

classdef GuardConditions < handle
    
    properties (Access = private)
        slotMap;
        networkManager;
        timeKeeping;
        messageHandler;
        clock;
        scheduler;
        driverAbstraction;
        neighborhood;
        config;
    end

    methods
        
        function this = GuardConditions(slotMap, networkManager, timeKeeping, messageHandler, clock, scheduler, driverAbstraction, neighborhood, config)
            this.slotMap = slotMap;
            this.networkManager = networkManager;
            this.timeKeeping = timeKeeping;
            this.messageHandler = messageHandler;
            this.clock = clock;
            this.scheduler = scheduler;
            this.driverAbstraction = driverAbstraction;
            this.neighborhood = neighborhood;
            this.config = config;
        end

        function allowed = listeningUncToSendingUncAllowed(this)
            allowed = false;
            currentSlot = this.timeKeeping.calculateCurrentSlotNum();
            if this.slotMap.clearToSend(currentSlot) & ~this.driverAbstraction.isMessageIncoming()
                allowed = true;
            end
        end

        function allowed = sendingUncToListeningConAllowed(this)
            % no conditions
            allowed = true;
        end

        function allowed = listeningConToSendingConAllowed(this)
            allowed = false;
            currentSlot = this.timeKeeping.calculateCurrentSlotNum();
            if this.slotMap.clearToSend(currentSlot) & ...
                    ~this.driverAbstraction.isMessageIncoming() & ...
                        this.networkManager.getNetworkStatus() == NetworkStatus.CONNECTED
                allowed = true;
            end
        end

        function allowed = sendingConToListeningConAllowed(this)
            % no conditions
            allowed = true;
        end

        function allowed = listeningConToListeningUncAllowed(this)
            allowed = false;
            oneHopSlotMap = this.slotMap.getOneHopSlotMap();
            if this.networkManager.getNetworkStatus() == NetworkStatus.NOT_CONNECTED
                allowed = true;
            elseif (~this.slotMap.hasOwnOrPendingSlots() & this.networkManager.networkStartedByThisNode() & nnz(oneHopSlotMap.status) == 0)
                allowed = true;
            end
        end

        function allowed = rangingPollAllowed(this)
            allowed = false;

            currentSlot = this.timeKeeping.calculateCurrentSlotNum();
            localTime = this.clock.getLocalTime();

            isOwnSlot = this.slotMap.isOwnSlot(currentSlot);

            if isOwnSlot
                % check if remaining time in slot is enough
                % to do ranging
                remainingTime = this.timeKeeping.getTimeRemainingInCurrentSlot();
                % only if no ping is scheduled in this slot
                % anymore (i.e. has been sent already)
                if this.scheduler.getTimeNextPingScheduled() > localTime + remainingTime
                    rangingTime = MessageSizes.RANGING_POLL_SIZE + MessageSizes.RANGING_RESP_SIZE + MessageSizes.RANGING_FINAL_SIZE + ...
                        MessageSizes.RANGING_RESULT_SIZE + 3 * MessageSizes.RANGING_WAITTIME;
                    
                    % only if enough time left to finish the ranging
                    if remainingTime > (rangingTime + this.config.guardPeriodLength)
                        allowed = true;
                    end
                end
            end
        end
        
        function allowed = idleingAllowed(this)
            allowed = false;
            if this.config.autoDutyCycle >= 1 % must be at least 1
                currentSlot = this.timeKeeping.calculateCurrentSlotNum();
                if currentSlot == 1 % only start idleing at the beginning of a new frame
                    ownSlots = this.slotMap.getOwnSlots();
                    if (size(ownSlots, 2) == this.config.slotGoal) % only start idleing if node reached the goal
                        localTime = this.clock.getLocalTime();
                        lastTimeIdled = this.timeKeeping.getLastTimeIdled();
                        % must not have idled for at least two frames
                        notRecentlyIdled = ((localTime - lastTimeIdled) > 2 * (this.config.slotLength * this.config.slotsPerFrame));
                        
                        % must not have gotten new neighbors in the last
                        % frame (makes sure it sends at least one ping to
                        % the new neighbor to acknowledge its slot)
                        newestNeighbor = this.neighborhood.getNewestNeighbor();
                        newestNeighborTimeJoined = this.neighborhood.getTimeWhenNewestNeighborJoined();
                        
                        twoHopSlotMap = this.slotMap.getTwoHopSlotMap();
                        threeHopSlotMap = this.slotMap.getThreeHopSlotMap();
                        
                        
                        noNewNeighbors = false;
                        if isempty(newestNeighbor)
                            noNewNeighbors = true;
                        end
                        
                        % if newest neighbor is already in two or three hop
                        % slot map (i. e. not new in the network), it is
                        % okay to idle
                        if ~isempty(find(newestNeighbor == twoHopSlotMap.ids, 1)) | ~isempty(find(newestNeighbor == threeHopSlotMap.ids, 1))
                            noNewNeighbors = true;
                            
                        % if neighbor joined more than one frame ago, it is
                        % okay to idle
                        elseif (localTime - newestNeighborTimeJoined) >= (this.config.slotLength * this.config.slotsPerFrame)
                            noNewNeighbors = true;
                        end
                        
                        noRecentCollisions = isempty(this.slotMap.getCollisionTimes(localTime));
                        
                        noRecentNewReservations = (localTime >= (this.slotMap.getLastNewReservationTime() + (this.config.slotLength * this.config.slotsPerFrame)));
                        
                        guardConditions = [notRecentlyIdled, noNewNeighbors, noRecentCollisions, noRecentNewReservations];
                        guardConditionsSatisfied = nnz(guardConditions) == size(guardConditions, 2);
                        if guardConditionsSatisfied 
                            allowed = true;                            
                        end
                    end
                end
            end
        end
        
        function allowed = idleToListeningConAllowed(this)
            allowed = false;
            % check if the node should wake up (based on
            % the network age to make sure all nodes wake up at the same time)
            localTime = this.clock.getLocalTime();
            netAge = this.networkManager.calculateNetworkAge(localTime);
            if this.timeKeeping.isAutoCycleWakeupTime(netAge)
                allowed = true;
            end
        end
        
        function allowed = idleToListeningConAllowedIncomingMsg(this, msg)
            allowed = false;
            if msg.type == MessageTypes.PING
                localTime = this.clock.getLocalTime();
                receivedPingNetAgeNow = this.timeKeeping.calculateNetworkAgeForLastPreamble(msg.networkAge);
                foreignPing = (this.networkManager.isPingFromForeignNetwork(msg, localTime, receivedPingNetAgeNow));

                oneHopSlotMap = this.slotMap.getOneHopSlotMap();
                twoHopSlotMap = this.slotMap.getTwoHopSlotMap();
                threeHopSlotMap = this.slotMap.getThreeHopSlotMap();

                sendingNodeDoesNotHaveSlot = (isempty(find(msg.senderId == oneHopSlotMap.ids, 1)) & isempty(find(msg.senderId == twoHopSlotMap.ids, 1)) & isempty(find(msg.senderId == threeHopSlotMap.ids, 1)));
                if foreignPing | sendingNodeDoesNotHaveSlot | msg.type == MessageTypes.COLLISION | isempty(this.slotMap.ownSlots)
                    allowed = true;
                end
            end
        end

    end

end
