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

function sameNetwork = everyNeighborIsInTheSameNetwork_mex(activeNodes, nodesInRangeIndices, config, pWrapper)
    sameNetwork = [];

    for i = 1:size(activeNodes, 1)
        netAges = [MatlabWrapper(15, pWrapper, activeNodes{i,1})];
        netIds = [MatlabWrapper(16, pWrapper, activeNodes{i,1})];
        timesSinceFrameStart = [MatlabWrapper(17, pWrapper, activeNodes{i,1})];
        
        for rangeIdx = 1:size(nodesInRangeIndices{i, 1}, 2)
            currentNode = activeNodes{nodesInRangeIndices{i, 1}(1, rangeIdx)};
    
            netId = MatlabWrapper(16, pWrapper, currentNode);
            netAge = MatlabWrapper(15, pWrapper, currentNode);
            timeSinceFrameStart = [MatlabWrapper(17, pWrapper, currentNode)];
            
            if ~isempty(netId) & ~isempty(netAge)
                netIds(1, end + 1) = netId;
                netAges(1, end + 1) = netAge;
                timesSinceFrameStart(1, end + 1) = timeSinceFrameStart;
            else
                netIds(1, end + 1) = NaN;
                netAges(1, end + 1) = NaN;
                timesSinceFrameStart(1, end + 1) = NaN;
            end
        end
        
        errorMargin = 49; % slight errors can be introduced by ToF (should be extremely low) and clock skew; 
                          % must be lower than guard period to ensure nodes
                          % in the same network are always in the same slot
                          % before a message is sent
        sameAge = false;
        sameId = false;
        sameFrameStart = false;
        
        if ~isempty(netAges) & isempty(find(isnan(netAges), 1))
            sameAge = (max(netAges) - min(netAges)) <= errorMargin;
        end
        if ~isempty(netIds) & isempty(find(isnan(netIds), 1))
            sameId = nnz(netIds(1, :) == netIds(1,1)) == size(netIds, 2);
        end
        if ~isempty(timesSinceFrameStart) & isempty(find(isnan(timesSinceFrameStart), 1))
            maxValue = max(timesSinceFrameStart);
            minValue = min(timesSinceFrameStart);
            sameFrameStart = ((maxValue - minValue) <= errorMargin) ...
             | (abs(maxValue - (minValue + config.frameLength)) <= errorMargin); % if a node is already in the next frame
        end
        
        sameNetwork(end+1, 1) = sameAge & sameId & sameFrameStart;
    end
end