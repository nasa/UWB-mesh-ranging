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

function [times, movementX, movementY] = generateTrajectory(xStart, yStart, startTime, velocity, xlimits, ylimits, distance, maxSteeringAngle, samplePoints, ticsPerMillisecond)
    
    % startTime: time when the movement should start
    % velocity: in m/s
    % xlimits: don't move outside of these limits (x-direction)
    % ylimits: don't move outside of these limits (y-direction)
    % distance: length of the way the node should move
    % samplePoints: number of "waypoints" (more = smoother movement, less =
    % moves in jumps);  more can increase the simulation time and GIF size
    % drastically!
    % maxSteeringAngle: maximum angle the node can "steer" from its
    % previous direction (to generate a smooth trajectory) 
    
    duration = (distance/velocity) * ticsPerMillisecond * 1000; % duration must be defined in tics
    stepSize = 100; %round((duration)/samplePoints);
    trajectoryResolution = 1000; 
    startTime = round(startTime/stepSize) * stepSize;
    endTime = startTime + duration;
    timeVector = (startTime:stepSize:endTime);
    movementX = zeros(1, size(timeVector, 2));
    movementY = zeros(1, size(timeVector, 2));
    positionsX = zeros(1, size(timeVector, 2));
    positionsY = zeros(1, size(timeVector, 2));
    % generate a movement for every sample point; length of the movement is
    % always the same (steady movement), direction of first movement is
    % random, afterwards the deviation from the previous direction is
    % limited ("limited steering angle")
    
    distancePerStep = distance/trajectoryResolution;
    
    % boundaries for the random angle (full circle, i.e. 0 to 2*pi)
    lbound = 0;
    ubound = 2*pi;
    maxAngle = maxSteeringAngle * (pi/180);

    currentPosition.x = xStart;
    currentPosition.y = yStart;
    positionsX(1,1) = xStart;
    positionsY(1,1) = yStart;

    for i = 1:trajectoryResolution %size(timeVector, 2)
        randomAngle = lbound+rand()*(ubound-lbound);

        movementX(1, i) = cos(randomAngle) * distancePerStep;
        movementY(1, i) = sin(randomAngle) * distancePerStep;
        
        % if out of bounds, generate a new random angle without steering
        % limitations to stay inbounds
        while isOutOfBounds(currentPosition, movementX(1,i), movementY(1,i), xlimits, ylimits) 
            randomAngle = rand()*(2*pi);
            movementX(1, i) = cos(randomAngle) * distancePerStep;
            movementY(1, i) = sin(randomAngle) * distancePerStep;
        end 

        positionsX(1, i+1) = positionsX(1, i) + movementX(1,i);
        positionsY(1, i+1) = positionsY(1, i) + movementY(1,i);
        
        ubound = randomAngle - (maxAngle / 2);
        lbound = randomAngle + (maxAngle / 2);
        
        % keep track of current position to stay within limits
        currentPosition.x = currentPosition.x + movementX(1, i);
        currentPosition.y = currentPosition.y + movementY(1, i);
    end
    
    % reduce the vectors to the actual number of timesteps we have ("downsample")
    sampleNum = size(timeVector, 2);
    samplePoints = 1:1:(trajectoryResolution+1);
    interpolationStepSize = trajectoryResolution/sampleNum;

    queryPoints = 1:interpolationStepSize:trajectoryResolution;
    positionsX = interp1(samplePoints, positionsX, queryPoints);
    positionsY = interp1(samplePoints, positionsY, queryPoints);

    movementX = diff(positionsX);
    movementY = diff(positionsY);
    times = timeVector(1,1:end-1);

    if isnan(times)
        times = [];
        movementX = [];
        movementY = [];
    end


%     % debugging
%     % plot the waypoints
%      
%     figure;
%     for i = 2:size(movementX, 2)
%         hold on;
%         plot([positionsX(1, i-1) positionsX(1, i)], [positionsY(1, i-1) positionsY(1, i)], 'Color', 'black');
%         hold off;
%     end
%     axis equal;
end

function outOfBounds = isOutOfBounds(currentPosition, movementX, movementY, xlimits, ylimits)
    if (currentPosition.x + movementX) < xlimits(1,1) | (currentPosition.x + movementX) > xlimits(1,2) | ...
        (currentPosition.y + movementY) > ylimits(1,2) | (currentPosition.y + movementY) < ylimits(1,1)
        outOfBounds = true;
    else
        outOfBounds = false;
    end
end
