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

function stopSim = checkStopCriteria_mex(globalTime, activeNodes, nodes, nodeConfigs, channel, config, pWrapper, manipulationTimes)    
    % sim can be stopped if
    % - all nodes reserved the target number of slots without collisions
    % - no node can reserve another slot without causing a collision
    % - no further movement or other actions are scheduled

    
    %% check if any movement is still scheduled
    noMovements = [];
    lastMovement = 0;
    for i = 1:size(activeNodes, 1)
        movementTimes = nodeConfigs{i, 1}.movementTimesPersistent;
        if ~isempty(movementTimes)
            noMovements(end+1, 1) = globalTime > movementTimes(1, end);

            if max(movementTimes(1, :)) > lastMovement
                lastMovement = max(movementTimes(1, :));
            end
        end
    end
    
    noMovements = (nnz(noMovements) == size(noMovements, 1));
    
    noManipulationsScheduled = true;
    lastManipulation = 0;
    
    %% check if timeout
    % timeout is thirty frames after last topology change
    lastEnter = 0;
    for i = 1:size(nodes, 1)
        if nodeConfigs{i, 1}.enterTime > lastEnter
            lastEnter = nodeConfigs{i, 1}.enterTime;
        end
    end
    numTicsTimeout = ((30+config.sleepFrames) * config.frameLength); 
    timeout = max([lastManipulation, lastMovement, lastEnter]) + numTicsTimeout;

    numTicsMinWait = ((2 + config.sleepFrames) * config.frameLength); % wait at least this num of frames before finishing
    minWaitTime = max([lastManipulation, lastMovement, lastEnter]) + numTicsMinWait;

    isTimeout = globalTime > timeout;
    minWaitTimeOver = globalTime > minWaitTime;
    
    %% check if all nodes entered
    noNodesLeftToEnter = globalTime > lastEnter;
        
    %% check if node reserved the target number of slots or if it cannot reserve any slots
    % get the reserved slots of every active node
    reservedSlots = cell(size(activeNodes, 1), 1);
    for i = 1:size(activeNodes, 1)
        nodeId = activeNodes{i, 1};
        ownSlots = MatlabWrapper(13, pWrapper, nodeId);
        
        % remove zeros from the slots
        zerosLogical = (ownSlots ~= 0);
        reservedSlots{i, 1} = ownSlots(zerosLogical);
    end
    
    numSlotsAvailable = checkIfStillAvailableSlots_mex(activeNodes, reservedSlots, channel, config);
    reservedEnoughSlots = [];
    
    nodesInRangeIndicesAllNodes = findNodesInRange_mex(activeNodes, channel);
    reservedSlotsAllNodesOneHop = findReservedSlotsOfNodesInRange_mex(activeNodes, nodesInRangeIndicesAllNodes, reservedSlots);
    reservedSlotsAllNodesTwoHop = findReservedSlotsInTwoHopRange_mex(activeNodes, reservedSlots, channel);

    for i = 1:size(activeNodes, 1)
        reservedEnoughSlots(end+1, 1) = (size(reservedSlots{i, 1}, 2) == config.slotGoal);
    end
    
    %% check if node is isolated (then it cannot reach any other node)
    isIsolated = findIsolatedNodes_mex(activeNodes, channel);

    % target is met if node reserved enough slots, cannot reserve or is
    % isolated
    targetMet = ((numSlotsAvailable == 0) | reservedEnoughSlots | isIsolated);
    targetMet = (nnz(targetMet) == size(targetMet, 1));

    %% check for colliding slots

%     nodesInRangeIndices = findNodesInRange(activeNodes);
%     reservedSlots = findReservedSlotsInTwoHopRange(activeNodes); %findReservedSlotsInThreeHopRange(activeNodes);
    noCollisionsAllNodes = zeros(size(activeNodes, 1), 1);
    for i = 1:size(activeNodes, 1)
        reservedSlotsOneHop = reservedSlotsAllNodesOneHop{i, 1};
        reservedSlotsTwoHop = reservedSlotsAllNodesTwoHop{i, 1};
    
        [uniqueSlotsOneHop, indOneHop] = unique(reservedSlotsOneHop);
        allOneHopSlotsAreUnique = (size(uniqueSlotsOneHop, 2) == size(reservedSlotsOneHop, 2));
        noReservedSlotsOneHop = (isempty(uniqueSlotsOneHop) & isempty(reservedSlotsOneHop));
    
        noCollisionsBetweenOneAndTwoHop = isempty(intersect(reservedSlotsOneHop, reservedSlotsTwoHop));

        if (allOneHopSlotsAreUnique | noReservedSlotsOneHop) & noCollisionsBetweenOneAndTwoHop
            noCollisionsAllNodes(i, 1) = 1;
        end
    end

    noCollisions = nnz(noCollisionsAllNodes) == size(noCollisionsAllNodes, 1);

    %% check if all nodes are in the same network as all their neighbors
    sameNetwork = everyNeighborIsInTheSameNetwork_mex(activeNodes, nodesInRangeIndicesAllNodes, config, pWrapper);

    % all nodes in range must be in the same network, except a node is
    % isolated
    sameNetwork = sameNetwork | isIsolated;
    sameNetwork = (nnz(sameNetwork) == size(sameNetwork, 1));
    
    %% set minimum run time
    minRunTime = 0;
    if (config.sleepFrames >= 1)
        minRunTime = 3 * config.frameLength * (config.sleepFrames + 1);
    end

    %% signal to stop the sim
    stopSim = noMovements & noManipulationsScheduled & noNodesLeftToEnter & ((noCollisions & targetMet & sameNetwork) | isTimeout) & minWaitTimeOver & (globalTime > minRunTime);

%     if (globalTime > 36000000)
%         stopSim = true;
%     else
%         stopSim = false;
%     end
end