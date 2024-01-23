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

useRandomSeedsFromTable = false;

for batchNo = 8:9
    simName = strcat('batch', num2str(batchNo));

    disp(strcat('Starting Batch No.', num2str(batchNo)));

    batch_data_path = strcat(base_path, 'data/batch', num2str(batchNo), '_sim_data_400.xlsx');
    batch_data_table = readtable(batch_data_path);

    node_config_path = strcat(base_path, 'data/');
    scenario_config_path = strcat(base_path, 'data/');
    
    gifPath = strcat(base_path, 'animations/');
    
    numSimulations = size(batch_data_table, 1);

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
    % initialize the random number generator with the current time
    posixTimeStamp = int32(posixtime(datetime()));
    rng(posixTimeStamp, 'Threefry');

    if useRandomSeedsFromTable
       resultsSheet = readtable(batch_data_path, 'Sheet', 'Results');
       randomSeeds = resultsSheet.randomSeeds;
    else
        randomSeeds = randi(intmax, numSimulations, 1);
    end
    % to prevent memory from leaking, don't run all simulations at once in the
    % same parpool; instead, create a new parpool to free memory after a
    % certain number of simulations
    
    simulationsPerPool = 60;
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
            close all;
            
            % initialize the random number generator
            rng(randomSeeds(simIdx, 1), 'Threefry');

            disp(strcat("Simulation ", num2str(simIdx), " seed: ", num2str(randomSeeds(simIdx, 1))));
            node_configs = load(strcat(node_config_path, batch_data_table.node_config{simIdx})).node_configs;
            % configure the simulation based on config data:
            numNodes = batch_data_table.num_nodes(simIdx);
            configs{simIdx}.numNodes = numNodes;
            configs{simIdx}.slotGoal = batch_data_table.slots_to_reserve(simIdx);
            configs{simIdx}.ticsPerMillisecond = batch_data_table.tics_per_ms(simIdx);
            configs{simIdx}.initialWaitTime = batch_data_table.wait_time_after_boot(simIdx) * configs{simIdx}.ticsPerMillisecond;
            configs{simIdx}.initialPingUpperLimit = batch_data_table.first_ping_upper_limit(simIdx) * configs{simIdx}.ticsPerMillisecond;
            configs{simIdx}.frameLength = batch_data_table.frame_length(simIdx) * configs{simIdx}.ticsPerMillisecond;
            configs{simIdx}.slotsPerFrame = batch_data_table.slots_per_frame(simIdx);
            configs{simIdx}.slotLength = configs{simIdx}.frameLength/configs{simIdx}.slotsPerFrame;
            configs{simIdx}.dutyCycle = batch_data_table.duty_cycle(simIdx);
            
            configs{simIdx}.guardPeriodLength = 5;
            configs{simIdx}.slotExpirationTimeout = configs{simIdx}.frameLength + configs{simIdx}.slotLength;
            configs{simIdx}.ownSlotExpirationTimeout = 2 * configs{simIdx}.frameLength;
            configs{simIdx}.occupiedSlotTimeoutMultiHop = configs{simIdx}.frameLength + configs{simIdx}.slotLength;
            configs{simIdx}.occupiedSlotTimeout = 2 * configs{simIdx}.frameLength;
            configs{simIdx}.collidingSlotTimeout = configs{simIdx}.slotLength;
            configs{simIdx}.collidingSlotTimeoutMultiHop = configs{simIdx}.frameLength;
            configs{simIdx}.absentNeighborTimeout = 1.5 * configs{simIdx}.frameLength;
            configs{simIdx}.tofErrorMargin = 2;
            
            configs{simIdx}.autoDutyCycle = 1;
            configs{simIdx}.signalRange = batch_data_table.signal_range(simIdx);
            configs{simIdx}.collisionDetection = batch_data_table.collisions_detectable; % if false, assume collisions cannot be detected
            
            configs{simIdx}.createStatistics = false;
            configs{simIdx}.showAnimation = false;
            configs{simIdx}.saveAnimation = false;
            configs{simIdx}.saveDiagrams = false;
            configs{simIdx}.verbose = false;
            configs{simIdx}.replay = false;
            
            configs{simIdx}.simName = simName;
            configs{simIdx}.simIdx = simIdx;
        
            % create scenario
            sc_times = {};
            sc_paths = {};
            if ~isnan(batch_data_table.scenario_times(simIdx))
                if size(batch_data_table.scenario_times{simIdx}, 2) > 0 & size(batch_data_table.scenario_paths{simIdx}, 2) > 0
                    out = regexp(batch_data_table.scenario_times{simIdx}, ',', 'split');
                    sc_times = num2cell(cellfun(@str2num, out));
                    sc_paths = regexp(batch_data_table.scenario_paths{simIdx}, ',', 'split');
                end
            end
            scenario = Scenario(sc_times, strcat(scenario_config_path, sc_paths));
            
            channel = CommunicationChannel();
            globalClock = GlobalClock();        

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
                        
%                         % save the trajectory
%                         writematrix(movementsX, strcat(base_path, 'data/trajectories/', 'xtraj_', simName, '_idx', num2str(simIdx), '_n', num2str(i), '.csv'));
%                         writematrix(movementsY, strcat(base_path, 'data/trajectories/', 'ytraj_', simName, '_idx', num2str(simIdx), '_n', num2str(i), '.csv'));
                    end
                end

        
                clock = HALClock();
                timeKeeping = TimeKeeping(clock, configs{simIdx});
                randomNumbers = RandomNumbers();
                slotMap = SlotMap(configs{simIdx}, randomNumbers);
                scheduler = Scheduler(clock, timeKeeping, randomNumbers, slotMap, configs{simIdx});
                driverAbstraction = DriverAbstractionLayer(channel, globalClock, timeKeeping);
                networkManager = NetworkManager();
                neighborhood = Neighborhood();
                messageHandler = MessageHandler(networkManager, timeKeeping, scheduler, slotMap, driverAbstraction, clock, neighborhood);
                rangingManager = RangingManager(clock);
                stateActions = StateActions(scheduler, timeKeeping, messageHandler, slotMap, clock, rangingManager, neighborhood, configs{simIdx});
                guardConditions = GuardConditions(slotMap, networkManager, timeKeeping, messageHandler, clock, scheduler, driverAbstraction, configs{simIdx});
                stateMachine = StateMachine(scheduler, guardConditions, driverAbstraction, timeKeeping, stateActions, rangingManager);
            
                nodes{end + 1, 1} = Node(configs{simIdx}, nodeConfig, stateMachine, slotMap, networkManager, channel, clock, messageHandler, timeKeeping, driverAbstraction);
            end

            if configs{simIdx}.showAnimation
                gifName = strcat(gifPath, "animation_", simName, "_", num2str(simIdx), ".gif");
                animation = Animation(gifName, configs{simIdx});
            else
                animation = [];
            end

            wrapper = NodeWrapper(nodes, channel, configs{simIdx}, scenario, animation, globalClock);
            
            % start the simulation
            disp(strcat('Starting Simulation #',  num2str(simIdx)))
            results = run_protocol_sim(wrapper, globalClock, configs{simIdx}, scenario, simIdx);
        
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
        
            % reset the node IDs (by calling the function with any inputs)
            StateMachine.getNewId(0);
        
            % clear variables to free memory
            animation = [];
            wrapper = [];
            diagrams = [];
            nodes = [];
            results = [];
            gateway = [];
            logger = [];
            medium = [];
            netManager = [];
            neighborhood = [];
            scheduler = [];
            slotMap = [];
            time = [];
        
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
    writetable(resultsTable, batch_data_path, 'Sheet', 'Results');

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