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

%% create configs script
% run sections individually and save resulting structures to .mat-files, so they can be
% used later

%% Test 1: 4 Nodes, all in range, no movement, simultaneous wakeup
node_configs = {};

% Node 1
config = NodeConfig();
config.x = 0;
config.y = 0;
node_configs{end+1, 1} = config;

% Node 2
config = NodeConfig();
config.x = 40;
config.y = 0;
node_configs{end+1, 1} = config;

% Node 3
config = NodeConfig();
config.x = 40;
config.y = 40;
node_configs{end+1, 1} = config;

% Node 4
config = NodeConfig();
config.x = 0;
config.y = 40;
node_configs{end+1, 1} = config;

%% Test 2: 4 Nodes, all in range, no movement, random wakeup
node_configs = {};

% Node 1
config = NodeConfig();
config.x = 0;
config.y = 0;
config.enterTime = {0, 1000};
node_configs{end+1, 1} = config;

% Node 2
config = NodeConfig();
config.x = 40;
config.y = 0;
config.enterTime = {0, 1000};
node_configs{end+1, 1} = config;

% Node 3
config = NodeConfig();
config.x = 40;
config.y = 40;
config.enterTime = {0, 1000};
node_configs{end+1, 1} = config;

% Node 4
config = NodeConfig();
config.x = 0;
config.y = 40;
config.enterTime = {0, 1000};
node_configs{end+1, 1} = config;

%% Test 3: 4 Nodes, random location, no movement, simultaneous wakeup
node_configs = {};

% Node 1
config = NodeConfig();
node_configs{end+1, 1} = config;

% Node 2
config = NodeConfig();
node_configs{end+1, 1} = config;

% Node 3
config = NodeConfig();
node_configs{end+1, 1} = config;

% Node 4
config = NodeConfig();
node_configs{end+1, 1} = config;

%% Test 4: 4 Nodes, random location, no movement, random wakeup
node_configs = {};

% Node 1
config = NodeConfig();
config.enterTime = {0, 1000};
node_configs{end+1, 1} = config;

% Node 2
config = NodeConfig();
config.enterTime = {0, 1000};
node_configs{end+1, 1} = config;

% Node 3
config = NodeConfig();
config.enterTime = {0, 1000};
node_configs{end+1, 1} = config;

% Node 4
config = NodeConfig();
config.enterTime = {0, 1000};
node_configs{end+1, 1} = config;

%% Test 5: 4 Nodes, random location, semi-random trajectory, simultaneous wakeup
% trajectory start time is random
% velocity is fixed
% travel distance is random between 0 and 100
% max steering angle is fixed
% number of sampling points is equal to distance traveled, so the node
% moves in "jumps" of 1m
node_configs = {};

% Node 1
config = NodeConfig();
config.trajectoryStartTime = {0, 1000};
config.velocity = 25;
config.travelDistance = {0, 200};
config.maxSteering = 20;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 2
config = NodeConfig();
config.trajectoryStartTime = {0, 1000};
config.velocity = 25;
config.travelDistance = {0, 200};
config.maxSteering = 20;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 3
config = NodeConfig();
config.trajectoryStartTime = {0, 1000};
config.velocity = 25;
config.travelDistance = {0, 200};
config.maxSteering = 20;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 4
config = NodeConfig();
config.trajectoryStartTime = {0, 1000};
config.velocity = 25;
config.travelDistance = {0, 200};
config.maxSteering = 20;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

%% Test 6: 6 Nodes in two groups, simultaneous wakeup, merging after initialization could be complete
node_configs = {};

% Node 1
config = NodeConfig();
config.x = -50;
config.y = 0;
node_configs{end+1, 1} = config;

% Node 2
config = NodeConfig();
config.x = -50;
config.y = 30;
node_configs{end+1, 1} = config;

% Node 3
config = NodeConfig();
config.x = -50;
config.y = 60;
node_configs{end+1, 1} = config;

% Node 4
config = NodeConfig();
config.x = 60;
config.y = 0;
config.movementTimes = [960];
config.movementsX = [-70];
config.movementsY = [0];
node_configs{end+1, 1} = config;

