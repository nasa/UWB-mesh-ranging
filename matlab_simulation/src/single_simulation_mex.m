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

% Single simulation using MEX
clear all;
close all;

global collisionsDetectable;
collisionsDetectable = false;

base_path = '/path/to/base/dir';

batchNo = 1;
simIdx = 1;
randomSeed = 1605185814;
numNodes = 4; %batch_data_table.num_nodes(simIdx);

global nodeTimes;
nodeTimes = zeros(361000, numNodes);


configIdx = 1; % in mex batch processing, the settings must be set in the C code, so only one line in the xls-file is needed

rng(randomSeed, 'Threefry');

simName = strcat('batch', num2str(batchNo));

batch_data_path = strcat(base_path, 'data/batch', num2str(batchNo), '_sim_data.xlsx');
batch_data_table = readtable(batch_data_path);

node_config_path = strcat(base_path, ['' ...
'data/']);

gifPath = strcat(base_path, 'animations/');

% load configs
node_configs = load(strcat(node_config_path, batch_data_table.node_config{configIdx})).node_configs;

configs.numNodes = numNodes;

configs.createStatistics = false;
configs.showAnimation = false;
configs.saveAnimation = false;
configs.saveDiagrams = false;
configs.verbose = false;
configs.replay = false;
configs.ticsPerMillisecond = 10;
configs.CADRE = false;

configs.simName = simName;
configs.simIdx = simIdx;

% initialize the MatlabWrapper
pWrapper = MatlabWrapper(1, randomSeed);

% create communication channel
channel = CommunicationChannel_mex(pWrapper);

% create the nodes
nodes = {};

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
    
    % set position
    nodes{end, 2} = struct('x', nodeConfig.x, 'y', nodeConfig.y);
    
    % add diagram
    individualConfig = MatlabWrapper(14, pWrapper, nodes{end, 1});
    nodes{end, 3} = Diagram_mex(nodeId, pWrapper, individualConfig);
    
    % generate trajectory if configured
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

            % not to be cleared so can be used by checkStopCriteria 
            nodeConfig.movementTimesPersistent = times;
    %         % save the trajectory
    %         writematrix(movementsX, strcat(base_path, 'data/trajectories/', 'xtraj_', simName, '_idx', num2str(simIdx), '.csv'));
    %         writematrix(movementsY, strcat(base_path, 'data/trajectories/', 'ytraj_', simName, '_idx', num2str(simIdx), '.csv'));
        end
    else
        nodeConfig.movementTimesPersistent = nodeConfig.movementTimes;
    end
end

% create animation
if configs.showAnimation
    gifName = strcat(gifPath, "animation_", configs.simName, "_", num2str(configs.simIdx), ".gif");
    individualConfig = MatlabWrapper(14, pWrapper, nodes{1,1});
    animation = Animation_mex(gifName, configs, individualConfig, nodes, channel, pWrapper);
else
    animation = [];
end


% start the simulation
tic
result = run_protocol_sim_mex(pWrapper, nodes, node_configs, configs, channel, animation);
toc
a=1;