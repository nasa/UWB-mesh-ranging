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

classdef DriverAbstractionLayer < handle
    
    properties %(Access = private)
        channel;
        globalClock;
        stateMachine;
        timeKeeping;

        sendingFinishedAt;
        messageIncoming;

        id;
    end

    methods 
        function this = DriverAbstractionLayer(channel, globalClock, timeKeeping)
            this.channel = channel;
            this.globalClock = globalClock;
            this.timeKeeping = timeKeeping;

            this.sendingFinishedAt = 0;
            this.messageIncoming = false;
        end

        function transmitPing(this, msg)
            global debugGlobalTime;

            if SimConfigs.VERBOSE
                disp(strcat(num2str(debugGlobalTime), ": Node ", num2str(this.id), " sent ping"));
            end

            this.transmit(msg, MessageSizes.PING_SIZE);
        end

        function transmitRangingPoll(this, msg)
            global debugGlobalTime;

            if SimConfigs.VERBOSE
                disp(strcat(num2str(debugGlobalTime), ": Node ", num2str(this.id), " sent poll"));
            end

            this.transmit(msg, MessageSizes.RANGING_POLL_SIZE);
        end

        function transmitRangingResponse(this, msg)
            global debugGlobalTime;

            if SimConfigs.VERBOSE
                disp(strcat(num2str(debugGlobalTime), ": Node ", num2str(this.id), " sent response"));
            end

            this.transmit(msg, MessageSizes.RANGING_RESP_SIZE);
        end

        function transmitRangingFinal(this, msg)
            global debugGlobalTime;

            if SimConfigs.VERBOSE
                disp(strcat(num2str(debugGlobalTime), ": Node ", num2str(this.id), " sent final"));
            end

            this.transmit(msg, MessageSizes.RANGING_FINAL_SIZE);
        end

        function transmitRangingResult(this, msg)
            global debugGlobalTime;

            if SimConfigs.VERBOSE
                disp(strcat(num2str(debugGlobalTime), ": Node ", num2str(this.id), " sent result"));
            end

            this.transmit(msg, MessageSizes.RANGING_RESULT_SIZE);
        end

        function notify(this, msg)

            global debugGlobalTime;
            currentSlot = this.timeKeeping.calculateCurrentSlotNum();

            if SimConfigs.VERBOSE
                switch msg.type
                    case MessageTypes.PING
                        disp(strcat(num2str(debugGlobalTime), ": Node ", num2str(this.id), " received ping from Node ", num2str(msg.senderId), " at slot ", num2str(currentSlot)));
                    case MessageTypes.COLLISION
                        disp(strcat(num2str(debugGlobalTime), ": Node ", num2str(this.id), " received collision at slot ", num2str(currentSlot)));
                    case MessageTypes.RANGING_POLL
                        disp(strcat(num2str(debugGlobalTime), ": Node ", num2str(this.id), " received poll from Node ", num2str(msg.senderId), " at slot ", num2str(currentSlot)));
                    case MessageTypes.RANGING_RESP
                        disp(strcat(num2str(debugGlobalTime), ": Node ", num2str(this.id), " received response from Node ", num2str(msg.senderId), " at slot ", num2str(currentSlot)));
                    case MessageTypes.RANGING_FINAL
                        disp(strcat(num2str(debugGlobalTime), ": Node ", num2str(this.id), " received final from Node ", num2str(msg.senderId), " at slot ", num2str(currentSlot)));
                    case MessageTypes.RANGING_RESULT
                        disp(strcat(num2str(debugGlobalTime), ": Node ", num2str(this.id), " received result from Node ", num2str(msg.senderId), " at slot ", num2str(currentSlot)));
                end
            end

            if msg.type == MessageTypes.PREAMBLE
                this.messageIncoming = true;
            else
                this.messageIncoming = false;
            end
            
            this.stateMachine.run(Events.INCOMING_MSG, msg);
        end

        function finished = sendingFinished(this)
            globalTime = this.globalClock.getGlobalTime();
            finished = globalTime >= this.sendingFinishedAt;
        end

        function incoming = isMessageIncoming(this)
            incoming = this.messageIncoming;
        end

        function setId(this, id)
            this.id = id;
        end

        function setStateMachine(this, stateMachine)
            this.stateMachine = stateMachine;
        end
        
    end

    methods (Access = private)
        function transmit(this, msg, size)
            globalTime = this.globalClock.getGlobalTime();
            if globalTime >= this.sendingFinishedAt
                globalTime = this.globalClock.getGlobalTime();
                this.channel.transmit(msg, globalTime);
                this.sendingFinishedAt = globalTime + size;
            end
        end
    end

end