% Node 5
config = NodeConfig();
config.x = 60;
config.y = 30;
config.movementTimes = [960];
config.movementsX = [-70];
config.movementsY = [0];
node_configs{end+1, 1} = config;

% Node 6
config = NodeConfig();
config.x = 60;
config.y = 60;
config.movementTimes = [960];
config.movementsX = [-70];
config.movementsY = [0];
node_configs{end+1, 1} = config;

%% Test 7: 6 Nodes in two groups, simultaneous wakeup, early merging when initialization is probably not complete
node_configs = {};

% Node 1
config = NodeConfig();
config.x = -50;
config.y = 0;
node_configs{end+1, 1} = config;

% Node 2
config = NodeConfig();
config.x = -50;
config.y = 30;
node_configs{end+1, 1} = config;

% Node 3
config = NodeConfig();
config.x = -50;
config.y = 60;
node_configs{end+1, 1} = config;

% Node 4
config = NodeConfig();
config.x = 60;
config.y = 0;
config.movementTimes = [500];
config.movementsX = [-70];
config.movementsY = [0];
node_configs{end+1, 1} = config;

% Node 5
config = NodeConfig();
config.x = 60;
config.y = 30;
config.movementTimes = [500];
config.movementsX = [-70];
config.movementsY = [0];
node_configs{end+1, 1} = config;

% Node 6
config = NodeConfig();
config.x = 60;
config.y = 60;
config.movementTimes = [500];
config.movementsX = [-70];
config.movementsY = [0];
node_configs{end+1, 1} = config;

%% Test 8: 6 Nodes in two groups, random wakeup, random trajectory
node_configs = {};

% Node 1
config = NodeConfig();
config.x = -50;
config.y = -50;
config.enterTime = {0, 1000};
config.trajectoryStartTime = {0, 400};
config.velocity = 25;
config.travelDistance = {50, 200};
config.maxSteering = 20;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 2
config = NodeConfig();
config.x = -100;
config.y = 20;
config.enterTime = {0, 1000};
config.trajectoryStartTime = {0, 400};
config.velocity = 25;
config.travelDistance = {50, 200};
config.maxSteering = 20;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 3
config = NodeConfig();
config.x = 20;
config.y = -100;
config.enterTime = {0, 1000};
config.trajectoryStartTime = {0, 400};
config.velocity = 25;
config.travelDistance = {50, 200};
config.maxSteering = 20;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 4
config = NodeConfig();
config.x = 50;
config.y = 50;
config.enterTime = {0, 1000};
config.trajectoryStartTime = {0, 400};
config.velocity = 25;
config.travelDistance = {50, 200};
config.maxSteering = 20;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 5
config = NodeConfig();
config.x = -20;
config.y = 100;
config.enterTime = {0, 1000};
config.trajectoryStartTime = {0, 400};
config.velocity = 25;
config.travelDistance = {50, 200};
config.maxSteering = 20;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 6
config = NodeConfig();
config.x = 100;
config.y = -20;
config.enterTime = {0, 1000};
config.trajectoryStartTime = {0, 400};
config.velocity = 25;
config.travelDistance = {50, 200};
config.maxSteering = 20;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;


%% Test 9: 6 Nodes, random location, random wakeup, random trajectory
node_configs = {};

% Node 1
config = NodeConfig();
config.enterTime = {0, 1000};
config.trajectoryStartTime = {0, 400};
config.velocity = 50;
config.travelDistance = {0, 200};
config.maxSteering = 50;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 2
config = NodeConfig();
config.enterTime = {0, 1000};
config.trajectoryStartTime = {0, 400};
config.velocity = 50;
config.travelDistance = {0, 200};
config.maxSteering = 50;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 3
config = NodeConfig();
config.enterTime = {0, 1000};
config.trajectoryStartTime = {0, 400};
config.velocity = 50;
config.travelDistance = {0, 200};
config.maxSteering = 50;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 4
config = NodeConfig();
config.enterTime = {0, 1000};
config.trajectoryStartTime = {0, 400};
config.velocity = 50;
config.travelDistance = {0, 200};
config.maxSteering = 50;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 5
config = NodeConfig();
config.enterTime = {0, 1000};
config.trajectoryStartTime = {0, 400};
config.velocity = 50;
config.travelDistance = {0, 200};
config.maxSteering = 50;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 6
config = NodeConfig();
config.enterTime = {0, 1000};
config.trajectoryStartTime = {0, 400};
config.velocity = 50;
config.travelDistance = {0, 200};
config.maxSteering = 50;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

