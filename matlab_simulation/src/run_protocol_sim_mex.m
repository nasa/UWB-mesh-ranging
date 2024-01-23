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

% run_protocol_sim_mex
function results = run_protocol_sim_mex(pWrapper, nodes, nodeConfigs, simConfig, channel, animation)
    global nodeTimes; 
    timeSampleCount = 1;
    
    globalTime = 0;
    stopCriteriaFrameCounter = 0;
    activeNodes = {}; % nodes that are turned on
    msgs = cell(size(nodes, 1), 1); % to hold the messages temporarily after a time tic
    validationData.pingsSent = cell(size(nodes, 1), 1);
    validationData.states = cell(size(nodes, 1), 1);
    
    % get config
    config = MatlabWrapper(14, pWrapper, 1);
    
    while true
        
        % turn nodes on at their individual enterTime
        for i = 1:size(nodes, 1)
            nodeId = nodes{i,1};
            % turn node on
            if (globalTime == nodeConfigs{i, 1}.enterTime)
                activeNodes{end+1, 1} = nodes{i,1};
                activeNodes{end, 2} = nodes{i,2};
                activeNodes{end, 3} = nodes{i,3};
                
                % subscribe to channel
                channel.subscribe(nodeId);
                
                MatlabWrapper(5, pWrapper, nodeId);   
                if (simConfig.showAnimation)
                    animation.addNode(nodes(i, :), globalTime);
                end
            end
        end
        
        % let nodes move
        for i = 1:size(activeNodes, 1)
            if isempty(nodeConfigs{i, 1}.movementTimes)
               continue; 
            end
            if globalTime == nodeConfigs{i, 1}.movementTimes(1,1)
                activeNodes{i, 2}.x = activeNodes{i, 2}.x + nodeConfigs{i, 1}.movementsX(1,1);
                activeNodes{i, 2}.y = activeNodes{i, 2}.y + nodeConfigs{i, 1}.movementsY(1,1);
                nodeConfigs{i, 1}.movementTimes(:,1) = [];
                nodeConfigs{i, 1}.movementsX(:,1) = [];
                nodeConfigs{i, 1}.movementsY(:,1) = [];
            end
        end
        
        for i = 1:size(activeNodes, 1)
            % run state machine with time tic
            nodeId = activeNodes{i, 1};
            
            msg = MatlabWrapper(3, pWrapper, nodeId); % time tic
           
            validationData.states{nodeId, 1}(1, end+1) = MatlabWrapper(11, pWrapper, nodeId);
            % message was sent if type is not -1
            if msg.type ~= -1
                msgs{i, 1} = 1; % has to be not "NaN", so just put in 1
                msgs{i, 2} = msg;
                if msg.type == 0 % PING
                    validationData.pingsSent{nodeId, 1}(1, end+1) = globalTime;
                end
            else
                msgs{i, 1} = nan;
            end
        end
        
        for i = 1:size(activeNodes, 1)
            if (~isnan(msgs{i, 1}))
                channel.transmit(msgs{i, 2}, globalTime);
            end
        end
        
        % execute the channel (actually transmit all messages that are due)
        channel.execute(globalTime, activeNodes);
        
        for i = 1:size(activeNodes, 1)
            % actually increment the time (has to be done independent from
            % time tic event to avoid slight time differences between
            % nodes)
            
            nodeId = activeNodes{i, 1};
            
            MatlabWrapper(9, pWrapper, nodeId); % increment time
            
            % save the local times of all nodes regularly
            if (mod(globalTime, 100) == 0)
                % get and save local time
                nodeTimes(timeSampleCount, nodeId) = MatlabWrapper(12, pWrapper, nodeId); % increment time
                if (i == size(activeNodes, 1))
                    % increment timeSampleCount
                    timeSampleCount = timeSampleCount + 1; 
                end
            end
        end
                
        % increment globalTime
        globalTime = globalTime + 1;
        
        if (mod(globalTime, config.frameLength) == 0) % check only once per frame
            if checkStopCriteria_mex(globalTime, activeNodes, nodes, nodeConfigs, channel, config, pWrapper, [])
                stopCriteriaFrameCounter = stopCriteriaFrameCounter + 1;
                if stopCriteriaFrameCounter == 2 % wait two frames after stop criteria was fulfilled
                    break;
                end
            else
                stopCriteriaFrameCounter = 0;
            end
        end
        
        % update diagram
        if simConfig.saveDiagrams
            for nodeIdx = 1:size(nodes, 1)
                nodeId = nodes{nodeIdx, 1};
                state = MatlabWrapper(11, pWrapper, nodeId);
                nodes{nodeIdx, 3}.updateOnTimeTic(state, "", globalTime);
            end
        end
        
        % update animation
        if simConfig.showAnimation
            if ~isempty(activeNodes)
                if animation.checkForChanges(activeNodes(:, 2))
                    animation.refresh(globalTime, activeNodes(:, 2));
                end
            end
        end
    end
    
    if simConfig.saveDiagrams
        saveDiagramTicLevel(nodes, simConfig, num2str(simConfig.simIdx));
    end
    
    % validate the results
    disp("==== RESULTS OF SIMULATION =====");
    validationData.globalTime = globalTime;
    results = validateNodeSchedule_mex(activeNodes, nodeConfigs, channel, config, simConfig, validationData, pWrapper, true);
    results.time = globalTime;
