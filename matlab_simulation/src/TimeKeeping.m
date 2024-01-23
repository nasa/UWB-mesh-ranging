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

classdef TimeKeeping < handle
    
    properties %(Access = private)
        clock;
        config;

        resetAtTime;
        frameStartTime;
        lastPreambleReceivedTime;
        lastTimeIdled;
    end

    methods
        function this = TimeKeeping(clock, config)
            this.clock = clock;
            this.config = config;

            this.resetAtTime = 0;
            this.lastTimeIdled = 0;
        end

        function isOver = initialWaitTimeOver(this)
            localTime = this.clock.getLocalTime();
            waitUntil = (this.resetAtTime + this.config.initialWaitTime);

            if localTime >= waitUntil
                isOver = true;
            else
                isOver = false;
            end
        end

        function resetTime(this)
            localTime = this.clock.getLocalTime();
            this.resetAtTime = localTime;
        end

        function setFrameStartToTime(this, time)
            this.frameStartTime = time;
        end

        function currentSlot = calculateCurrentSlotNum(this)
            if isempty(this.frameStartTime)
                currentSlot = 1;
                return;
            end

            localTime = this.clock.getLocalTime();
            currentSlot = this.calculateOwnSlotAtTime(localTime);
        end

        function currentFrame = calculateCurrentFrameNum(this)
            localTime = this.clock.getLocalTime();
            currentFrame = floor((localTime - this.frameStartTime)/ (this.config.slotsPerFrame * this.config.slotLength) + 1);
        end

        function nextStart = calculateNextStartOfSlot(this, querySlot)
            localTime = this.clock.getLocalTime();
            currentFrame = this.calculateCurrentFrameNum();

            nextStart = this.frameStartTime + ((querySlot - 1) * this.config.slotLength) + ((currentFrame - 1) * this.config.slotLength * this.config.slotsPerFrame);
            if (nextStart <= localTime)
                nextStart = nextStart + (this.config.slotLength * this.config.slotsPerFrame);
            end             
        end

        function slot = calculateOwnSlotAtTime(this, time)
            % calculate for a given local time in which slot the node was
            % or will be then
            timeInSlot = mod(time, this.config.slotsPerFrame * this.config.slotLength);
            firstTimeInSlot = mod(this.frameStartTime, this.config.slotsPerFrame * this.config.slotLength);
            
            if (timeInSlot < firstTimeInSlot)
                timeInSlot = timeInSlot + this.config.slotsPerFrame * this.config.slotLength;
            end
            
            slot = floor(((timeInSlot - firstTimeInSlot) + this.config.slotLength)/this.config.slotLength);
        end

        function recordTime = recordPreamble(this, msg)
            this.lastPreambleReceivedTime = this.clock.getLocalTime();
            recordTime = this.lastPreambleReceivedTime;
        end

        function networkAgeNow = calculateNetworkAgeForLastPreamble(this, networkAgeAtLastPreamble)
            assert(~isempty(this.lastPreambleReceivedTime));

            timeSinceLastPreamble = this.calculateTimeSinceLastPreamble();

            networkAgeNow = networkAgeAtLastPreamble + timeSinceLastPreamble;
        end

        function frameStartTime = getFrameStartTime(this)
            % mainly used for testing
            frameStartTime = this.frameStartTime;
        end

        function setFrameStartTimeForLastPreamble(this, timeSinceFrameStartAtLastPreamble)
            localTime = this.clock.getLocalTime();
            timeSinceLastPreamble = this.calculateTimeSinceLastPreamble();
            this.frameStartTime = localTime - (timeSinceLastPreamble + timeSinceFrameStartAtLastPreamble);
        end

        function timeSinceFrameStart = calculateTimeSinceFrameStart(this)
%             assert(~isempty(this.frameStartTime));
            if isempty(this.frameStartTime)
                timeSinceFrameStart = [];
            end

            localTime = this.clock.getLocalTime();

            currentSlotNum = this.calculateCurrentSlotNum();
            timeInSlot = this.calculateTimeInSlot(localTime);

            timeSinceFrameStart = this.config.slotLength * (currentSlotNum - 1) + timeInSlot;
        end

        function remainingTime = getTimeRemainingInCurrentSlot(this)
            localTime = this.clock.getLocalTime();
            timeInSlot = this.calculateTimeInSlot(localTime);
            remainingTime = this.config.slotLength - timeInSlot;
        end

        function translatedCollisionTimes = translateTimeOfCollisionReports(this, msg)
            translatedCollisionTimes = this.lastPreambleReceivedTime - msg.collisionTimes;
        end
        
        function lastTimeIdled = getLastTimeIdled(this)
            lastTimeIdled = this.lastTimeIdled;
        end
        
        function setLastTimeIdled(this)
            this.lastTimeIdled = this.clock.getLocalTime();
        end
        
        function isWakeupTime = isAutoCycleWakeupTime(this, networkAge)
            sleeptime = (this.config.slotLength * this.config.slotsPerFrame)*this.config.autoDutyCycle;
            isWakeupTime = (mod(networkAge, sleeptime) == 0);
        end

    end

    methods(Access = private)
        function timeSinceLastPreamble = calculateTimeSinceLastPreamble(this)
            assert(~isempty(this.lastPreambleReceivedTime));

            localTime = this.clock.getLocalTime();
            timeSinceLastPreamble = localTime - this.lastPreambleReceivedTime;
        end

        function slot = calculateSlotFromTimeSinceFrameStart(this, timeSinceFrameStart)
            slot = ceil((timeSinceFrameStart + 1)/this.config.slotLength);
            assert(~(slot > this.config.slotsPerFrame));
            assert(~(slot == 0));
        end

        function timeInSlot = calculateTimeInSlot(this, time)
            % time in current slot
            timeInSlot = mod(time - this.frameStartTime, this.config.slotLength);
        end
    end
end