%% CADRE Scenarios

%% Test 1: 4 Nodes, all in range, no movement, simultaneous wakeup
node_configs = {};

% Node 1
config = NodeConfig();
config.x = 0;
config.y = 0;
node_configs{end+1, 1} = config;

% Node 2
config = NodeConfig();
config.x = 40;
config.y = 0;
node_configs{end+1, 1} = config;

% Node 3
config = NodeConfig();
config.x = 40;
config.y = 40;
node_configs{end+1, 1} = config;

% Node 4
config = NodeConfig();
config.x = 0;
config.y = 40;
node_configs{end+1, 1} = config;

%% Test 2: 4 Nodes, random location, no movement, simultaneous wakeup
node_configs = {};

% Node 1
config = NodeConfig();
node_configs{end+1, 1} = config;

% Node 2
config = NodeConfig();
node_configs{end+1, 1} = config;

% Node 3
config = NodeConfig();
node_configs{end+1, 1} = config;

% Node 4
config = NodeConfig();
node_configs{end+1, 1} = config;

%% Test 3: 4 Nodes, random location, semi-random trajectory, simultaneous wakeup
% trajectory start time is random
% velocity is fixed
% travel distance is random between 0 and 100
% max steering angle is fixed
% number of sampling points is equal to distance traveled, so the node
% moves in "jumps" of 1m
node_configs = {};

% Node 1
config = NodeConfig();
config.trajectoryStartTime = {0, 1000};
config.velocity = 25;
config.travelDistance = {0, 200};
config.maxSteering = 20;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 2
config = NodeConfig();
config.trajectoryStartTime = {0, 1000};
config.velocity = 25;
config.travelDistance = {0, 200};
config.maxSteering = 20;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 3
config = NodeConfig();
config.trajectoryStartTime = {0, 1000};
config.velocity = 25;
config.travelDistance = {0, 200};
config.maxSteering = 20;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 4
config = NodeConfig();
config.trajectoryStartTime = {0, 1000};
config.velocity = 25;
config.travelDistance = {0, 200};
config.maxSteering = 20;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

%% Test 4: 4 Nodes in two groups, simultaneous wakeup, merging
node_configs = {};

% Node 1
config = NodeConfig();
config.x = -50;
config.y = 0;
node_configs{end+1, 1} = config;

% Node 2
config = NodeConfig();
config.x = -50;
config.y = 30;
node_configs{end+1, 1} = config;

% Node 3
config = NodeConfig();
config.x = 60;
config.y = 0;
config.movementTimes = [960];
config.movementsX = [-70];
config.movementsY = [0];
node_configs{end+1, 1} = config;

% Node 4
config = NodeConfig();
config.x = 60;
config.y = 30;
config.movementTimes = [960];
config.movementsX = [-70];
config.movementsY = [0];
node_configs{end+1, 1} = config;


%% Test 5: 4 Nodes in two groups, simultaneous wakeup, random trajectory
node_configs = {};

% Node 1
config = NodeConfig();
config.x = -50;
config.y = 0;
config.trajectoryStartTime = {0, 400};
config.velocity = 25;
config.travelDistance = {50, 200};
config.maxSteering = 20;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 2
config = NodeConfig();
config.x = -50;
config.y = 30;
config.trajectoryStartTime = {0, 400};
config.velocity = 25;
config.travelDistance = {50, 200};
config.maxSteering = 20;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 3
config = NodeConfig();
config.x = 60;
config.y = 0;
config.trajectoryStartTime = {0, 400};
config.velocity = 25;
config.travelDistance = {50, 200};
config.maxSteering = 20;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;

% Node 4
config = NodeConfig();
config.x = 60;
config.y = 30;
config.trajectoryStartTime = {0, 400};
config.velocity = 25;
config.travelDistance = {50, 200};
config.maxSteering = 20;
config.samplePoints = config.travelDistance;
node_configs{end+1, 1} = config;