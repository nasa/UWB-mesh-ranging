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

classdef Diagram_mex < handle
    
    properties
        pWrapper;
        id;
        slotLength;
        
        statusStructure = {};
        slotLevelSymbols = struct;
        ticLevelSymbols = struct;
                
        firstSymbolInsertedFlag; % necessary to insert on "9." when unconnected listening is started
        exportLengthLimit = 4000;
    end
    
    methods
        
        function this = Diagram_mex(id, pWrapper, config)
            this.id = id;
            this.pWrapper = pWrapper;
            this.slotLength = config.slotLength;
            
            this.initializeDataStructure();
        end
        
        function updateOnTimeTic(this, status, statusData, globalTime)
            slotNum = MatlabWrapper(19, this.pWrapper, this.id);
            networkId = MatlabWrapper(16, this.pWrapper, this.id);
            
            [statusStructureIdx, symbols] = this.getStructureIdxAndSymbols(status, globalTime);
            if slotNum ~= 0
                % update status
                switch status
                    case States_mex.LISTENING_UNCONNECTED
                        this.statusStructure{statusStructureIdx, 1}.statusWave{1, end+1} = symbols.listeningSymbol;
                        this.statusStructure{statusStructureIdx, 1}.networkWave{1, end+1} = symbols.unconnectedSymbol;
                        this.statusStructure{statusStructureIdx, 1}.networkData{1, end+1} = "";
                        this.statusStructure{statusStructureIdx, 1}.statusData{1, end+1} = strcat('"', statusData, '"');
                        
                        this.statusStructure{statusStructureIdx, 1}.lastStatusSymbol = symbols.listeningSymbol;
                        
                    case States.LISTENING_CONNECTED
                        this.statusStructure{statusStructureIdx, 1}.statusWave{1, end+1} = symbols.listeningSymbol;
                        this.statusStructure{statusStructureIdx, 1}.networkWave{1, end+1} = symbols.connectedSymbol;
                        this.statusStructure{statusStructureIdx, 1}.networkData{1, end+1} = num2str(networkId);
                        this.statusStructure{statusStructureIdx, 1}.statusData{1, end+1} = strcat('"', statusData, '"');
                        
                        this.statusStructure{statusStructureIdx, 1}.lastStatusSymbol = symbols.listeningSymbol;

                    case States_mex.SENDING_UNCONNECTED
                        
                        if strcmp(this.statusStructure{statusStructureIdx, 1}.lastStatusSymbol, symbols.sendingSymbol)
                            this.statusStructure{statusStructureIdx, 1}.statusWave{1, end+1} = symbols.repeatSymbol;
                            this.statusStructure{statusStructureIdx, 1}.statusData{1, end+1} = "";
                        else
                            this.statusStructure{statusStructureIdx, 1}.statusWave{1, end+1} = symbols.sendingSymbol;
                            this.statusStructure{statusStructureIdx, 1}.statusData{1, end+1} = strcat('"', statusData, '"');
                        end
                        this.statusStructure{statusStructureIdx, 1}.networkWave{1, end+1} = symbols.unconnectedSymbol;
                        this.statusStructure{statusStructureIdx, 1}.networkData{1, end+1} = "";
                        
                        this.statusStructure{statusStructureIdx, 1}.lastStatusSymbol = symbols.sendingSymbol;

                    case States_mex.SENDING_CONNECTED
                        
                        if strcmp(this.statusStructure{statusStructureIdx, 1}.lastStatusSymbol, symbols.sendingSymbol)
                            this.statusStructure{statusStructureIdx, 1}.statusWave{1, end+1} = symbols.repeatSymbol;
                            this.statusStructure{statusStructureIdx, 1}.statusData{1, end+1} = "";
                        else
                            this.statusStructure{statusStructureIdx, 1}.statusWave{1, end+1} = symbols.sendingSymbol;
                            this.statusStructure{statusStructureIdx, 1}.statusData{1, end+1} = strcat('"', statusData, '"');
                        end
                        this.statusStructure{statusStructureIdx, 1}.networkWave{1, end+1} = symbols.connectedSymbol;
                        this.statusStructure{statusStructureIdx, 1}.networkData{1, end+1} = num2str(networkId);

                        this.statusStructure{statusStructureIdx, 1}.lastStatusSymbol = symbols.sendingSymbol;

                        
                    case States_mex.OFF
                        
                    case States_mex.IDLE
                        this.statusStructure{statusStructureIdx, 1}.statusWave{1, end+1} = symbols.idleSymbol;
                        this.statusStructure{statusStructureIdx, 1}.networkWave{1, end+1} = symbols.connectedSymbol;
                        this.statusStructure{statusStructureIdx, 1}.slotsWave{1, end+1} = symbols.slotFreeSymbol;
                        this.statusStructure{statusStructureIdx, 1}.statusData{1, end+1} = '""';
                        this.statusStructure{statusStructureIdx, 1}.slotsData{1, end+1} = '""';
                        this.statusStructure{statusStructureIdx, 1}.networkData{1, end+1} = num2str(networkId);
                        
                        this.statusStructure{statusStructureIdx, 1}.lastStatusSymbol = symbols.idleSymbol;

                        
                    case States_mex.RANGING_POLL
                        
                        if strcmp(this.statusStructure{statusStructureIdx, 1}.lastStatusSymbol, symbols.sendingSymbol)
                            this.statusStructure{statusStructureIdx, 1}.statusWave{1, end+1} = symbols.repeatSymbol;
                            this.statusStructure{statusStructureIdx, 1}.statusData{1, end+1} = "";
                        else
                            this.statusStructure{statusStructureIdx, 1}.statusWave{1, end+1} = symbols.sendingSymbol;
                            this.statusStructure{statusStructureIdx, 1}.statusData{1, end+1} = strcat('"', statusData, '"');
                        end
                        this.statusStructure{statusStructureIdx, 1}.networkWave{1, end+1} = symbols.connectedSymbol;
                        this.statusStructure{statusStructureIdx, 1}.networkData{1, end+1} = num2str(networkId);
                        
                        this.statusStructure{statusStructureIdx, 1}.lastStatusSymbol = symbols.sendingSymbol;

                        
                    case States_mex.RANGING_WAITING
                        % same as listening
                        this.statusStructure{statusStructureIdx, 1}.statusWave{1, end+1} = symbols.listeningSymbol;
                        this.statusStructure{statusStructureIdx, 1}.networkWave{1, end+1} = symbols.connectedSymbol;
                        this.statusStructure{statusStructureIdx, 1}.networkData{1, end+1} = num2str(networkId);
                        this.statusStructure{statusStructureIdx, 1}.statusData{1, end+1} = strcat('"', statusData, '"');
                        
                        this.statusStructure{statusStructureIdx, 1}.lastStatusSymbol = symbols.listeningSymbol;

                        
                    case States_mex.RANGING_RESP
                        if strcmp(this.statusStructure{statusStructureIdx, 1}.lastStatusSymbol, symbols.sendingSymbol)
                            this.statusStructure{statusStructureIdx, 1}.statusWave{1, end+1} = symbols.repeatSymbol;
                            this.statusStructure{statusStructureIdx, 1}.statusData{1, end+1} = "";
                        else
                            this.statusStructure{statusStructureIdx, 1}.statusWave{1, end+1} = symbols.sendingSymbol;
                            this.statusStructure{statusStructureIdx, 1}.statusData{1, end+1} = strcat('"', statusData, '"');
                        end
                        this.statusStructure{statusStructureIdx, 1}.networkWave{1, end+1} = symbols.connectedSymbol;
                        this.statusStructure{statusStructureIdx, 1}.networkData{1, end+1} = num2str(networkId);
                    
                        this.statusStructure{statusStructureIdx, 1}.lastStatusSymbol = symbols.sendingSymbol;
                        
                    case States_mex.RANGING_FINAL
                       if strcmp(this.statusStructure{statusStructureIdx, 1}.lastStatusSymbol, symbols.sendingSymbol)
                            this.statusStructure{statusStructureIdx, 1}.statusWave{1, end+1} = symbols.repeatSymbol;
                            this.statusStructure{statusStructureIdx, 1}.statusData{1, end+1} = "";
                        else
                            this.statusStructure{statusStructureIdx, 1}.statusWave{1, end+1} = symbols.sendingSymbol;
                            this.statusStructure{statusStructureIdx, 1}.statusData{1, end+1} = strcat('"', statusData, '"');
                        end
                        this.statusStructure{statusStructureIdx, 1}.networkWave{1, end+1} = symbols.connectedSymbol;
                        this.statusStructure{statusStructureIdx, 1}.networkData{1, end+1} = num2str(networkId);
                    
                        this.statusStructure{statusStructureIdx, 1}.lastStatusSymbol = symbols.sendingSymbol; 
                    case States_mex.RANGING_RESULT
                       if strcmp(this.statusStructure{statusStructureIdx, 1}.lastStatusSymbol, symbols.sendingSymbol)
                            this.statusStructure{statusStructureIdx, 1}.statusWave{1, end+1} = symbols.repeatSymbol;
                            this.statusStructure{statusStructureIdx, 1}.statusData{1, end+1} = "";
                        else
                            this.statusStructure{statusStructureIdx, 1}.statusWave{1, end+1} = symbols.sendingSymbol;
                            this.statusStructure{statusStructureIdx, 1}.statusData{1, end+1} = strcat('"', statusData, '"');
                        end
                        this.statusStructure{statusStructureIdx, 1}.networkWave{1, end+1} = symbols.connectedSymbol;
                        this.statusStructure{statusStructureIdx, 1}.networkData{1, end+1} = num2str(networkId);
                    
                        this.statusStructure{statusStructureIdx, 1}.lastStatusSymbol = symbols.sendingSymbol;                         
                end

                % update slots
                if status ~= States_mex.IDLE
                    
                    slotMap = MatlabWrapper(18, this.pWrapper, this.id);
                    oneHopSlotsStatus = slotMap.oneHopStatus;
                    ownSlots = MatlabWrapper(13, this.pWrapper, this.id);
                    currentSlotNum = MatlabWrapper(19, this.pWrapper, this.id);
                    
                    switch oneHopSlotsStatus(1, slotNum)
                        case 0
                            if ~isempty(find(ownSlots == slotNum, 1)) %& (status == 2 | status == 3)
                                this.statusStructure{statusStructureIdx, 1}.slotsWave{1, end+1} = symbols.slotOwnSymbol;
                                this.statusStructure{statusStructureIdx, 1}.lastSlotSymbol = symbols.slotOwnSymbol;
                            else
                                this.statusStructure{statusStructureIdx, 1}.slotsWave{1, end+1} = symbols.slotFreeSymbol;
                                this.statusStructure{statusStructureIdx, 1}.lastSlotSymbol = symbols.slotFreeSymbol;

                            end
                            this.statusStructure{statusStructureIdx, 1}.slotsData{1, end+1} = strcat('"', num2str(currentSlotNum), '"');

                        case 1
                            this.statusStructure{statusStructureIdx, 1}.slotsWave{1, end+1} = symbols.slotOccupiedSymbol;
                            oneHopSlotsId = slotMap.oneHopIds;
                            this.statusStructure{statusStructureIdx, 1}.slotsData{1, end+1} = strcat('"', num2str(currentSlotNum), "[", num2str(oneHopSlotsId(1, slotNum)), "]", '"');
                            this.statusStructure{statusStructureIdx, 1}.lastSlotSymbol = symbols.slotOccupiedSymbol;
                                
                        case 2
                            this.statusStructure{statusStructureIdx, 1}.slotsWave{1, end+1} = symbols.slotCollidingSymbol;
                            this.statusStructure{statusStructureIdx, 1}.slotsData{1, end+1} = strcat('"', num2str(currentSlotNum), '"');
                            this.statusStructure{statusStructureIdx, 1}.lastSlotSymbol = symbols.slotCollidingSymbol;
                    end
                end
            else
                switch status 
                    case States_mex.LISTENING_UNCONNECTED 
                        this.statusStructure{statusStructureIdx, 1}.statusWave{1, end+1} = symbols.listeningSymbol;
                        this.statusStructure{statusStructureIdx, 1}.networkWave{1, end+1} = symbols.unconnectedSymbol;
                        this.statusStructure{statusStructureIdx, 1}.slotsWave{1, end+1} = symbols.slotFreeSymbol;

                        this.statusStructure{statusStructureIdx, 1}.statusData{1, end+1} = strcat('"', statusData, '"');

                        this.statusStructure{statusStructureIdx, 1}.slotsData{1, end+1} = '""';
                        this.statusStructure{statusStructureIdx, 1}.networkData{1, end+1} = "";

                        if strcmp(this.statusStructure{statusStructureIdx, 1}.level, "slot")
                            this.firstSymbolInsertedFlag = true;
                        end
                    case States_mex.LISTENING_CONNECTED

                    case States_mex.SENDING_UNCONNECTED

                    case States_mex.SENDING_CONNECTED

                    case States_mex.OFF
                        this.statusStructure{statusStructureIdx, 1}.statusWave{1, end+1} = symbols.offSymbol;
                        this.statusStructure{statusStructureIdx, 1}.networkWave{1, end+1} = symbols.offSymbol;
                        this.statusStructure{statusStructureIdx, 1}.slotsWave{1, end+1} = symbols.offSymbol;

                        this.statusStructure{statusStructureIdx, 1}.statusData{1, end+1} = "";
                        this.statusStructure{statusStructureIdx, 1}.slotsData{1, end+1} = "";
                        this.statusStructure{statusStructureIdx, 1}.networkData{1, end+1} = "";

                    case States_mex.IDLE

                end
            end

            this.statusStructure{statusStructureIdx, 1}.globalTimeLineWave{1, end+1} = symbols.timeLineSymbol;
            this.statusStructure{statusStructureIdx, 1}.globalTimeLineData{1, end+1} = globalTime;
            this.statusStructure{statusStructureIdx, 1}.lastUpdate = globalTime;
            this.statusStructure{statusStructureIdx, 1}.slotNumWhenLastUpdated = slotNum;
        end
        
        function [statusStructureIdx, symbols] = getStructureIdxAndSymbols(this, status, time)
            ticSymbols = this.ticLevelSymbols;
            
            if (time == 0)
                ticSymbols.offSymbol = "0";
                ticSymbols.unconnectedSymbol = "0";
            end
            
            % tic level
            statusStructureIdx = 1;
            symbols = ticSymbols;
        end
        
        function trimmed = trimTicLevelDiagram(this, startTime, endTime)
            trimmed = struct;
            
            startIdx = find(cell2mat(this.statusStructure{1,1}.globalTimeLineData) == startTime);
            endIdx = find(cell2mat(this.statusStructure{1,1}.globalTimeLineData) == endTime);
            
            trimmed.statusWave = this.statusStructure{1,1}.statusWave(startIdx:endIdx);
            trimmed.statusData = this.statusStructure{1,1}.statusData(startIdx:endIdx);
            trimmed.slotsWave = this.statusStructure{1,1}.slotsWave(startIdx:endIdx);
            trimmed.slotsData = this.statusStructure{1,1}.slotsData(startIdx:endIdx);
            trimmed.networkWave = this.statusStructure{1,1}.networkWave(startIdx:endIdx);
            trimmed.networkData = this.statusStructure{1,1}.networkData(startIdx:endIdx);            
            trimmed.globalTimeLineWave = this.statusStructure{1,1}.globalTimeLineWave(startIdx:endIdx);
            trimmed.globalTimeLineData = this.statusStructure{1,1}.globalTimeLineData(startIdx:endIdx);
        end
               
        function exportData(this, path, structureToExport)
            statusPrefix = "{ ""name"": ""Node " + num2str(this.id) + """, ""wave"": """;
            slotsPrefix = "{ ""name"": ""Slots"", ""wave"": """;
            networkPrefix = "{ ""name"": ""Network"", ""wave"": """;            
            
            statusWaveString = statusPrefix;
            statusDataString = "";
            for i=1:size(structureToExport.statusWave, 2)
                statusWaveString = strcat(statusWaveString, structureToExport.statusWave{1, i});
                if structureToExport.statusData{1, i} ~= ""
                    statusDataString = strcat(statusDataString, structureToExport.statusData{1, i}, ",");
                end
            end
            statusSuffix = """, ""data"":[" + statusDataString + "]},";
            statusWaveString = strcat(statusWaveString, statusSuffix);
            
            slotsWaveString = slotsPrefix;
            slotsDataString = "";
            for i=1:size(structureToExport.slotsWave, 2)
                slotsWaveString = strcat(slotsWaveString, structureToExport.slotsWave{1, i});
                if ~(structureToExport.slotsData{1, i} == "") %| structureToExport.slotsWave{1, i} == ".")
                    slotsDataString = strcat(slotsDataString, structureToExport.slotsData{1, i}, ",");
                end
            end
            slotsSuffix = """, ""data"":[" + slotsDataString + "]},";
            slotsWaveString = strcat(slotsWaveString, slotsSuffix);

            networkWaveString = networkPrefix;
            networkDataString = "";
            for i=1:size(structureToExport.networkWave, 2)
                networkWaveString = strcat(networkWaveString, structureToExport.networkWave{1, i});
                if structureToExport.networkData{1, i} ~= ""
                    networkDataString = strcat(networkDataString, structureToExport.networkData{1, i}, ",");
                end
            end
            networkSuffix = """, ""data"":[" + networkDataString + "]},";
            networkWaveString = strcat(networkWaveString, networkSuffix);
            
            fid = fopen(path,'at');
            fprintf(fid, statusWaveString + '\n');
            fprintf(fid, slotsWaveString + '\n');
            fprintf(fid, networkWaveString + '\n');

            fclose(fid);
        end
        
        function [globalTimeLineSlotsWaveString, globalTimeLineSlotsDataString] = getGlobalTimeLineSlotLevel(this)
            globalTimeLineSlotsWaveString = "";
            globalTimeLineSlotsDataString = "";
            for i=1:size(this.statusStructure{2, 1}.globalTimeLineWave, 2)
                globalTimeLineSlotsWaveString = strcat(globalTimeLineSlotsWaveString, this.statusStructure{2, 1}.globalTimeLineWave{1, i});
            end
            for i=1:size(this.statusStructure{2, 1}.globalTimeLineData, 2)
                globalTimeLineSlotsDataString = strcat(globalTimeLineSlotsDataString, '"', num2str(this.statusStructure{2, 1}.globalTimeLineData{1, i}), '"', ",");
            end
        end
        
        function [globalTimeLineTicsWaveString, globalTimeLineTicsDataString] = getGlobalTimeLineTicLevel(this, varargin)
            if nargin > 1
                startIdx = find(cell2mat(this.statusStructure{1,1}.globalTimeLineData) == varargin{1});
                endIdx = find(cell2mat(this.statusStructure{1,1}.globalTimeLineData) == varargin{2});
            else
                startIdx = 1;
                endIdx = size(this.statusStructure{1, 1}.globalTimeLineWave, 2);
            end

            globalTimeLineTicsWaveString = "";
            globalTimeLineTicsDataString = "";
            for i=startIdx:endIdx
                globalTimeLineTicsWaveString = strcat(globalTimeLineTicsWaveString, this.statusStructure{1, 1}.globalTimeLineWave{1, i});
            end
            for i=startIdx:endIdx
                globalTimeLineTicsDataString = strcat(globalTimeLineTicsDataString, '"', num2str(this.statusStructure{1, 1}.globalTimeLineData{1, i}), '"', ",");
            end
        end
        
        function setId(this, id)
            this.id = id;
        end

        function newPath = insertPartCounterInPath(this, partCounter, path)
            newPath = insertBefore(path, ".txt", strcat("_", num2str(partCounter)));
        end
        
        function initializeDataStructure(this)
            % slot-level
            this.statusStructure{2,1}.statusWave = {"0"};
            this.statusStructure{2,1}.statusData = {""};

            this.statusStructure{2,1}.slotsWave = {"0"};
            this.statusStructure{2,1}.slotsData = {""};

            this.statusStructure{2,1}.networkWave = {"0"};
            this.statusStructure{2,1}.networkData = {""};
            
            this.statusStructure{2,1}.globalTimeLineWave = {"0"};
            this.statusStructure{2,1}.globalTimeLineData = {};

            this.statusStructure{2,1}.lastUpdate = 0;
            this.statusStructure{2,1}.slotNumWhenLastUpdated = 0;
            
            this.statusStructure{2,1}.lastStatusSymbol = {""};
            this.statusStructure{2,1}.lastSlotSymbol = {""};

            this.statusStructure{2,1}.level = "slot";
            
            % symbols
            this.slotLevelSymbols.listeningSymbol = "9.";      % red
            this.slotLevelSymbols.sendingSymbol = "5.";        % blue
            this.slotLevelSymbols.idleSymbol = "7.";           % green
            this.slotLevelSymbols.offSymbol = "..";            % flatline
            this.slotLevelSymbols.repeatSymbol = "..";
            
            this.slotLevelSymbols.unconnectedSymbol = "0.";    % flatline
            this.slotLevelSymbols.connectedSymbol = "3.";      % yellow

            this.slotLevelSymbols.slotOccupiedSymbol = "8.";   % pink
            this.slotLevelSymbols.slotFreeSymbol = "2.";       % blank
            this.slotLevelSymbols.slotOwnSymbol = "6.";        % teal
            this.slotLevelSymbols.slotCollidingSymbol = "4.";  % orange

            this.slotLevelSymbols.timeLineSymbol = "2.";
            
            % tic-level
            this.statusStructure{1,1}.statusWave = {};
            this.statusStructure{1,1}.statusData = {};

            this.statusStructure{1,1}.slotsWave = {};
            this.statusStructure{1,1}.slotsData = {};

            this.statusStructure{1,1}.networkWave = {};
            this.statusStructure{1,1}.networkData = {};
            
            this.statusStructure{1,1}.globalTimeLineWave = {};
            this.statusStructure{1,1}.globalTimeLineData = {};
            
            this.statusStructure{1,1}.lastUpdate = 0;
            this.statusStructure{1,1}.slotNumWhenLastUpdated = 0;      
            
            this.statusStructure{1,1}.lastStatusSymbol = {""};
            this.statusStructure{1,1}.lastSlotSymbol = {""};

            this.statusStructure{1,1}.level = "tic";

            
            % symbols
            this.ticLevelSymbols.listeningSymbol = "9";      % red
            this.ticLevelSymbols.sendingSymbol = "5";        % blue
            this.ticLevelSymbols.idleSymbol = "7";         % green
            this.ticLevelSymbols.offSymbol = ".";            % flatline
            this.ticLevelSymbols.repeatSymbol = ".";
            
            this.ticLevelSymbols.unconnectedSymbol = "0";    % flatline
            this.ticLevelSymbols.connectedSymbol = "3";      % yellow

            this.ticLevelSymbols.slotOccupiedSymbol = "8";   % pink
            this.ticLevelSymbols.slotFreeSymbol = "2";       % blank
            this.ticLevelSymbols.slotOwnSymbol = "6";        % teal
            this.ticLevelSymbols.slotCollidingSymbol = "4";  % orange

            this.ticLevelSymbols.timeLineSymbol = "2";
        end
        
    end
    
end