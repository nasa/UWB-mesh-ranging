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

% Single Simulation Script

base_path = '/path/to/base/dir';

batchNo = 1;
simIdx = 1;
randomSeed = 6537851;

simName = strcat('batch', num2str(batchNo));

disp(strcat('Starting Batch No.', num2str(batchNo)));

batch_data_path = strcat(base_path, 'data/batch', num2str(batchNo), '_sim_data.xlsx');
batch_data_table = readtable(batch_data_path);

node_config_path = strcat(base_path, ['' ...
    'data/']);
scenario_config_path = strcat(base_path, 'data/');

gifPath = strcat(base_path, 'animations/');

numSimulations = size(batch_data_table, 1);

resultsTableColumnSim = zeros(numSimulations, 1);
resultsTableColumnStatus = cell(numSimulations, 1);
resultsTableColumnTime = zeros(numSimulations, 1);
resultsTableColumnInfo = cell(numSimulations, 1);
resultsTableColumnRandomSeed = zeros(numSimulations, 1);

addpath(strcat(base_path, '3rdparty'));

tic
close all;

rng(randomSeed, 'Threefry');

node_configs = load(strcat(node_config_path, batch_data_table.node_config{simIdx})).node_configs;
% configure the simulation based on config data:
numNodes = batch_data_table.num_nodes(simIdx);
configs.numNodes = numNodes;
configs.slotGoal = batch_data_table.slots_to_reserve(simIdx);
configs.ticsPerMillisecond = batch_data_table.tics_per_ms(simIdx);
configs.initialWaitTime = batch_data_table.wait_time_after_boot(simIdx) * configs.ticsPerMillisecond;
configs.initialPingUpperLimit = batch_data_table.first_ping_upper_limit(simIdx) * configs.ticsPerMillisecond;
configs.frameLength = batch_data_table.frame_length(simIdx) * configs.ticsPerMillisecond;
configs.slotsPerFrame = batch_data_table.slots_per_frame(simIdx);
configs.slotLength = configs.frameLength/configs.slotsPerFrame;
configs.dutyCycle = batch_data_table.duty_cycle(simIdx);

configs.guardPeriodLength = 5;
configs.slotExpirationTimeout = configs.frameLength + configs.slotLength;
configs.ownSlotExpirationTimeout = 2 * configs.frameLength;
configs.occupiedSlotTimeoutMultiHop = configs.frameLength + configs.slotLength;
configs.occupiedSlotTimeout = 2 * configs.frameLength;
configs.collidingSlotTimeout = configs.slotLength;
configs.collidingSlotTimeoutMultiHop = configs.frameLength;
configs.absentNeighborTimeout = 1.5 * configs.frameLength;
configs.tofErrorMargin = 2;

configs.autoDutyCycle = 0; % num of frames to idle
configs.signalRange = batch_data_table.signal_range(simIdx);
configs.collisionDetection = batch_data_table.collisions_detectable; % if false, assume collisions cannot be detected

configs.createStatistics = false;
configs.showAnimation = false;
configs.saveAnimation = false;
configs.saveDiagrams = true;
configs.verbose = false;
configs.replay = false;

configs.simName = simName;
configs.simIdx = simIdx;

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
            multiplier = configs.ticsPerMillisecond;
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
        [times, movementsX, movementsY] = generateTrajectory(xStart, yStart, startTime, velocity, xlimits, ylimits, distance, maxSteeringAngle, samplePoints, configs.ticsPerMillisecond);
        if ~isempty(times)
            nodeConfig.movementTimes = times;
            nodeConfig.movementsX = movementsX;
            nodeConfig.movementsY = movementsY;
        
%         % save the trajectory
%         writematrix(movementsX, strcat(base_path, 'data/trajectories/', 'xtraj_', simName, '_idx', num2str(simIdx), '.csv'));
%         writematrix(movementsY, strcat(base_path, 'data/trajectories/', 'ytraj_', simName, '_idx', num2str(simIdx), '.csv'));
        end
    end

    clock = HALClock();
    timeKeeping = TimeKeeping(clock, configs);
    randomNumbers = RandomNumbers();
    slotMap = SlotMap(configs, randomNumbers);
    scheduler = Scheduler(clock, timeKeeping, randomNumbers, slotMap, configs);
    driverAbstraction = DriverAbstractionLayer(channel, globalClock, timeKeeping);
    networkManager = NetworkManager();
    neighborhood = Neighborhood();
    diagram = Diagram(slotMap, timeKeeping, networkManager, configs.slotLength);
    diagrams{end + 1, 1} = diagram;
    messageHandler = MessageHandler(networkManager, timeKeeping, scheduler, slotMap, driverAbstraction, clock, neighborhood);
    rangingManager = RangingManager(clock);
    stateActions = StateActions(scheduler, timeKeeping, messageHandler, slotMap, clock, rangingManager, neighborhood, configs);
    guardConditions = GuardConditions(slotMap, networkManager, timeKeeping, messageHandler, clock, scheduler, driverAbstraction, neighborhood, configs);
    stateMachine = StateMachine(slotMap, scheduler, guardConditions, driverAbstraction, timeKeeping, stateActions, rangingManager);

    nodes{end + 1, 1} = Node(configs, nodeConfig, stateMachine, slotMap, networkManager, channel, clock, messageHandler, timeKeeping, driverAbstraction);
end

if configs.showAnimation
    gifName = strcat(gifPath, "animation_", simName, "_", num2str(simIdx), ".gif");
    animation = Animation(gifName, configs, globalClock);
else
    animation = [];
end

wrapper = NodeWrapper(nodes, channel, configs, scenario, animation, diagrams, globalClock);

% start the simulation
disp(strcat('Starting Simulation #',  num2str(simIdx)))
% tic
results = run_protocol_sim(wrapper, globalClock, configs, scenario, simIdx);
% toc
% record results
resultsTableColumnSim(simIdx, 1) = simIdx;
if results.passed
    resultsTableColumnStatus(simIdx, 1) = {"PASS"};
else
    resultsTableColumnStatus(simIdx, 1) = {"FAIL"};
end
resultsTableColumnTime(simIdx, 1) = results.time;
resultsTableColumnInfo(simIdx, 1) = {results.info};
resultsTableColumnRandomSeed(simIdx, 1) = randomSeed;

% % save statistics
% networkIds = [];
% for i = 1:size(nodes, 1)
%     netId = nodes{i, 1}.networkManager.getNetworkId();
%     if ~isempty(netId)
%         networkIds = [networkIds, netId];
%     end
% end
% numNetworks{simIdx, 1} = size(unique(networkIds), 2);numIsolatedNodes = results.numIsolatedNodes;
% numOwnSlotsGivenUpPerNode = cellfun(@(c) c.slotMap.numOwnSlotsGivenUp, nodes);
% numPendingSlotsGivenUpPerNode = cellfun(@(c) c.slotMap.numPendingSlotsGivenUp, nodes);
% topologyChanges = wrapper.topologyChanges;
% numNetworkSwitchesPerNode = cellfun(@(c) c.netManager.numNetworkJoins, nodes);
% numReservedSlotPerNodePerFrame = results.numSlots;

% reset the node IDs (by calling the function with any inputs)
StateMachine.getNewId(0);
toc
    
% create the results table
resultsTable = table(resultsTableColumnSim, resultsTableColumnStatus, resultsTableColumnTime, resultsTableColumnInfo, resultsTableColumnRandomSeed);

% % write it to the batch data spreadsheet
% writetable(resultsTable, batch_data_path, 'Sheet', 'Results');
