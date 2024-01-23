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

classdef SlotMap < handle

    properties %(Access = private)
        config;
        randomNumbers

        id;

        oneHopSlotMap;
        twoHopSlotMap;
        threeHopSlotMap;

        pendingSlots;
        pendingSlotsAcknowledgedBy;
        neighborsWhenPendingAdded;
        collisionPerceivedAt;    
        lastNewReservationTime;

        ownSlots;
    end

    methods
        function this = SlotMap(config, randomNumbers)
            this.config = config;

            this.randomNumbers = randomNumbers;

            this.oneHopSlotMap.status = zeros(1, this.config.slotsPerFrame);
            this.oneHopSlotMap.ids = zeros(1, this.config.slotsPerFrame);
            this.oneHopSlotMap.lastUpdated = zeros(1, this.config.slotsPerFrame);

            this.twoHopSlotMap.status = zeros(1, this.config.slotsPerFrame);
            this.twoHopSlotMap.ids = zeros(1, this.config.slotsPerFrame);
            this.twoHopSlotMap.lastUpdated = zeros(1, this.config.slotsPerFrame);

            this.threeHopSlotMap.status = zeros(1, this.config.slotsPerFrame);
            this.threeHopSlotMap.ids = zeros(1, this.config.slotsPerFrame);
            this.threeHopSlotMap.lastUpdated = zeros(1, this.config.slotsPerFrame);

            this.pendingSlotsAcknowledgedBy = zeros(this.config.slotsPerFrame, 1);
            this.neighborsWhenPendingAdded = cell(this.config.slotsPerFrame, 1);
            this.collisionPerceivedAt = [];
            this.lastNewReservationTime = 0;
        end

        function oneHopSlotMap = getOneHopSlotMap(this)
            oneHopSlotMap = this.oneHopSlotMap;
        end

        function twoHopSlotMap = getTwoHopSlotMap(this)
            twoHopSlotMap = this.twoHopSlotMap;
        end

        function threeHopSlotMap = getThreeHopSlotMap(this)
            threeHopSlotMap = this.threeHopSlotMap;
        end

        function updateOneHopSlotMap(this, msg, currentSlot, localTime)
            currentStatus = this.oneHopSlotMap.status(1, currentSlot);

            switch msg.type
                case MessageTypes.PING
                    currentId = this.oneHopSlotMap.ids(1, currentSlot);
                    newId = msg.senderId;

                    switch currentStatus
                        case SlotOccupancyStates.FREE
                            this.oneHopSlotMap.status(1, currentSlot) = SlotOccupancyStates.OCCUPIED;
                            this.oneHopSlotMap.ids(1, currentSlot) = newId;
                            this.oneHopSlotMap.lastUpdated(1, currentSlot) = localTime;
                        case SlotOccupancyStates.OCCUPIED
                            if newId == currentId
                                this.oneHopSlotMap.lastUpdated(1, currentSlot) = localTime;
                            else
                                timeout = this.config.occupiedSlotTimeout;
                                if this.oneHopSlotIsExpired(currentSlot, localTime, timeout)
                                    this.oneHopSlotMap.status(1, currentSlot) = SlotOccupancyStates.OCCUPIED;
                                    this.oneHopSlotMap.ids(1, currentSlot) = newId;
                                    this.oneHopSlotMap.lastUpdated(1, currentSlot) = localTime;
                                end
                            end
                        case SlotOccupancyStates.COLLIDING
                            timeout = this.config.collidingSlotTimeout;
                            if this.oneHopSlotIsExpired(currentSlot, localTime, timeout)
                                this.oneHopSlotMap.status(1, currentSlot) = SlotOccupancyStates.OCCUPIED;
                                this.oneHopSlotMap.ids(1, currentSlot) = newId;
                                this.oneHopSlotMap.lastUpdated(1, currentSlot) = localTime;
                            end
                    end
                    
                    % it is a new reservation attempt when the two hop slot
                    % map does not contain the id of the sender (i.e. its
                    % slot still needs acknowledgement)
                    if ~(msg.twoHopSlotsIds(1, currentSlot) == msg.senderId)
                        this.lastNewReservationTime = localTime;
                    end
                    
                case MessageTypes.COLLISION
                    this.oneHopSlotMap.status(1, currentSlot) = SlotOccupancyStates.COLLIDING;
                    this.oneHopSlotMap.ids(1, currentSlot) = 0;
                    this.oneHopSlotMap.lastUpdated(1, currentSlot) = localTime;
            end
        end

        function updateTwoHopSlotMap(this, msg, localTime)
            % use oneHopSlots info from msg because one hop of a neighbor
            % means two hop of this node
            msg.multiHopSlotsStatus = msg.oneHopSlotsStatus;
            msg.multiHopSlotsIds = msg.oneHopSlotsIds; 

            msg.twoHopSlotsStatus = [];
            msg.twoHopSlotsIds = []; 

            slotMap = this.updateMultiHopSlotMap(msg, localTime, this.twoHopSlotMap);
            this.twoHopSlotMap = slotMap;
        end

        function updateThreeHopSlotMap(this, msg, localTime)
            % use twoHopSlots info from msg because two hop of a neighbor
            % means three hop of this node
            msg.multiHopSlotsStatus = msg.twoHopSlotsStatus;
            msg.multiHopSlotsIds = msg.twoHopSlotsIds; 

            msg.threeHopSlotsStatus = [];
            msg.threeHopSlotsIds = []; 

            slotMap = this.updateMultiHopSlotMap(msg, localTime, this.threeHopSlotMap);
            this.threeHopSlotMap = slotMap;
        end

        function addPendingSlot(this, slot, neighbors, localTime)
            this.pendingSlots(1, end+1) = slot;
            this.pendingSlots(2, end) = localTime;
            this.pendingSlotsAcknowledgedBy(slot, 1) = this.id;

            this.neighborsWhenPendingAdded{slot, 1} = neighbors;
        end

        function result = isPendingSlot(this, slot)
            result = ~isempty(this.pendingSlots(ismember(this.pendingSlots, slot)));
        end

        function result = isOwnSlot(this, slot)
            ownSlots = this.getOwnSlots();
            result = ~isempty(ownSlots(ismember(ownSlots, slot)));
        end

        function acknowledgedBy = updatePendingSlotAcks(this, msg)
            % if pending slot was acknowledged, save which node
            % acknowledged it and return all nodes that did (return is
            % mostly used for testing)
    
            for i = 1:size(this.pendingSlots, 2)
                pendingSlotNum = this.pendingSlots(1, i);
                if msg.oneHopSlotsIds(1, pendingSlotNum) == this.id
                    this.pendingSlotsAcknowledgedBy(pendingSlotNum, end + 1) = msg.senderId;
                end
            end

            acknowledgedBy = this.pendingSlotsAcknowledgedBy;
        end

        function addAcknowledgedPendingSlotsToOwn(this)
            removeIdx = [];
            removeSlots = [];
            for i = 1:size(this.pendingSlots, 2)
                pendingSlotNum = this.pendingSlots(1, i);
                if this.slotWasAcknowledged(pendingSlotNum)
                    this.ownSlots(1, end + 1) = pendingSlotNum;
                    removeIdx(1, end + 1) = i;
                    removeSlots(1, end + 1) = pendingSlotNum;
                end
            end

            this.pendingSlots(:, removeIdx) = [];
            this.pendingSlotsAcknowledgedBy(removeSlots, :) = [];
            if ~isempty(removeSlots)
                this.neighborsWhenPendingAdded(removeSlots, 1) = cell(1,1);
            end
        end

        function collidingSlots = checkOwnSlotsForCollisions(this, msg)
            collidingSlots = this.checkSlotsForCollisions(msg, this.ownSlots);
        end
        
        function collidingSlots = checkPendingSlotsForCollisions(this, msg)
            collidingSlots = this.checkSlotsForCollisions(msg, this.pendingSlots);
        end

        function releaseOwnSlots(this, slotsToRelease)
            this.ownSlots = this.releaseSlots(this.ownSlots, slotsToRelease);
            this.removeOwnAndPendingSlotsFromSlotMaps(slotsToRelease);
        end

        function releasePendingSlots(this, slotsToRelease)
            this.pendingSlots = this.releaseSlots(this.pendingSlots, slotsToRelease);
            this.removeOwnAndPendingSlotsFromSlotMaps(slotsToRelease);
        end

        function goalMet = slotReservationGoalMet(this)
           goalMet = (size(this.ownSlots, 2) + size(this.pendingSlots, 2)) >= this.config.slotGoal;
        end

        function removeExpiredSlotsFromOneHopSlotMap(this, localTime)
            timeout = this.config.slotExpirationTimeout;

            for slot = 1:size(this.oneHopSlotMap.status, 2)
                if localTime > this.oneHopSlotMap.lastUpdated(1, slot) + timeout
                    this.oneHopSlotMap.status(1, slot) = SlotOccupancyStates.FREE;
                    this.oneHopSlotMap.ids(1, slot) = 0;
                end
            end
        end

        function removeExpiredSlotsFromTwoHopSlotMap(this, localTime)
            for slot = 1:size(this.twoHopSlotMap.status, 2)
                if this.isOwnSlot(slot)
                    timeout = this.config.ownSlotExpirationTimeout;
                else
                    timeout = this.config.slotExpirationTimeout;
                end
                
                if localTime > this.twoHopSlotMap.lastUpdated(1, slot) + timeout
                    this.twoHopSlotMap.status(1, slot) = SlotOccupancyStates.FREE;
                    this.twoHopSlotMap.ids(1, slot) = 0;
                end
            end
        end

        function removeExpiredSlotsFromThreeHopSlotMap(this, localTime)
            for slot = 1:size(this.threeHopSlotMap.status, 2)
                if this.isOwnSlot(slot)
                    timeout = this.config.ownSlotExpirationTimeout;
                else
                    timeout = this.config.slotExpirationTimeout;
                end
                
                if localTime > this.threeHopSlotMap.lastUpdated(1, slot) + timeout
                    this.threeHopSlotMap.status(1, slot) = SlotOccupancyStates.FREE;
                    this.threeHopSlotMap.ids(1, slot) = 0;
                end
            end
        end

        function removeExpiredPendingSlots(this, localTime)
            timeout = this.config.ownSlotExpirationTimeout;
            if ~isempty(this.pendingSlots)
                expiredSlotsLogical = this.pendingSlots(2, :) < (localTime - timeout);
                this.pendingSlots = this.pendingSlots(:, ~expiredSlotsLogical);
            end
        end

        function removed = removeExpiredOwnSlots(this, localTime)
            timeout = this.config.ownSlotExpirationTimeout;
            slotsToRemove = [];
            for i = 1:size(this.ownSlots, 2)
                ownSlot = this.ownSlots(1,i);
                if localTime > (this.twoHopSlotMap.lastUpdated(1,ownSlot) + timeout)
                    slotsToRemove(1, end+1) = i;
                end
            end

            removed = this.ownSlots(:, slotsToRemove);
            this.ownSlots(:, slotsToRemove) = [];
        end

        function reservableSlot = getReservableSlot(this)
            % a slot is reservable when it is either free or colliding in
            % any slot map; colliding slots are also considered because
            % otherwise deadlocks could happen
            freeSlots = this.findFreeSlotsInThreeHopNeighborhood();
            collidingSlots = this.findCollidingSlotsInThreeHopNeighborhood();

            reservableSlots = unique([freeSlots, collidingSlots]);

            reservableSlot = this.randomNumbers.getRandomElementFrom(reservableSlots);
        end

        function collisionTimes = getCollisionTimes(this, localTime)
            % returns collision times that are still relevant (not older
            % than one frame)
            collisionTimes = [];
            toDelete = [];
            for i = 1:size(this.collisionPerceivedAt, 1)
                if ~(localTime > (this.collisionPerceivedAt(i,1) + this.config.frameLength))
                    collisionTimes(end+1,1) = this.collisionPerceivedAt(i,1);
                else
                    toDelete(end+1,1) = i;
                end
            end
            
            % delete the times that are too old
            this.collisionPerceivedAt(toDelete,:) = [];
        end

        function recordCollisionTime(this, localTimeAtCollision)
            this.collisionPerceivedAt(end+1, 1) = localTimeAtCollision;
        end

        function clear = clearToSend(this, currentSlot)
            % check if slot is free, own or pending, i. e. clear to send
            % if slot is colliding, it is also okay to send (colliding slot
            % are treated as free when it comes to availability for
            % reservation)
            
            clear = this.slotIsFree(currentSlot) | ...
                this.slotIsColliding(currentSlot) | ...
                this.isPendingSlot(currentSlot) | this.isOwnSlot(currentSlot) | ...
                currentSlot == 0;
        end

        function isFree = slotIsFree(this, currentSlot)
            freeSlots = this.findFreeSlotsInThreeHopNeighborhood();
            isFree = ~isempty(find(freeSlots == currentSlot, 1));
        end

        function isColliding = slotIsColliding(this, currentSlot)
            collidingSlots = this.findCollidingSlotsInThreeHopNeighborhood();
            isColliding = ~isempty(find(collidingSlots == currentSlot, 1));
        end

        function ownSlots = getOwnSlots(this)
            ownSlots = this.ownSlots;
        end
        
        function pendingSlots = getPendingSlots(this)
            pendingSlots = this.pendingSlots;
        end

        function result = hasOwnOrPendingSlots(this)
            result = (size(this.ownSlots, 2) + size(this.pendingSlots, 2)) > 0;
        end

        function nextOwnOrPendingSlot = getNextOwnOrPendingSlot(this, currentSlot)
            selection = unique([this.ownSlots, this.pendingSlots]);
            nextOwnOrPendingSlot = this.getNextSlotFromSelection(selection, currentSlot);
        end
        
        function lastNewReservationTime = getLastNewReservationTime(this)
            lastNewReservationTime = this.lastNewReservationTime;
        end