end



function saveDiagramTicLevel(nodes, config, simIdx)
    
    if strlength(config.simName) > 0
        simname_prefix = strcat(config.simName + "_");
    else
        simname_prefix = "";
    end
    
    diagram_ticLevel_path = [pwd + "/../timingdiagrams/" + simname_prefix + "timing_diagram_tic_" + simIdx + ".txt"];
    
    for node = 1:size(nodes,1)
        exportLength = size(nodes{node, 3}.statusStructure{1, 1}.globalTimeLineData, 2);
        if exportLength > nodes{node, 3}.exportLengthLimit
            numParts = ceil(exportLength/nodes{node, 3}.exportLengthLimit);
            breakWhenDone = false;

            for i = 1:numParts
                startTime = (i-1) * nodes{node, 3}.exportLengthLimit;
                endTime = i * nodes{node, 3}.exportLengthLimit;

                % put the remainder into one file if it only slightly
                % exceeds the limit or if endTime is bigger than
                % exportLength
                if (exportLength - endTime) <= 100
                    endTime = exportLength - 1;
                    breakWhenDone = true;
                end

                % do not split the diagrams when one node is sending

                % for endTime
                if ~breakWhenDone
                    exitLoop = 0;
                    while (1)
                        for node2 = 1:size(nodes,1)
                            endIdx = find(cell2mat(nodes{node2, 3}.statusStructure{1,1}.globalTimeLineData) == endTime);
                            if strcmp(nodes{node2, 3}.statusStructure{1,1}.statusWave{1, endIdx}, '.') | strcmp(nodes{node2, 3}.statusStructure{1,1}.statusWave{1, endIdx}, '5')
                                endTime = endTime + 1;
                                break;
                            else
                                exitLoop = exitLoop + 1;
                            end
                        end
                        if exitLoop == size(nodes,1)
                            break;
                        else
                           exitLoop = 0;
                        end
                    end
                end

                % for startTime
                exitLoop = 0;
                while (1)
                    for node2 = 1:size(nodes,1)
                        startIdx = find(cell2mat(nodes{node2, 3}.statusStructure{1,1}.globalTimeLineData) == startTime);
                        if strcmp(nodes{node2, 3}.statusStructure{1,1}.statusWave{1, startIdx}, '.') | strcmp(nodes{node2, 3}.statusStructure{1,1}.statusWave{1, startIdx}, '5')
                            startTime = startTime - 1;
                            break;
                        else
                            exitLoop = exitLoop + 1;
                        end
                    end
                    if exitLoop == size(nodes,1)
                        break;
                    else
                       exitLoop = 0;
                    end
                end

                newPath = nodes{node, 3}.insertPartCounterInPath(i, diagram_ticLevel_path);

                if node == 1
                    prependSignalString(newPath);
                end

                structureToExport = nodes{node, 3}.trimTicLevelDiagram(startTime, endTime);
                diagrams{node, 1}.exportData(newPath, structureToExport);

                if node == size(nodes,1)
                    [globalTimeLineTicsWaveString, globalTimeLineTicsDataString] = nodes{node, 3}.getGlobalTimeLineTicLevel(startTime, endTime);
                    appendTimeLineString(newPath, globalTimeLineTicsWaveString, globalTimeLineTicsDataString);
                end

                if breakWhenDone
                    break;
                end
            end
        else
            if node == 1
                prependSignalString(diagram_ticLevel_path);
            end

            structureToExport = nodes{node, 3}.statusStructure{1,1};
            nodes{node, 3}.exportData(diagram_ticLevel_path, structureToExport);

            if node == size(nodes,1)
                [globalTimeLineTicsWaveString, globalTimeLineTicsDataString] = nodes{node, 3}.getGlobalTimeLineTicLevel();
                appendTimeLineString(diagram_ticLevel_path, globalTimeLineTicsWaveString, globalTimeLineTicsDataString);
            end        
        end
    end

end

function saveLogs(nodes, config, simIdx)

    if strlength(config.simName) > 0
        simname_prefix = strcat(config.simName + "_");
    else
        simname_prefix = "";
    end

    % create new folder for the log files
    parentFolder = strcat(pwd, '/../logs/');
    folderName = strcat(simname_prefix, simIdx);
    mkdir(parentFolder, folderName);
    for node = 1:size(nodes,1)
        nodes{node, 1}.logger.saveLogAsCsv([pwd + "/../logs/" + simname_prefix + simIdx + "/_node" + num2str(nodes{node, 1}.id)]);
    end
end

function prependSignalString(path)
    fid = fopen(path,'wt');
    fprintf(fid, '{ "signal" :[\n');
    fclose(fid);
end

function appendTimeLineString(path, globalTimeLineTicsWaveString, globalTimeLineTicsDataString)
    % append time line string
    timePrefix = strcat("{ ""name"": ""Time"", ""wave"": """, globalTimeLineTicsWaveString);
    timeSuffix = """, ""data"":[" + globalTimeLineTicsDataString + "]},";
    timeLineString = strcat(timePrefix, timeSuffix);
    
    fid = fopen(path,'at');
    fprintf(fid, timeLineString + '\n');
    fprintf(fid, '],head:{\ntext:''''},\nfoot:{\ntock:1\n} }\n');
    fclose(fid);
end

