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

classdef Neighborhood < handle
    
    properties %(Access = private)
       oneHopNeighbors;
       oneHopNeighborsLastSeen;
       oneHopNeighborsLastRanging;
       oneHopNeighborsJoinedTime;
    end

    methods

        function this = Neighborhood()
            this.oneHopNeighbors = [];
            this.oneHopNeighborsLastSeen = [];
            this.oneHopNeighborsLastRanging = [];
        end

        function addOrUpdateOneHopNeighbor(this, id, time)
            idx = find(this.oneHopNeighbors == id, 1);                
            if isempty(idx) 
                this.oneHopNeighbors(end + 1, 1) = id;
                this.oneHopNeighborsLastSeen(end + 1, 1) = time;
                this.oneHopNeighborsLastRanging(end + 1, 1) = 0;
                this.oneHopNeighborsJoinedTime(end + 1, 1) = time;
            else 
                this.oneHopNeighborsLastSeen(idx, 1) = time;
            end
        end

       function removeAbsentNeighbors(this, timeout, localTime)
           absentLogical = (this.oneHopNeighborsLastSeen + timeout) < localTime;
           absentIdx = find(absentLogical);
           this.oneHopNeighbors(absentIdx, :) = [];
           this.oneHopNeighborsLastSeen(absentIdx, :) = [];
           this.oneHopNeighborsLastRanging(absentIdx, :) = [];
           this.oneHopNeighborsJoinedTime(absentIdx, :) = [];
       end
       
       function updateRanging(this, id, time)
           idx = find(this.oneHopNeighbors == id, 1);                
           this.oneHopNeighborsLastRanging(idx, 1) = time;
       end

       function neighborId = getNextRangingNeighbor(this)
           % return the neighbor that has not been ranged for the longest
           % time
           [~, idx] = min(this.oneHopNeighborsLastRanging);
%            idx = find(this.oneHopNeighborsLastRanging == minTimeLastUpdate);
           
           if size(idx, 1) > 1
               idx = idx(1,1);               
           end
           
           if ~isempty(idx)
               neighborId = this.oneHopNeighbors(idx, 1);
           else
               neighborId = [];
           end
       end

       function oneHopNeighbors = getOneHopNeighbors(this)
            oneHopNeighbors = this.oneHopNeighbors;
       end
       
       function newestNeighbor = getNewestNeighbor(this)
           [~, idxNewestNeighbor] = max(this.oneHopNeighborsJoinedTime);
           newestNeighbor = this.oneHopNeighbors(idxNewestNeighbor, 1);
       end
       
       function newestJoinedTime = getTimeWhenNewestNeighborJoined(this)
           newestJoinedTime = max(this.oneHopNeighborsJoinedTime);
       end
       
    end

end