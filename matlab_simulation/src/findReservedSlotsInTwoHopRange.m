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

function reservedSlots = findReservedSlotsInTwoHopRange(activeNodes)
    reservedSlots = cell(size(activeNodes, 1), 1);

    nodesInOneHopRangeIndices = findNodesInRange(activeNodes);
    nodesInTwoHopRangeIndices = nodesInOneHopRangeIndices;

    for i = 1:size(activeNodes, 1)
        if isempty(nodesInOneHopRangeIndices{i,1})
            continue;
        end
        % get all nodes in two-hop range
        for k = 1:size(nodesInOneHopRangeIndices{i, 1}, 2)
            neighborIdx = nodesInOneHopRangeIndices{i, 1}(1, k);
            nodesInTwoHopRangeIndices{i, 1} = [nodesInTwoHopRangeIndices{i, 1}, nodesInOneHopRangeIndices{neighborIdx, 1}];
        end

        nodesInTwoHopRangeIndices{i, 1} = unique(nodesInTwoHopRangeIndices{i, 1});
        
        % remove one-hop neighbors and node itself from two-hop neighbors
        nodesInTwoHopRangeIndices{i, 1} = setdiff(nodesInTwoHopRangeIndices{i, 1}, [nodesInOneHopRangeIndices{i, 1}, i]);

        for j = 1:size(activeNodes, 1)
            if  ~isempty(find(nodesInTwoHopRangeIndices{i, 1} == j, 1))
                if i == j
                    % if own slot collides with another, that does not
                    % necessarily lead to collisions at other nodes, so
                    % don't count it as a collision
                    continue;
                end
                reservedSlots{i, 1} = [reservedSlots{i, 1}, activeNodes{j,1}.slotMap.ownSlots];
            end
        end
    end
end