%         function nextOwnSlot = getNextOwnSlot(this, currentSlot)
%             nextOwnSlot = this.getNextSlotFromSelection(this.ownSlots, currentSlot);
%         end
%        
%         function nextPendingSlot = getNextPendingSlot(this, currentSlot)
%             nextPendingSlot = this.getNextSlotFromSelection(this.pendingSlots, currentSlot);
%         end

        function exists = ownNetworkExists(this, collidingSlots)
            % find out if own network was succerssfully created in the
            % first place (if the initital ping collided, the network was
            % not created)
            exists = true;

            % first create artificial message
            msg.oneHopSlotsStatus = zeros(1, this.config.slotsPerFrame);
            msg.oneHopSlotsIds = zeros(1, this.config.slotsPerFrame);
            msg.twoHopSlotsStatus = zeros(1, this.config.slotsPerFrame);
            msg.twoHopSlotsIds = zeros(1, this.config.slotsPerFrame);

            for i = 1:size(collidingSlots, 2)
                msg.twoHopSlotsStatus(1, i) = SlotOccupancyStates.COLLIDING;
            end

            % then check if own slots collide
            collidingOwnSlots = this.checkOwnSlotsForCollisions(msg);
            collidingPendingSlots = this.checkPendingSlotsForCollisions(msg);

            if ~isempty(collidingOwnSlots) | ~isempty(collidingPendingSlots)
                % if own slot was reported colliding and no slots are
                % occupied, the own network was never created
                if nnz(this.oneHopSlotMap.status == SlotOccupancyStates.OCCUPIED) == 0
                    exists = false;
                end
            end
        end
        
        function extendTimeouts(this)
            % to prevent slots from timing out while sleeping, extend the
            % timeout for all slotmaps by the time that the nodes idled
            % (the maximum possible idle time, cause the node does not know
            % how long other nodes idled exactly)
            
            extensionTime = (this.config.slotLength * this.config.slotsPerFrame)*this.config.autoDutyCycle;
            
            this.oneHopSlotMap.lastUpdated(this.oneHopSlotMap.status ~= 0) = this.oneHopSlotMap.lastUpdated(this.oneHopSlotMap.status ~= 0) + extensionTime;
            this.twoHopSlotMap.lastUpdated(this.twoHopSlotMap.status ~= 0) = this.twoHopSlotMap.lastUpdated(this.twoHopSlotMap.status ~= 0) + extensionTime;
            this.threeHopSlotMap.lastUpdated(this.threeHopSlotMap.status ~= 0) = this.threeHopSlotMap.lastUpdated(this.threeHopSlotMap.status ~= 0) + extensionTime;
        end

        function setId(this, id)
            this.id = id;
        end
    
    end


    methods (Access = private)
        function expired = oneHopSlotIsExpired(this, currentSlot, localTime, timeout)
            expired = this.isExpired(this.oneHopSlotMap.lastUpdated(1, currentSlot), localTime, timeout);
        end

        function expired = multiHopSlotIsExpired(this, slot, localTime, timeout, slotMap)
            expired = this.isExpired(slotMap.lastUpdated(1, slot), localTime, timeout);
        end

        function expired = isExpired(this, lastUpdateTime, localTime, timeout)
            if localTime >= lastUpdateTime + timeout
                expired = true;
            else
                expired = false;
            end
        end

        function wasAcknowledged = slotWasAcknowledged(this, slot)
            if ~isempty(this.neighborsWhenPendingAdded{slot, 1})
                neighborsThatNeedToAck = cell2mat(this.neighborsWhenPendingAdded(slot, 1));
                acksFromCorrectNeighbors = fastIntersect(this.pendingSlotsAcknowledgedBy(slot, :), neighborsThatNeedToAck);
                numCorrectAcks = size(acksFromCorrectNeighbors, 2);
                if numCorrectAcks >= size(neighborsThatNeedToAck, 2)
                    wasAcknowledged = true;
                else
                    wasAcknowledged = false;
                end
            else
                wasAcknowledged = true;
            end
        end

        function slotMap = updateMultiHopSlotMap(this, msg, localTime, slotMap)
            for slot = 1:size(slotMap.status, 2)
                currentStatus = slotMap.status(1, slot);
                newStatus = msg.multiHopSlotsStatus(1, slot);
                currentId = slotMap.ids(1, slot);
                newId = msg.multiHopSlotsIds(1, slot);

                switch newStatus
                    case SlotOccupancyStates.OCCUPIED
                        switch currentStatus
                            case SlotOccupancyStates.FREE
                                slotMap.status(1, slot) = newStatus;
                                slotMap.ids(1, slot) = msg.multiHopSlotsIds(1, slot);
                                slotMap.lastUpdated(1, slot) = localTime;
                            case SlotOccupancyStates.OCCUPIED
                                if newId == currentId
                                    slotMap.lastUpdated(1, slot) = localTime;
                                else
                                    timeout = this.config.occupiedSlotTimeout;
                                    if this.multiHopSlotIsExpired(slot, localTime, timeout, slotMap)
                                        slotMap.status(1, slot) = newStatus;
                                        slotMap.ids(1, slot) = msg.multiHopSlotsIds(1, slot);
                                        slotMap.lastUpdated(1, slot) = localTime;
                                    else
                                        slotMap.status(1, slot) = SlotOccupancyStates.COLLIDING;
                                        slotMap.ids(1, slot) = 0;
                                        slotMap.lastUpdated(1, slot) = localTime;
                                    end
                                end
                            case SlotOccupancyStates.COLLIDING
                                timeout = this.config.collidingSlotTimeoutMultiHop;
                                if this.multiHopSlotIsExpired(slot, localTime, timeout, slotMap)
                                    slotMap.status(1, slot) = newStatus;
                                    slotMap.ids(1, slot) = msg.multiHopSlotsIds(1, slot);
                                    slotMap.lastUpdated(1, slot) = localTime;
                                end
                        end
                        
                        % if slot is own or pending slot but reported
                        % occupied by another node, set it to colliding to
                        % prevent deadlocks and instead make it reservable 
                        if ~isempty(fastIntersect(this.ownSlots, slot)) | ~isempty(fastIntersect(this.pendingSlots, slot))
                            if ~isequal(newId, this.id)
                                slotMap.status(1, slot) = SlotOccupancyStates.COLLIDING;
                                slotMap.ids(1, slot) = 0;
                                slotMap.lastUpdated(1, slot) = localTime;
                            end
                        end

                    case SlotOccupancyStates.COLLIDING
                        slotMap.status(1, slot) = newStatus;
                        slotMap.ids(1, slot) = 0;
                        slotMap.lastUpdated(1, slot) = localTime;
                    case SlotOccupancyStates.FREE
                        timeout = this.config.occupiedSlotTimeoutMultiHop;
                        if this.multiHopSlotIsExpired(slot, localTime, timeout, slotMap)
                            slotMap.status(1, slot) = newStatus;
                            slotMap.ids(1, slot) = 0;
                        end
                end
            end
        end

        function collidingSlots = checkSlotsForCollisions(this, msg, slotsToCheck)
            collidingSlots = [];
            
            for i = 1:size(slotsToCheck, 2)
                slotNum = slotsToCheck(1, i);
                if this.slotReportedColliding(msg, slotNum) || this.slotReportedOccupiedByOtherNode(msg, slotNum)
                    collidingSlots(1, end + 1) = slotNum;
                end
            end
        end

        function result = slotReportedColliding(this, msg, slotNum)
            if msg.oneHopSlotsStatus(1, slotNum) == SlotOccupancyStates.COLLIDING ...
                || msg.twoHopSlotsStatus(1, slotNum) == SlotOccupancyStates.COLLIDING
                result = true;
            else
                result = false;
            end
        end

        function result = slotReportedOccupiedByOtherNode(this, msg, slotNum)
            if msg.oneHopSlotsStatus(1, slotNum) == SlotOccupancyStates.OCCUPIED & ~isequal(msg.oneHopSlotsIds(1, slotNum), this.id) ...
                || msg.twoHopSlotsStatus(1, slotNum) == SlotOccupancyStates.OCCUPIED & ~isequal(msg.twoHopSlotsIds(1, slotNum), this.id)
                result = true;
            else
                result = false;
            end
        end

        function allSlots = releaseSlots(this, allSlots, slotsToRelease)
            if ~isempty(allSlots)
                idx = allSlots(1,:) == slotsToRelease;
                allSlots(:, idx) = [];
            end
        end

        function removeOwnAndPendingSlotsFromSlotMaps(this, slotsToRelease)
            % remove own slots from slot maps
            twoHopSlotIdx = find(this.twoHopSlotMap.ids == this.id);
            for i = 1:size(twoHopSlotIdx, 2)
                if (ismember(twoHopSlotIdx(1, i), slotsToRelease))
                    this.twoHopSlotMap.status(:, twoHopSlotIdx(1,i)) = 0;
                    this.twoHopSlotMap.ids(:, twoHopSlotIdx(1,i)) = 0;
                end
            end

            threeHopSlotIdx = find(this.threeHopSlotMap.ids == this.id);
            for i = 1:size(threeHopSlotIdx, 2)
                if (ismember(threeHopSlotIdx(1, i), slotsToRelease))
                    this.threeHopSlotMap.status(:, threeHopSlotIdx(1,i)) = 0;
                    this.threeHopSlotMap.ids(:, threeHopSlotIdx(1,i)) = 0;
                end
            end
        end

        function freeSlots = findFreeSlotsInThreeHopNeighborhood(this)
            slotNums = 1:this.config.slotsPerFrame;

            oneHopFree = slotNums(this.oneHopSlotMap.status == SlotOccupancyStates.FREE);
            twoHopFree = slotNums(this.twoHopSlotMap.status == SlotOccupancyStates.FREE);
            threeHopFree = slotNums(this.threeHopSlotMap.status == SlotOccupancyStates.FREE);

            % slots are only free if they are one hop, two hop and
            % three hop free, so get the intersections of all
            oneAndTwoHopIntersection = fastIntersect(oneHopFree, twoHopFree);
            freeSlots = fastIntersect(oneAndTwoHopIntersection, threeHopFree);
        end

        function collidingSlots = findCollidingSlotsInThreeHopNeighborhood(this)
            slotNums = 1:this.config.slotsPerFrame;

            oneHopColliding = slotNums(this.oneHopSlotMap.status == SlotOccupancyStates.COLLIDING);
            twoHopColliding = slotNums(this.twoHopSlotMap.status == SlotOccupancyStates.COLLIDING);
            threeHopColliding = slotNums(this.threeHopSlotMap.status == SlotOccupancyStates.COLLIDING);

            % slots are colliding if they are colliding in one of the
            % slot maps, so get the union of all
            collidingSlots = unique([oneHopColliding, twoHopColliding, threeHopColliding]);

            % slots are not reservable if they are occupied in any slot map
            oneHopOccupied = slotNums(this.oneHopSlotMap.status == SlotOccupancyStates.OCCUPIED);
            twoHopOccupied = slotNums(this.twoHopSlotMap.status == SlotOccupancyStates.OCCUPIED);
            threeHopOccupied = slotNums(this.threeHopSlotMap.status == SlotOccupancyStates.OCCUPIED);

            occupiedSlots = unique([oneHopOccupied, twoHopOccupied, threeHopOccupied]);
            
            % return slots that are colliding but not occupied in any map
            collidingSlots = setdiff(collidingSlots, occupiedSlots);

            % comment: for-loop might be faster than setdiff, but in this
            % case the simpler code was preferred; might be changed if
            % performance problems come up
        end

        function nextSlot = getNextSlotFromSelection(this, selection, currentSlot)
            nextSlot = [];
            
            if ~isempty(selection)
                slotDists = selection - currentSlot;
                for i = 1:size(slotDists, 2)
                    if slotDists(1, i) <= 0
                        slotDists(1, i) = slotDists(1, i) + this.config.slotsPerFrame;
                    end
                end
                [~, ind] = min(slotDists);
                nextSlot = selection(1, ind);
            end
        end
    end

end

function intersection = fastIntersect(firstMat, secondMat)
    intersection = firstMat(ismember(firstMat, secondMat));
end