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

function results = run_protocol_sim(wrapper, globalClock, config, scenario, simIdx)

    global collisionReports;
    collisionReports = 0;
    num_slots = [];

    % start the discrete simulation
    while true 
        globalTime = globalClock.getGlobalTime();

        % initialize nodes that are active at this time
        wrapper.initializeNodes();
        
        % run wrapper
        wrapper.runWrapper();
        
        activeNodes = wrapper.getActiveNodes();
        
        % count slots once per frame:
        if size(activeNodes, 1)
            
            if mod(globalTime, config.frameLength) == mod(activeNodes{1,1}.getFrameStartTime(), config.frameLength)
                num_slots(end+1, :) = zeros(size(activeNodes, 2));
                for i = 1:size(activeNodes, 1)
                    num_slots(end, i) = size(activeNodes{i, 1}.getOwnSlots(), 2);
                end

                nodes = wrapper.getNodes();
                times =  []; %scenario.getManipulationTimes();
                if checkStopCriteria(globalTime, activeNodes, nodes, config, times)
                    break;
                end
            end
        end
        
        % increment globalTime
        globalClock.incrementGlobalTime();
    end
    
    
    %% save logs and diagram    
    nodes = wrapper.getNodes();

    if config.saveDiagrams
%         saveLogs(wrapper, config, num2str(simIdx));
        saveDiagramTicLevel(wrapper, config, num2str(simIdx));
    end
    
    %% plot results
    if config.verbose
        figure;
    
        for i = 1:size(num_slots, 2)
            plot(linspace(1, size(num_slots, 1), size(num_slots, 1)), config.slotGoal - num_slots(:, i));
            hold on;
        end
        grid on;
        ylabel('residual slots');
        xlabel('frame #');
    end
    
    %% validate the simulation results
    disp("==== RESULTS OF SIMULATION =====");
    results = validateNodeSchedule(nodes, config, true);
    results.numSlots = num_slots;
    results.time = globalTime;
end

function saveDiagramTicLevel(wrapper, config, simIdx)
    nodes = wrapper.getNodes();
    diagrams = wrapper.getDiagrams();
    
    if strlength(config.simName) > 0
        simname_prefix = strcat(config.simName + "_");
    else
        simname_prefix = "";
    end
    
    diagram_ticLevel_path = [pwd + "/../timingdiagrams/" + simname_prefix + "timing_diagram_tic_" + simIdx + ".txt"];
    
    for node = 1:size(nodes,1)
        exportLength = size(diagrams{node, 1}.statusStructure{1, 1}.globalTimeLineData, 2);
        if exportLength > diagrams{node, 1}.exportLengthLimit
            numParts = ceil(exportLength/diagrams{node, 1}.exportLengthLimit);
            breakWhenDone = false;

            for i = 1:numParts
                startTime = (i-1) * diagrams{node, 1}.exportLengthLimit;
                endTime = i * diagrams{node, 1}.exportLengthLimit;

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
                            endIdx = find(cell2mat(diagrams{node2, 1}.statusStructure{1,1}.globalTimeLineData) == endTime);
                            if strcmp(diagrams{node2, 1}.statusStructure{1,1}.statusWave{1, endIdx}, '.') | strcmp(diagrams{node2, 1}.statusStructure{1,1}.statusWave{1, endIdx}, '5')
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
                        startIdx = find(cell2mat(diagrams{node2, 1}.statusStructure{1,1}.globalTimeLineData) == startTime);
                        if strcmp(diagrams{node2, 1}.statusStructure{1,1}.statusWave{1, startIdx}, '.') | strcmp(diagrams{node2, 1}.statusStructure{1,1}.statusWave{1, startIdx}, '5')
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

                newPath = diagrams{node, 1}.insertPartCounterInPath(i, diagram_ticLevel_path);

                if node == 1
                    prependSignalString(newPath);
                end

                structureToExport = diagrams{node, 1}.trimTicLevelDiagram(startTime, endTime);
                diagrams{node, 1}.exportData(newPath, structureToExport);

                if node == size(nodes,1)
                    [globalTimeLineTicsWaveString, globalTimeLineTicsDataString] = diagrams{node, 1}.getGlobalTimeLineTicLevel(startTime, endTime);
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

            structureToExport = diagrams{node, 1}.statusStructure{1,1};
            diagrams{node, 1}.exportData(diagram_ticLevel_path, structureToExport);

            if node == size(nodes,1)
                [globalTimeLineTicsWaveString, globalTimeLineTicsDataString] = diagrams{node, 1}.getGlobalTimeLineTicLevel();
                appendTimeLineString(diagram_ticLevel_path, globalTimeLineTicsWaveString, globalTimeLineTicsDataString);
            end        
        end
    end

end

function saveLogs(wrapper, config, simIdx)
    nodes = wrapper.getNodes();

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

