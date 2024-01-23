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

classdef Animation_mex < handle
    
    properties
        animationWindow;
        timeBox;
        filename;
        
        nodes = {};
        channel;
        pWrapper;
        
        nodesX = {};
        nodesY = {};
        nodesColor = {};
        nodesNumColor = {};
        
        nodeHandles = {};
        nodeIdTextHandles = {};
        slotTextHandles = {};
        signalRangeHandles = {};
        linkHandles = {};
        
        nodeCircleRadius = 9;
        gifCreatedFlag = 0;
        simConfig;
        config;
        colors = {'r', 'g', 'b', 'c', 'm', 'k'};
    end
    
    methods
        
        function this = Animation_mex(gifFilename, simConfig, config, nodes, channel, pWrapper)
            this.simConfig = simConfig;
            this.config = config;
%             this.nodes = nodes;
            this.channel = channel;
            this.pWrapper = pWrapper;

            this.animationWindow = figure('Name', 'Simulation Animation');
            xlim([-150 150]);
            ylim([-150 150]);
            this.timeBox = annotation('textbox', [0.8, 0.8, 0.1, 0.1], 'String', "", 'FitBoxToText','on');
            this.filename = gifFilename;
            grid on;
            grid minor;
            xlabel('x [m]');
            ylabel('y [m]');
        end
        
        function addNode(this, node, globalTime)
            
            this.nodes(end+1, :) = node;
            x = this.nodes{end, 2}.x;
            y = this.nodes{end, 2}.y;
            
            % draw circle
            h = plotCircle(x, y, this.nodeCircleRadius, 3);
            % draw node id
            h2 = text(x, y, strcat('\bf', num2str(this.nodes{end, 1})), 'HorizontalAlignment', 'center', 'FontSize', 12);
%             % draw signal range
%             h3 = plotCircle(x, y, this.config.signalRange, 1);
            
            % draw own slots
            slots = getSlotsAsString(node, this.pWrapper);
            networkId = MatlabWrapper(16, this.pWrapper, node{1, 1}); % color of slot text should depend on network (this implementation uses only the ID, so may not work in every case)
            if networkId == 0
                networkId = node{1, 1};
            end
            h4 = text(x + this.nodeCircleRadius + 3, y - this.nodeCircleRadius, strcat('\bf', slots), 'HorizontalAlignment', 'center', 'FontSize', 10, 'Color', this.colors{1, networkId});
            hold on;



            % add handle
            this.nodeHandles{end+1, 1} = h; % node handle is the plotted  circle
            this.nodeIdTextHandles{end+1, 1} = h2; % text handle is the node ID inside the circle
%             this.signalRangeHandles{end+1, 1} = h3;
            this.slotTextHandles{end+1, 1} = h4;
            this.linkHandles{end+1, 1} = cell(1, this.simConfig.numNodes);

            % draw links
            for linkIdx = 1:size(this.nodes,1)
                sender = this.nodes{end, 1};
                receiver = this.nodes{linkIdx, 1};
                position1.x = this.nodes{end, 2}.x;
                position1.y = this.nodes{end, 2}.y;
                position2.x = this.nodes{linkIdx, 2}.x;
                position2.y = this.nodes{linkIdx, 2}.y;
                
                if this.channel.isInRange(position1, position2)
                   this.linkHandles{end, 1}{1, linkIdx} = plot([position1.x, position2.x], [position1.y, position2.y], "Color", 'k');
                else
                    this.linkHandles{end, 1}{1, linkIdx} = plot([position1.x, position2.x], [position1.y, position2.y], "Color", 'k');
                    set(this.linkHandles{end, 1}{1, linkIdx}, 'LineStyle', 'none')
                end
            end
            
            this.nodesX{end+1, 1} = x;
            this.nodesY{end+1, 1} = y;
            this.nodesColor{end+1, 1} = getCircleColor(node, this.pWrapper);
            this.nodesNumColor{end+1, 1} = getNumberColor(node, this.config.slotGoal, this.pWrapper);
            this.refresh(globalTime, this.nodes(:, 2));
        end
        
        function removeNode(this, id, globalTime)
            for i = 1:size(this.nodes, 1)
                if this.nodes{i,1}.id == id
                    this.nodes{i,1} = [];
                    this.nodesX{i,1} = [];
                    this.nodesY{i,1} = [];
                    this.nodesColor{i,1} = [];
                    this.nodesNumColor{i,1} = [];
                    this.nodeHandles{i,1} = [];
                    this.nodeIdTextHandles{i,1} = [];
                    this.slotTextHandles{i,1} = [];
                    break;
                end
            end
            this.refresh(globalTime);
        end
        
        function refresh(this, globalTime, currentPositions)
            
            figure(this.animationWindow);
            axis equal;
            for i = 1:size(this.nodeHandles, 1)
                position.x = currentPositions{i, 1}.x;
                position.y = currentPositions{i, 1}.y;

                [xdat, ydat] = getCircle(position.x, position.y, this.nodeCircleRadius);
                [xdat2, ydat2] = getCircle(position.x, position.y, this.channel.signalRange);
                color = getCircleColor(this.nodes(i, 1), this.pWrapper);
                numColor = getNumberColor(this.nodes(i, 1), this.config.slotGoal, this.pWrapper);
                
                set(this.nodeHandles{i,1},'XData', xdat,'YData', ydat, 'Color', color);
                set(this.nodeIdTextHandles{i,1}, 'Position', [position.x position.y], 'Color', numColor);
                
