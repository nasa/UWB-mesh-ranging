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

% Batch Simulation Script
% configure multiple simulations via Excel file and run them all

base_path = '/path/to/base/dir/';

useRandomSeedsFromTable = true;
resultsNum = 1;
numNodes = 6;

global collisionsDetectable;
collisionsDetectable = false;

for batchNo = 1:8
    simName = strcat('batch', num2str(batchNo));

    disp(strcat('Starting Batch No.', num2str(batchNo)));

    batch_data_path = strcat(base_path, 'data/results/batch', num2str(batchNo), '_sim_data.xlsx');
    batch_data_table = readtable(batch_data_path);

    node_config_path = strcat(base_path, 'data/results/');
    scenario_config_path = strcat(base_path, 'data/');
    
    gifPath = strcat(base_path, 'animations/');
    
    numSimulations = 10000; %size(batch_data_table, 1);

%     % stats
%     numNetworks = cell(numSimulations, 1);
%     numIsolatedNodes = cell(numSimulations, 1);
%     numNetworkSwitchesPerNode = cell(numSimulations, 1);
%     numOwnSlotsGivenUpPerNode = cell(numSimulations, 1);
%     numPendingSlotsGivenUpPerNode = cell(numSimulations, 1);
%     numReservedSlotPerNodePerFrame = cell(numSimulations, 1);
%     topologyChanges = cell(numSimulations, 1);
%     numNodeGroups = cell(numSimulations, 1);
% 
%     resultsTableColumnSim = zeros(numSimulations, 1);
%     resultsTableColumnStatus = cell(numSimulations, 1);
%     resultsTableColumnTime = zeros(numSimulations, 1);
%     resultsTableColumnInfo = cell(numSimulations, 1);
    
    configs = cell(numSimulations, 1);
    
    addpath(strcat(base_path, '3rdparty'));

    % generate the random seeds
    % initialize the random number generator with the current time (this
    % only sets the random seed to later generate individual random
    % numbers per simulation)
    posixTimeStamp = int32(posixtime(datetime()));
    rng(posixTimeStamp, 'Threefry');

    if useRandomSeedsFromTable
       resultsSheet = readtable(batch_data_path, 'Sheet', ["Results" + num2str(resultsNum)]);
       randomSeeds = resultsSheet.randomSeeds;
    else
        randomSeeds = randi(intmax, numSimulations, 1);
    end
    % to prevent memory from leaking, don't run all simulations at once in the
    % same parpool; instead, create a new parpool to free memory after a
    % certain number of simulations
    
    simulationsPerPool = 10000;
    numPools = ceil(numSimulations/simulationsPerPool);
    
    tic
    for poolbatch = 0:(numPools - 1)
    
        % create parallel pool
        poolobj = parpool;
        
        startIdx = 1 + poolbatch * simulationsPerPool;
        endIdx = simulationsPerPool + poolbatch * simulationsPerPool;
        if endIdx > numSimulations
            endIdx = numSimulations;
        end
    
        % construct parfor progress bar to keep track of the progress
        ppm = ParforProgressbar(endIdx - startIdx, 'showWorkerProgress', true);

        parfor simIdx = startIdx:endIdx
            configIdx = 1; % in mex batch processing, the settings must be set in the C code, so only one line in the xls-file is needed
            close all;
            
            % initialize the random number generator
            rng(randomSeeds(simIdx, 1), 'Threefry');

            disp(strcat("Simulation ", num2str(simIdx), " seed: ", num2str(randomSeeds(simIdx, 1))));
            node_configs = load(strcat(node_config_path, batch_data_table.node_config{configIdx})).node_configs;
            
            % configure the simulation based on config data:
%             numNodes = batch_data_table.num_nodes(simIdx);
            configs{simIdx}.numNodes = numNodes;

            configs{simIdx}.createStatistics = false;
            configs{simIdx}.showAnimation = false;
            configs{simIdx}.saveAnimation = false;
            configs{simIdx}.saveDiagrams = false;
            configs{simIdx}.verbose = false;
            configs{simIdx}.replay = false;
            configs{simIdx}.ticsPerMillisecond = 10;
            configs{simIdx}.CADRE = false;

            configs{simIdx}.simName = simName;
            configs{simIdx}.simIdx = simIdx;
            
