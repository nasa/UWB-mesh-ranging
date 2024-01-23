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

classdef NodeConfig < handle

    %% Config:
    % []: for leaving and movement: no leaving or movement;
    % {a b}: random integer between a and b is chosen for this value;
    % other values: do as specified
    
    properties
        x;
        y;
        enterTime;
        leaveTime;
        movementTimes;
        movementsX;
        movementsY;
        
        movementTimesPersistent;
        
        
        % if specified, the following properties are used to generate a
        % random trajectory for the node at runtime
        trajectoryStartTime;
        velocity;
        xlimits;
        ylimits;
        travelDistance;
        maxSteering;
        samplePoints;
    end

    methods
        
        function this = NodeConfig()
            this.x = {-100, 100}; 
            this.y = {-100, 100};
            this.enterTime = 0;
            this.leaveTime = 0;
            this.movementTimes = [];
            this.movementsX = [];
            this.movementsY = [];
            
            this.trajectoryStartTime = [];
            this.velocity = 0;
            this.xlimits = [-150 150];
            this.ylimits = [-150 150];
            this.travelDistance = [];
            this.maxSteering = [];
            this.samplePoints = [];
        end
        
%         function this = NodeConfig(x, y, enterTime, leaveTime, movementTimes, movementsX, movementsY)
%             this.x = x;
%             this.y = y;
%             this.enterTime = enterTime;
%             this.leaveTime = leaveTime;
%             this.movementTimes = movementTimes;
%             this.movementsX = movementsX;
%             this.movementsY = movementsY;
%         end
        
    end


end