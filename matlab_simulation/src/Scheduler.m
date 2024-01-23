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

classdef Scheduler < handle
        
    properties %(Access = private)
        clock;
        timeKeeping;
        randomNumbers;
        slotMap;
        config;

        timeNextPingScheduled;
    end

    methods

        function this = Scheduler(clock, timeKeeping, randomNumbers, slotMap, config)
            this.clock = clock;
            this.timeKeeping = timeKeeping;
            this.randomNumbers = randomNumbers;
            this.slotMap = slotMap;
            this.config = config;
        end

        function timeNextSchedule = getTimeNextPingScheduled(this)
            timeNextSchedule = this.timeNextPingScheduled;
        end

        function wasSuccess = schedulePingAtTime(this, time)
            localTime = this.clock.getLocalTime();

            if time > localTime
                this.timeNextPingScheduled = time;
                wasSuccess = true;
            else
                wasSuccess = false;
            end
        end
        
        function isScheduledToNow = pingScheduledToNow(this)
            localTime = this.clock.getLocalTime();
            if isequal(localTime, this.timeNextPingScheduled) 
                isScheduledToNow = true;
            else
                isScheduledToNow = false;
            end
        end

        function wasSuccess = cancelScheduledPing(this)
            if ~isempty(this.timeNextPingScheduled)
                this.timeNextPingScheduled = [];
                wasSuccess = true;
            else
                wasSuccess = false;
            end
        end

        function nothingScheduled = nothingScheduledYet(this)
            timeNextSchedule = this.getTimeNextPingScheduled();
            if isempty(timeNextSchedule)
                nothingScheduled = true;
            else
                nothingScheduled = false;
            end
        end

        function slot = getSlotOfNextSchedule(this)
            timeNextSchedule = this.getTimeNextPingScheduled();
            slot = this.timeKeeping.calculateOwnSlotAtTime(timeNextSchedule);
        end

        function scheduleNextPing(this, state)
            switch state
                case States.LISTENING_UNCONNECTED
                    % schedule ping randomly within limit
                    lowerBound = this.clock.getLocalTime();
                    upperBound = lowerBound + this.config.initialPingUpperLimit();
                    scheduleTime = this.randomNumbers.getRandomIntBetween(lowerBound,upperBound);

                case States.LISTENING_CONNECTED
                    reserveAdditionalSlot = ~this.slotMap.slotReservationGoalMet();
                    if reserveAdditionalSlot
                        % reserve an additional slot
                        scheduleSlot = this.slotMap.getReservableSlot();
                    else
                        % schedule to next own or pending slot
                        currentSlot = this.timeKeeping.calculateCurrentSlotNum();
                        scheduleSlot = this.slotMap.getNextOwnOrPendingSlot(currentSlot);
                    end

                    delay = this.getRandomDelay();
                    scheduleTime = this.timeKeeping.calculateNextStartOfSlot(scheduleSlot) + this.config.guardPeriodLength + delay;
            end
            this.timeNextPingScheduled = scheduleTime;
        end
    end

    methods (Access = private)
        function delay = getRandomDelay(this)
            % delay is random, but always a multiple of the ping size so
            % pings do not overlap and chance of collision is lower
            minDelayFactor = 0;
            maxDelayFactor = floor(this.config.slotLength - 2 * this.config.guardPeriodLength - MessageSizes.PING_SIZE)/MessageSizes.PING_SIZE;
            delay = this.randomNumbers.getRandomIntBetween(minDelayFactor, maxDelayFactor) * MessageSizes.PING_SIZE;
        end
    end

end