%             % create scenario
%             sc_times = {};
%             sc_paths = {};
%             if ~isnan(batch_data_table.scenario_times(simIdx))
%                 if size(batch_data_table.scenario_times{simIdx}, 2) > 0 & size(batch_data_table.scenario_paths{simIdx}, 2) > 0
%                     out = regexp(batch_data_table.scenario_times{simIdx}, ',', 'split');
%                     sc_times = num2cell(cellfun(@str2num, out));
%                     sc_paths = regexp(batch_data_table.scenario_paths{simIdx}, ',', 'split');
%                 end
%             end
%             scenario = Scenario(sc_times, strcat(scenario_config_path, sc_paths));
            
            % initialize the MatlabWrapper
            pWrapper = MatlabWrapper(1, randomSeeds(simIdx, 1));

            channel = CommunicationChannel_mex(pWrapper);

            % do not simulate if not every node has a config
            if numNodes ~= size(node_configs, 1)
                warning('config not provided for every node');
                resultsVector(simIdx, 1) = 0;
                continue;
            end
            
            % create nodes
            nodes = {};
            diagrams = {};
            for i = 1:numNodes
                nodeConfig = node_configs{i, 1};
                    
                nodeId = i;

                % create node
                nodes{end + 1, 1} = MatlabWrapper(2, pWrapper, nodeId);
        
                % choose random values for fields that were specified by a range
                configFields = fields(nodeConfig);
                for fieldIdx = 1:size(configFields, 1)
                    % if it is time related, multiply by tics per ms (as the value
                    % is in tics)
                    if strcmp(configFields{fieldIdx}, 'enterTime') | ...
                        strcmp(configFields{fieldIdx}, 'leaveTime') | ...
                         strcmp(configFields{fieldIdx}, 'trajectoryStartTime') | ...
                          strcmp(configFields{fieldIdx}, 'movementTimes')
                        multiplier = configs{simIdx}.ticsPerMillisecond;
                    else
                        multiplier = 1;
                    end
                    if iscell(nodeConfig.(configFields{fieldIdx}))
                        randomlyChosenValue = randi([nodeConfig.(configFields{fieldIdx}){1,1}*multiplier nodeConfig.(configFields{fieldIdx}){1,2}*multiplier]);
                    else
                        randomlyChosenValue = nodeConfig.(configFields{fieldIdx})*multiplier;
                    end
                    nodeConfig.(configFields{fieldIdx}) = randomlyChosenValue;
                    if strcmp(configFields{fieldIdx}, 'samplePoints')
                        % use one sample point per meter distance
                        nodeConfig.(configFields{fieldIdx}) = nodeConfig.travelDistance;
                    end
                end
                
                % set position
                nodes{end, 2} = struct('x', nodeConfig.x, 'y', nodeConfig.y);

                % add diagram
                individualConfig = MatlabWrapper(14, pWrapper, nodes{end, 1});
                nodes{end, 3} = Diagram_mex(nodeId, pWrapper, individualConfig);

                % generate a random trajectory if configured
                if nodeConfig.trajectoryStartTime < nodeConfig.enterTime
                    nodeConfig.trajectoryStartTime = nodeConfig.enterTime;
                end
                
                xStart = nodeConfig.x;
                yStart = nodeConfig.y;
                startTime = nodeConfig.trajectoryStartTime;
                velocity = nodeConfig.velocity;
                xlimits = nodeConfig.xlimits;
                ylimits = nodeConfig.ylimits;
                distance = nodeConfig.travelDistance;
                maxSteeringAngle = nodeConfig.maxSteering;
                samplePoints = nodeConfig.samplePoints;
                
                if ~isempty(startTime)
                    [times, movementsX, movementsY] = generateTrajectory(xStart, yStart, startTime, velocity, xlimits, ylimits, distance, maxSteeringAngle, samplePoints, configs{simIdx}.ticsPerMillisecond);
