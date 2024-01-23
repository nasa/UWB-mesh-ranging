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

classdef StateMachine < handle

    properties %(Access = private)
        state;
        id;
        stateData;
        
        slotMap;
        scheduler;
        guardConditions;
        driverAbstractionLayer;
        timeKeeping;
        stateActions;
        rangingManager;
    end

    methods (Static)
        function id = getNewId(clear)
            persistent idCnt;

            if nargin == 1
                idCnt = [];
                return;
            end

            if isempty(idCnt)
                idCnt = 1;
            end

            id = idCnt;
            idCnt = idCnt + 1;
        end
    end

    methods
        function this = StateMachine(slotMap, scheduler, guardConditions, driverAbstractionLayer, timeKeeping, stateActions, rangingManager)
            this.id = StateMachine.getNewId();
            this.state = States.OFF;
            this.stateData = "";

            this.slotMap = slotMap;
            this.scheduler = scheduler;
            this.guardConditions = guardConditions;
            this.driverAbstractionLayer = driverAbstractionLayer;
            this.timeKeeping = timeKeeping;
            this.stateActions = stateActions;
            this.rangingManager = rangingManager;
        end

        function run(this, varargin)
            global debugGlobalTime;

            event = varargin{1};       

            if nargin == 3
                msg = varargin{2};
            end

            switch this.state
                case States.OFF
                    switch event
                        case Events.TURN_ON
                            this.state = States.LISTENING_UNCONNECTED;
                            this.stateActions.listeningUnconnectedTimeTicAction();
                    end

                case States.LISTENING_UNCONNECTED
                    switch event
                        case Events.INCOMING_MSG
                            if msg.type == MessageTypes.PING
                                this.state = States.LISTENING_CONNECTED;
                            end
                            this.stateActions.listeningUnconnectedIncomingMsgAction(msg);
                        case Events.TIME_TIC

                            pingScheduled = this.scheduler.pingScheduledToNow();
                            guardConditionsSatisfied = this.guardConditions.listeningUncToSendingUncAllowed();
                            if pingScheduled & guardConditionsSatisfied
                                this.state = States.SENDING_UNCONNECTED;
                                this.stateActions.sendingUnconnectedTimeTicAction();
                            else
                                % no state change
                                this.state = States.LISTENING_UNCONNECTED;
                                this.stateActions.listeningUnconnectedTimeTicAction();
                            end
                    end

                case States.SENDING_UNCONNECTED
                    switch event
                        case Events.TIME_TIC
                           sendingFinished = this.driverAbstractionLayer.sendingFinished();
                           guardConditionsSatisfied = this.guardConditions.sendingUncToListeningConAllowed();  
                           if sendingFinished & guardConditionsSatisfied
                                this.state = States.LISTENING_CONNECTED;
                                this.stateActions.listeningConnectedTimeTicAction();
                           else
                               % no state change
                                this.stateActions.sendingUnconnectedTimeTicAction();
                           end
                    end

                case States.LISTENING_CONNECTED
                    switch event
                        case Events.INCOMING_MSG
                            
                            switch msg.type
                                case MessageTypes.RANGING_POLL
                                    if (msg.recipient == this.id)
                                        this.state = States.RANGING_WAITING;
                                    end

                                case MessageTypes.PING
                            
                            end

                            this.stateActions.listeningConnectedIncomingMsgAction(msg);

                        case Events.TIME_TIC
                            pingScheduled = this.scheduler.pingScheduledToNow();
                            sendingConnectedOkay = this.guardConditions.listeningConToSendingConAllowed();  
                            listeningUnconnectedOkay = this.guardConditions.listeningConToListeningUncAllowed();
                            startRangingOkay = this.guardConditions.rangingPollAllowed();
                            idleingOkay = this.guardConditions.idleingAllowed();
                            
                            if idleingOkay
                                this.state = States.IDLE;
                                this.stateActions.idleTimeTicAction();
                            end

                            if pingScheduled & sendingConnectedOkay & this.state == States.LISTENING_CONNECTED
                                this.state = States.SENDING_CONNECTED;
                                this.stateActions.sendingConnectedTimeTicAction();
                            elseif pingScheduled & ~sendingConnectedOkay
                                this.scheduler.cancelScheduledPing();
                            end

                            if ~pingScheduled & startRangingOkay & this.state == States.LISTENING_CONNECTED
                                this.state = States.RANGING_POLL;
                                this.stateActions.rangingPollTimeTicAction();
                            end

                            if this.state == States.LISTENING_CONNECTED
                                % no transition was done
                                this.stateActions.listeningConnectedTimeTicAction();
                                if listeningUnconnectedOkay
                                    this.state = States.LISTENING_UNCONNECTED;
                                    this.stateActions.listeningUnconnectedTimeTicAction();
                                end
                            end
                    end

               case States.SENDING_CONNECTED
                   switch event
                       case Events.TIME_TIC
                           sendingFinished = this.driverAbstractionLayer.sendingFinished();
                           if sendingFinished
                               this.state = States.LISTENING_CONNECTED;
                               this.stateActions.listeningConnectedTimeTicAction();
                           end
                   end

               case States.RANGING_POLL
                    switch event
                        case Events.INCOMING_MSG
                            % do nothing
                            
                        case Events.TIME_TIC
                            sendingFinished = this.driverAbstractionLayer.sendingFinished();
                            if sendingFinished
                                this.rangingManager.recordRangingMsgOut();
                                this.state = States.LISTENING_RANGING;
                                this.stateActions.listeningConnectedTimeTicAction();
                            end
                            
                            if this.state == States.RANGING_POLL
                                this.stateActions.rangingPollTimeTicAction();
                            end
                    end

                case States.RANGING_WAITING
                    switch event
                        case Events.INCOMING_MSG
                        
                        case Events.TIME_TIC
