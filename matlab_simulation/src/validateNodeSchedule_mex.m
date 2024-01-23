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

function results = validateNodeSchedule_mex(nodes, nodeConfigs, channel, config, simConfig, validationData, pWrapper, verbose)
    %% check if any node can still reserve slots without causing collisions
    % check if all nodes have reserved the specified number of slots (or if
    % all slots are occupied)
    
    % get the reserved slots of every node
    reservedSlots = cell(size(nodes, 1), 1);
    for i = 1:size(nodes, 1)
        nodeId = nodes{i, 1};
        ownSlots = MatlabWrapper(13, pWrapper, nodeId);

        % remove zeros from the slots
        zerosLogical = (ownSlots ~= 0);
        reservedSlots{i, 1} = ownSlots(zerosLogical);
    end

    numSlotsAvailable = checkIfStillAvailableSlots_mex(nodes, reservedSlots, channel, config);
    reservedEnoughSlots = [];
    results.info = "";
    results.passed = true; 

    for i = 1:size(nodes, 1)
        reservedEnoughSlots(end+1, 1) = (size(reservedSlots{i, 1}, 2) == config.slotGoal);
    end

    targetMet = ((numSlotsAvailable == 0) | reservedEnoughSlots);    
    isIsolated = findIsolatedNodes_mex(nodes, channel);

    results.numIsolatedNodes = nnz(isIsolated); 

    if (isempty(find(reservedEnoughSlots ~= 1, 2)))
        if verbose
            disp("Every node reserved the specified number of slots.");
        end
    elseif (nnz(targetMet) == size(targetMet, 1))
        statusMsg = "Slot capacity was not sufficient for all nodes.";
        if verbose
            disp(statusMsg);
        end
        results.info = strcat(results.info, statusMsg);
    else
        goalNotMetInd = find(reservedEnoughSlots ~= 1, 2);
        idNotMet = [];
        for i = 1:size(goalNotMetInd, 1)
            idNotMet = nodes{goalNotMetInd(i), 1};
            if isIsolated(goalNotMetInd(i), 1)
                statusMsg = ["Node " + string(idNotMet) + " is isolated."];
                if verbose
                    disp(statusMsg);
                end
                results.info = strcat(results.info, statusMsg);
            else
                statusMsg = ["Node " + string(idNotMet) + " did not reserve the specified number of slots."];
                if verbose
                    disp(statusMsg);
                end
                results.info = strcat(results.info, statusMsg);
                results.passed = false;
            end
        end
    end

    %% check if there are colliding slots and if all nodes in range are in the same network
    nodesInRangeIndicesAllNodes = findNodesInRange_mex(nodes, channel);
    reservedSlotsAllNodesOneHop = findReservedSlotsOfNodesInRange_mex(nodes, nodesInRangeIndicesAllNodes, reservedSlots);
    reservedSlotsAllNodesTwoHop = findReservedSlotsInTwoHopRange_mex(nodes, reservedSlots, channel);
    sameNetworkAllNodes = everyNeighborIsInTheSameNetwork_mex(nodes, nodesInRangeIndicesAllNodes, config, pWrapper);

    for i = 1:size(nodes, 1)
        sameNetwork = sameNetworkAllNodes(i, 1);
        if isIsolated(i, 1)
            sameNetwork = true;
        end

        reservedSlotsOneHop = reservedSlotsAllNodesOneHop{i, 1};
        reservedSlotsTwoHop = reservedSlotsAllNodesTwoHop{i, 1};

        [uniqueSlotsOneHop, indOneHop] = unique(reservedSlotsOneHop);
        allOneHopSlotsAreUnique = (size(uniqueSlotsOneHop, 2) == size(reservedSlotsOneHop, 2));
        noReservedSlotsOneHop = (isempty(uniqueSlotsOneHop) & isempty(reservedSlotsOneHop));

        noCollisionsBetweenOneAndTwoHop = isempty(intersect(reservedSlotsOneHop, reservedSlotsTwoHop));

        if (allOneHopSlotsAreUnique | noReservedSlotsOneHop) & noCollisionsBetweenOneAndTwoHop & sameNetwork 
            if verbose
                disp("No colliding slots for node " + num2str(nodes{i,1}));
            end
        elseif ~(allOneHopSlotsAreUnique | noReservedSlotsOneHop) | ~noCollisionsBetweenOneAndTwoHop
%            duplicatesInd = find(not(ismember(1:numel(reservedSlotsOneHop),indOneHop)));            
%            duplicateSlotNums = reservedSlotsTwoHop(duplicatesInd);
%            statusMsg = ["Slot(s) " + string(duplicateSlotNums) + " are colliding for node " + num2str(nodes{i,1}.id) + "."];
           statusMsg = ["Slot(s) are colliding for node " + num2str(nodes{i,1}) + "."];
           if verbose
               disp(statusMsg);
           end
           results.passed = false;
           results.info = strcat(results.info, statusMsg);
        elseif (allOneHopSlotsAreUnique | noReservedSlotsOneHop) & noCollisionsBetweenOneAndTwoHop & ~sameNetwork
            statusMsg = ["Node " + num2str(nodes{i,1}) + " is not in the same network as all its neighbors."];
            if verbose
                disp(statusMsg);
            end
            results.passed = false;
            results.info = strcat(results.info, statusMsg);
        else
            statusMsg = ["Unexpected results."];
            if verbose
                disp(statusMsg);
            end
            results.passed = false;
            results.info = strcat(results.info, statusMsg);
        end
    end

    %% check if every node skipped a ping (only CADRE)
    if (simConfig.CADRE)
        % if the CADRE code is simulated, we also check if every node
        % sent a ping in each of its slots
        
        % in CADRE code, first slot always starts at zero for all nodes (as
        % they are synchronized)
        numSlotsSimulated = floor(validationData.globalTime)/config.slotLength;
        
        nodeSentAllPings = ones(4, 1);
        for i=1:numSlotsSimulated
            slotStart = config.slotLength * (i-1) + 1;
            slotEnd = config.slotLength * i;
            timeSinceFirstFrameStart = slotStart - 1;
            timeInFrame = mod(timeSinceFirstFrameStart, config.frameLength);
            slotNum = ceil(mod(slotStart, config.frameLength)/config.slotLength);
            
            % slotNum is also the nodeId in the CADRE case
            timeIdx = find(validationData.pingsSent{slotNum, 1} >= slotStart & validationData.pingsSent{slotNum, 1} <= slotEnd);
            if isempty(timeIdx)
                nodeSlept = false;
                for j=slotStart:slotEnd
                    if (validationData.states{slotNum, 1}(1, j) == 11)
                        nodeSlept = true;
                    end
                end
                if ~nodeSlept
                    % node did not send in its slot even though it was not
                    % sleeping
                    results.passed = false;
                    statusMsg = ["Node " + num2str(slotNum) + " skipped ping. "];
                    results.info = strcat(results.info, statusMsg);
                end
            end
        end
    end
    
    if strcmp(results.info, "")
        results.info = "-";
    end

    % find the number of connected groups
    % first, add the node itself to its neighbors
    for i = 1:size(nodesInRangeIndicesAllNodes, 1)
        nodesInRangeIndicesAllNodes{i, 1} = [nodesInRangeIndicesAllNodes{i, 1}, i];
    end

    groups = findNodeGroups(nodesInRangeIndicesAllNodes);

    results.nodegroups = size(groups, 1);
    results.nodes = nodes;
    
end