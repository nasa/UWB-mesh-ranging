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

classdef NodeWrapper < handle
    
    properties
        nodes;
        activeNodes = {};
        activeNodesIds = [];
        nodesBootupTimes = [];
        diagrams = {};
        channel;
        simConfig;
        scenario;
        animation;
        globalClock;
        
        scenarioLoaded = false;

        % topology change detection
        topologyChanges = {};
        oneHopNeighbors = {};
    end

    
    methods
        function this = NodeWrapper(nodes, channel, config, scenario, animation, diagrams, globalClock)
            this.nodes = nodes;
            this.diagrams = diagrams;
            this.channel = channel;
            this.simConfig = config;
            this.scenario = scenario;
            this.animation = animation;
            this.globalClock = globalClock;
        end
        
        function initializeNodes(this)
            % initialize all nodes (they start in "OFF"-state)
            for nodeIdx = 1:size(this.nodes,1)
                if isempty(this.nodes{nodeIdx,1}.getId())
                    this.nodes{nodeIdx,1}.initialize();
%                     this.diagrams{nodeIdx,1}.setId(this.nodes{nodeIdx,1}.id);
                end
            end
        end

        function runWrapper(this)
            globalTime = this.globalClock.getGlobalTime();

            % turn on nodes
            for nodeIdx = 1:size(this.nodes,1)
                if isempty(find(this.activeNodesIds == this.nodes{nodeIdx,1}.getId(), 1))
                    if globalTime >= this.nodes{nodeIdx,1}.getEnterTime() %* this.simConfig.timeFactor
                        this.nodes{nodeIdx,1}.stateMachine.run(Events.TURN_ON);
                        this.activeNodes{end+1, 1} = this.nodes{nodeIdx,1};
                        this.nodes{nodeIdx,1}.initialize();
                        this.activeNodesIds(end+1, 1) = this.nodes{nodeIdx,1}.getId();
                        this.nodesBootupTimes(end+1, 1) = globalTime;
                        
                        if this.simConfig.showAnimation
                            this.animation.addNode(this.activeNodes{end, 1});
                        end
                    end
                end
            end
            
%             % let scenario check and possibly run a manipulation
%             if this.scenario.checkManipulation()
%                 this.scenario.manipulate(this);
%             end
            
            % movements etc. take place on every sim tic
            for nodeIdx = 1:size(this.activeNodes, 1)
                this.activeNodes{nodeIdx,1}.move(globalTime);
            end

            % let nodes execute their actions
            for nodeIdx = 1:size(this.activeNodes, 1)
                this.activeNodes{nodeIdx,1}.runStateMachine(Events.TIME_TIC);
            end
            
            this.channel.execute(globalTime);
            
            % update diagram
            if this.simConfig.saveDiagrams
                for nodeIdx = 1:size(this.nodes, 1)
                    this.diagrams{nodeIdx,1}.updateOnTimeTic(this.nodes{nodeIdx,1}.stateMachine.state, this.nodes{nodeIdx,1}.stateMachine.stateData, globalTime);
                end
            end
            
            % update animation
            if this.simConfig.showAnimation
                if this.animation.checkForChanges()
                    this.animation.refresh();
                end
            end

            % update statistics
            % topology changes and time until a valid configuration is
            % found:
            if this.simConfig.createStatistics
                if this.updateTopologyAndDetectChanges()
                    this.topologyChanges{end + 1, 1} = globalTime;
                    this.topologyChanges{end, 2} = [];
                    currentResults = validateNodeSchedule(this.activeNodes, this.simConfig, false);
    
                    if currentResults.passed
                        this.topologyChanges{end, 2} = globalTime;
                    end
                else
                    if ~isempty(this.topologyChanges) & isempty(this.topologyChanges{end, 2})
                        currentResults = validateNodeSchedule(this.activeNodes, this.simConfig, false);
                        if currentResults.passed
                            this.topologyChanges{end, 2} = globalTime;
                        end
                    end
                end
            end

            % increment local times
            for nodeIdx = 1:size(this.activeNodes, 1)
                this.activeNodes{nodeIdx,1}.tic();
            end
            
        end

        function changed = updateTopologyAndDetectChanges(this)
            changed = false;
            oneHopNeighborsIdx = findNodesInRange(this.activeNodes);
            oneHopNeighborsIds = cell(size(oneHopNeighborsIdx, 1), 1);
            for i = 1:size(oneHopNeighborsIdx, 1)
                oneHopNeighborsIds{i, 1} = cellfun(@(c) c.getId(), this.activeNodes(oneHopNeighborsIdx{i,1}));

                if size(this.oneHopNeighbors, 1) < i
                    % new node
                    changed = true;
                else
                    if ~isequal(oneHopNeighborsIds{i, 1}, this.oneHopNeighbors{i, 1})
                        changed = true;
                    end
                end
                this.oneHopNeighbors{i, 1} = oneHopNeighborsIds{i, 1};
            end
        end
        
        function activeNodes = getActiveNodes(this)
            activeNodes = this.activeNodes;
        end
        
        function nodes = getNodes(this)
            nodes = this.nodes;
        end
        
        function diagrams = getDiagrams(this)
            diagrams = this.diagrams;
        end
    end
end