%                             this.stateData = "";

                            if  this.rangingManager.waitTimeOver()
                                lastIncomingRangingMessage = this.rangingManager.getLastRangingMessage();
                                if lastIncomingRangingMessage.type == MessageTypes.RANGING_POLL
                                    this.state = States.RANGING_RESP;
                                    this.stateActions.rangingResponseTimeTicAction(lastIncomingRangingMessage);
                                elseif lastIncomingRangingMessage.type == MessageTypes.RANGING_RESP
                                    this.state = States.RANGING_FINAL;
                                    this.stateActions.rangingFinalTimeTicAction(lastIncomingRangingMessage);
                                elseif lastIncomingRangingMessage.type == MessageTypes.RANGING_FINAL
                                    this.state = States.RANGING_RESULT;
                                    this.stateActions.rangingResultTimeTicAction(lastIncomingRangingMessage);
                                end
                            end
                    end
                    
                case States.RANGING_RESP
                    switch event
                        case Events.INCOMING_MSG
                            % do nothing
                            
                        case Events.TIME_TIC
                            sendingFinished = this.driverAbstractionLayer.sendingFinished();
                            if sendingFinished
                                this.rangingManager.recordRangingMsgOut();
                                this.state = States.LISTENING_RANGING;
                                this.stateActions.listeningConnectedTimeTicAction();
                            end
                            
                            if this.state == States.RANGING_RESP
                                lastIncomingRangingMessage = this.rangingManager.getLastRangingMessage();
                                this.stateActions.rangingResponseTimeTicAction(lastIncomingRangingMessage);
                            end
                    end
                    
                case States.RANGING_FINAL
                    switch event
                        case Events.INCOMING_MSG
                            % do nothing
                        case Events.TIME_TIC
                            sendingFinished = this.driverAbstractionLayer.sendingFinished();
                            if sendingFinished
                                this.rangingManager.recordRangingMsgOut();
                                this.state = States.LISTENING_RANGING;
                                this.stateActions.listeningConnectedTimeTicAction();
                            end
                            
                            if this.state == States.RANGING_FINAL
                                lastIncomingRangingMessage = this.rangingManager.getLastRangingMessage();
                                this.stateActions.rangingFinalTimeTicAction(lastIncomingRangingMessage);
                            end
                    end

                case States.RANGING_RESULT
                    switch event
                        case Events.INCOMING_MSG
                            % do nothing
                        case Events.TIME_TIC
                            sendingFinished = this.driverAbstractionLayer.sendingFinished();
                            if sendingFinished
                                this.rangingManager.recordRangingMsgOut();
                                this.state = States.LISTENING_CONNECTED;
                                this.stateActions.listeningConnectedTimeTicAction();
                            end
                            
                            if this.state == States.RANGING_RESULT
                                lastIncomingRangingMessage = this.rangingManager.getLastRangingMessage();
                                this.stateActions.rangingResultTimeTicAction(lastIncomingRangingMessage);
                            end
                    end
                case States.LISTENING_RANGING
                    switch event
                        case Events.INCOMING_MSG
                            switch msg.type
                                case MessageTypes.RANGING_RESP
                                    this.state = States.RANGING_WAITING;
                                case MessageTypes.RANGING_FINAL
                                    this.state = States.RANGING_WAITING;
                                case MessageTypes.RANGING_RESULT
                                    this.state = States.LISTENING_CONNECTED;
                            end
                            this.stateActions.listeningRangingIncomingMsgAction(msg);

                        case Events.TIME_TIC
                            if this.rangingManager.rangingTimedOut()
                                this.state = States.LISTENING_CONNECTED;
                                this.stateActions.listeningConnectedTimeTicAction();
                            end
                    end
                case States.IDLE
                    switch event
                        case Events.INCOMING_MSG
                            idleEnd = this.guardConditions.idleToListeningConAllowedIncomingMsg(msg);
                            if idleEnd
                                this.slotMap.extendTimeouts(); % extend slot timeouts cause otherwise they would be expired
                                this.timeKeeping.setLastTimeIdled();
                                this.state = States.LISTENING_CONNECTED;
                                this.stateActions.listeningConnectedIncomingMsgAction(msg);
                            end
                            
                            % otherwise process the message but keep
                            % idleing
                            if this.state == States.IDLE
                                this.stateActions.idleIncomingMsgAction(msg);
                            end
                        case Events.TIME_TIC
                            idleEnd = this.guardConditions.idleToListeningConAllowed();
                            
                            if idleEnd
                                this.slotMap.extendTimeouts(); % extend slot timeouts cause otherwise they would be expired
                                this.timeKeeping.setLastTimeIdled();
                                this.state = States.LISTENING_CONNECTED;
                                this.stateActions.listeningConnectedTimeTicAction();
                            end
                            
                            if this.state == States.IDLE
                                this.stateActions.idleTimeTicAction();
                            end
                    end
            end
        end

        function state = getState(this)
            state = this.state;
        end

        function id = getId(this)
            id = this.id;
        end
    end

end





