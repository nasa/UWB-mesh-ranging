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

function sameNetwork = everyNeighborIsInTheSameNetwork(activeNodes, nodesInRangeIndices)
    sameNetwork = [];

    for i = 1:size(activeNodes, 1)        
        timeOfNode = activeNodes{i,1}.clock.getLocalTime();
        netAges = [activeNodes{i,1}.networkManager.calculateNetworkAge(timeOfNode)];
        netIds = [activeNodes{i,1}.networkManager.getNetworkId()];
        timesSinceFrameStart = [activeNodes{i,1}.timeKeeping.calculateTimeSinceFrameStart()];
        
        for rangeIdx = 1:size(nodesInRangeIndices{i, 1}, 2)
            currentNode = activeNodes{nodesInRangeIndices{i, 1}(1, rangeIdx)};
    
            timeOfNode = currentNode.clock.getLocalTime();
            netId = currentNode.networkManager.getNetworkId();
            netAge = currentNode.networkManager.calculateNetworkAge(timeOfNode);
            if ~isempty(netId) & ~isempty(netAge)
                netIds(1, end + 1) = netId;
                netAges(1, end + 1) = netAge;
                timesSinceFrameStart(1, end + 1) = currentNode.timeKeeping.calculateTimeSinceFrameStart();
            else
                netIds(1, end + 1) = NaN;
                netAges(1, end + 1) = NaN;
                timesSinceFrameStart(1, end + 1) = NaN;
            end
        end
        
        allowedError = (2 * activeNodes{i,1}.config.tofErrorMargin);
        sameAge = false;
        sameId = false;
        sameFrameStart = false;
        
        if ~isempty(netAges) & isempty(find(isnan(netAges)))
            sameAge = (max(netAges) - min(netAges)) <= allowedError;
        end
        if ~isempty(netIds) & isempty(find(isnan(netIds)))
            sameId = nnz(netIds(1, :) == netIds(1,1)) == size(netIds, 2);
        end
        if ~isempty(timesSinceFrameStart) & isempty(find(isnan(timesSinceFrameStart)))
            sameFrameStart = (max(timesSinceFrameStart) - min(timesSinceFrameStart)) <= allowedError;
        end
        
        sameNetwork(end+1, 1) = sameAge & sameId & sameFrameStart;
    end
end