%                     % save the start coordinates
%                     writematrix(xStart, strcat(base_path, 'data/trajectories/startcoords/', 'xstart_', simName, '_idx', num2str(simIdx), '_n', num2str(i), '.csv'));
%                     writematrix(yStart, strcat(base_path, 'data/trajectories/startcoords/', 'ystart_', simName, '_idx', num2str(simIdx), '_n', num2str(i), '.csv'));
    
                    if ~isempty(times)
                        nodeConfig.movementTimes = times;
                        nodeConfig.movementsX = movementsX;
                        nodeConfig.movementsY = movementsY;
                        
                        % not to be cleared so can be used by checkStopCriteria 
                        nodeConfig.movementTimesPersistent = times;
                        
%                         % save the trajectory
%                         writematrix(movementsX, strcat(base_path, 'data/trajectories/', 'xtraj_', simName, '_idx', num2str(simIdx), '_n', num2str(i), '.csv'));
%                         writematrix(movementsY, strcat(base_path, 'data/trajectories/', 'ytraj_', simName, '_idx', num2str(simIdx), '_n', num2str(i), '.csv'));
                    end
                else
                    nodeConfig.movementTimesPersistent = nodeConfig.movementTimes;
                end
            end
            
            % no animation in batch
            animation = [];
            
            % start the simulation
            disp(strcat('Starting Simulation #',  num2str(simIdx)))
            results = run_protocol_sim_mex(pWrapper, nodes, node_configs, configs{simIdx}, channel, animation);
        
            % record results
            resultsTableColumnSim(simIdx, 1) = simIdx;
            if results.passed
                resultsTableColumnStatus(simIdx, 1) = {"PASS"};
            else
                resultsTableColumnStatus(simIdx, 1) = {"FAIL"};
            end
            resultsTableColumnTime(simIdx, 1) = results.time;
            resultsTableColumnInfo(simIdx, 1) = {results.info};

%             % save statistics
%             networkIds = [];
%             for i = 1:size(nodes, 1)
%                 netId = nodes{i, 1}.netManager.getNetworkId();
%                 if ~isempty(netId)
%                     networkIds = [networkIds, netId];
%                 else
%                     networkIds = [networkIds, nodes{i, 1}.id];
%                 end
%             end
%             numNetworks{simIdx, 1} = size(unique(networkIds), 2);
%             numIsolatedNodes{simIdx, 1} = results.numIsolatedNodes;
%             topologyChanges{simIdx, 1} = wrapper.topologyChanges;
%             numNetworkSwitchesPerNode{simIdx, 1} = cellfun(@(c) c.netManager.numNetworkJoins, nodes);
%             numOwnSlotsGivenUpPerNode{simIdx, 1} = cellfun(@(c) c.slotMap.numOwnSlotsGivenUp, nodes);
%             numPendingSlotsGivenUpPerNode{simIdx, 1} = cellfun(@(c) c.slotMap.numPendingSlotsGivenUp, nodes);
%             numReservedSlotPerNodePerFrame{simIdx, 1} = results.numSlots;
%             numNodeGroups{simIdx, 1} = results.nodegroups;

            % update progress bar
            ppm.increment();
        
            close all;
        end
    
        % delete progress bar
        delete(ppm);
        
        % delete parpool to free memory
        delete(poolobj);
    
    end
    toc
        
    % create the results table
    resultsTable = table(resultsTableColumnSim, resultsTableColumnStatus, resultsTableColumnTime, resultsTableColumnInfo, randomSeeds);
    % write it to the batch data spreadsheet
    writetable(resultsTable, batch_data_path, 'Sheet', ["Results" + num2str(resultsNum)]);

%     % save stats 
%     stats = struct;
%     stats.numNetworks = numNetworks;
%     stats.numIsolatedNodes = numIsolatedNodes;
%     stats.topologyChanges = topologyChanges;
%     stats.numNetworkSwitchesPerNode = numNetworkSwitchesPerNode;
%     stats.numOwnSlotsGivenUpPerNode = numOwnSlotsGivenUpPerNode;
%     stats.numPendingSlotsGivenUpPerNode = numPendingSlotsGivenUpPerNode;
%     stats.numReservedSlotPerNodePerFrame = numReservedSlotPerNodePerFrame;
%     stats.numNodeGroups = numNodeGroups;
% 
%     statsFilename = strcat(base_path,'data/batch', num2str(batchNo), 'stats.mat');
%     save(statsFilename, 'stats');
end