%                 set(this.signalRangeHandles{i,1},'XData', xdat2,'YData', ydat2, 'Color', this.colors{1, this.nodes{i, 1}.id});
                
                slots = getSlotsAsString(this.nodes(i,1), this.pWrapper);
                networkId = MatlabWrapper(16, this.pWrapper, this.nodes{i, 1}); % color of slot text should depend on network
                
                if networkId == 0
                    networkId = this.nodes{i, 1};
                end
                set(this.slotTextHandles{i,1}, 'Position', [(position.x + this.nodeCircleRadius + 3) (position.y - this.nodeCircleRadius)], 'Color', this.colors{1, networkId},'String', slots);

                % draw links
                for linkIdx = 1:size(this.nodes,1)
                    position2.x = currentPositions{linkIdx, 1}.x;
                    position2.y = currentPositions{linkIdx, 1}.y;
                    
                    if this.channel.isInRange(position, position2)
                        set(this.linkHandles{i,1}{1, linkIdx},'XData', [position.x, position2.x],'YData', [position.y, position2.y], 'LineStyle', '-', 'Color', 'k');
                    else
                        set(this.linkHandles{i,1}{1, linkIdx}, 'LineStyle', 'none')
                    end
                end

            end
            
            set(this.timeBox, 'String', num2str(globalTime));
            
            drawnow;
            
            if this.simConfig.saveAnimation
                this.saveToGif(this.animationWindow, this.filename);
            end
        end
        
        function changed = checkForChanges(this, currentPositions)
            changed = false;
            
            for i = 1:size(this.nodes, 1)
                position.x = currentPositions{i, 1}.x;
                position.y = currentPositions{i, 1}.y;
                color = getCircleColor(this.nodes(i, 1), this.pWrapper);
                numColor = getNumberColor(this.nodes(i, 1), this.config.slotGoal, this.pWrapper);
                
                if position.x ~= this.nodesX{i, 1} | ...
                        position.y ~= this.nodesY{i, 1} | ...
                        ~strcmp(color, this.nodesColor{i, 1}) | ...
                        ~strcmp(numColor, this.nodesNumColor{i, 1})
                    % update and indicate changes
                    this.nodesX{i, 1} = position.x;
                    this.nodesY{i, 1} = position.y;
                    this.nodesColor{i, 1} = color;
                    this.nodesNumColor{i, 1} = numColor;
                    changed = true;
                end
            end
        end
        
        function saveToGif(this, h, filename)
            % Capture the plot as an image 
            frame = getframe(h); 
            im = frame2im(frame); 
            [imind,cm] = rgb2ind(im,256); 
            % Write to the GIF File 
            if ~this.gifCreatedFlag
                imwrite(imind,cm,filename,'gif', 'Loopcount',inf); 
                this.gifCreatedFlag = 1;
            else 
                imwrite(imind,cm,filename,'gif','WriteMode','append'); 
            end 
        end
    end
    
end

function h = plotCircle(x,y,r, width)
    hold on
    th = 0:pi/50:2*pi;
    xunit = r * cos(th) + x;
    yunit = r * sin(th) + y;
    h = plot(xunit, yunit, 'LineWidth', width, 'Color', 'b');
    hold off
end

function [xcircle,ycircle] = getCircle(x,y,r)
    hold on
    th = 0:pi/50:2*pi;
    xcircle = r * cos(th) + x;
    ycircle = r * sin(th) + y;
end

function color = getCircleColor(node, pWrapper)

    % evaluate color based on state (listening or sending)
    state = MatlabWrapper(11, pWrapper, node{1, 1});
    switch state
        case States_mex.LISTENING_CONNECTED
            color = 'blue';
        case States_mex.LISTENING_UNCONNECTED
            color = 'blue';
        case States_mex.SENDING_UNCONNECTED
            color = 'green';
        case States_mex.SENDING_CONNECTED
            color = 'green';
        case States_mex.RANGING_POLL
            color = 'green';
        case States_mex.RANGING_WAITING
            color = 'blue';
        case States_mex.RANGING_RESP
            color = 'green';
        case States_mex.RANGING_FINAL
            color = 'green';
        case States_mex.RANGING_RESULT
            color = 'green'; 
        case States_mex.LISTENING_RANGING
            color = 'blue';
        case States_mex.IDLE
            color = "black";
        case States_mex.OFF
            color = "black";
    end
    
    % modifications:
    % collision is received: red
%     localTime = node.getLocalTime();
%     collisionNow = find(localTime == node.slotMap.collisionPerceivedAt);
    
%     if ~isempty(collisionNow)
%         color = 'red';
%     end
end

function numColor = getNumberColor(node, numSlotsToReserve, pWrapper)
    % change color of node ID to indicate whether the node successfully
    % reserved the desired number of slots
    ownSlots = MatlabWrapper(13, pWrapper, node{1,1});
    
    % remove zeros from the slots
    zerosLogical = (ownSlots ~= 0);
    ownSlots = ownSlots(zerosLogical);
    
    numOwnSlots = size(ownSlots, 2);
    
    if (numOwnSlots >= numSlotsToReserve)
        numColor = 'green';
    else
        numColor = 'black';
    end

end

function slots = getSlotsAsString(node, pWrapper)
    slots = "";
    ownSlots = MatlabWrapper(13, pWrapper, node{1,1});
    
    % remove zeros from the slots
    zerosLogical = (ownSlots ~= 0);
    ownSlots = ownSlots(zerosLogical);
    
    if ~isempty(ownSlots)
        for slotIdx = 1:size(ownSlots, 2)
            slots = strcat(slots, num2str(ownSlots(1, slotIdx)));
            if size(ownSlots, 2) > 1
                slots = strcat(slots, ",");
            end
        end
    else
        slots = "-";
    end
end



