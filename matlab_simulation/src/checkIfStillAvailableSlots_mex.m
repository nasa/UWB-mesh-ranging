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

function slotsAvailable = checkIfStillAvailableSlots(nodes, reservedSlots, channel, config)

% check if any node can still reserve slots without causing collisions

    freeSlotsPerNode = [];
    for i = 1:size(nodes, 1)
        reservedSlotsInContentionArea = [];
        % find all nodes in range
        for j = 1:size(nodes, 1)
            if channel.isInRange(nodes{i,2}, nodes{j,2})
                reservedSlotsInContentionArea = [reservedSlotsInContentionArea, reservedSlots{j,1}];
                
                % again find all nodes in range of this node
                for k = 1:size(nodes, 1)
                    if channel.isInRange(nodes{j,2}, nodes{k,2})
                        reservedSlotsInContentionArea = [reservedSlotsInContentionArea, reservedSlots{k,1}];
                    end
                end
            end
        end
        
        allSlots = linspace(1, config.frameLength/config.slotLength, config.frameLength/config.slotLength);
        freeSlots = setdiff(allSlots, reservedSlotsInContentionArea);
        freeSlotsPerNode{end+1, 1} = size(freeSlots, 2);
    end
    
    slotsAvailable = cell2mat(freeSlotsPerNode);
end