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

classdef NetworkManager < handle

    properties %(Access = private)
        networkStatus;
        networkId;
        networkAgeAtJoining;
        localTimeAtJoining;
        currentNetworkStartedByThisNode;

        nodeId;
    end

    methods
        function this = NetworkManager()
            this.networkStatus = NetworkStatus.NOT_CONNECTED;
            this.currentNetworkStartedByThisNode = false;
        end

        function createNetwork(this, localTime)
            this.setNetworkStatusToConnected();
            this.setNetworkId(this.nodeId);
            this.networkAgeAtJoining = 0;
            this.localTimeAtJoining = localTime;
        end

        function netStatus = getNetworkStatus(this)
            netStatus = this.networkStatus;
        end

        function setNetworkStatusToConnected(this)
            this.networkStatus = NetworkStatus.CONNECTED;
        end

        function disconnect(this)
            this.networkStatus = NetworkStatus.NOT_CONNECTED;
            this.networkId = [];
            this.networkAgeAtJoining = [];
            this.localTimeAtJoining = [];
            this.currentNetworkStartedByThisNode = false;
        end

        function wasSet = setNetworkId(this, id)
            if this.networkStatus == NetworkStatus.CONNECTED
                this.networkId = id;
                wasSet = true;
                if isequal(this.nodeId, id)
                    this.currentNetworkStartedByThisNode = true;
                end
            else
                wasSet = false;
            end
        end

        function networkId = getNetworkId(this)
            networkId = this.networkId;
        end

        function wasSet = saveNetworkAgeAtJoining(this, netAge)
            if ~this.isConnectedAndHasId()
                wasSet = false;
                return;
            end

            this.networkAgeAtJoining = netAge;
            wasSet = true;
        end

        function wasSet = saveLocalTimeAtJoining(this, localTime)
            if ~this.isConnectedAndHasId()
                wasSet = false;
                return;
            end

            this.localTimeAtJoining = localTime;
            wasSet = true;
        end

        function netAge = calculateNetworkAge(this, localTime)
            if ~this.isConnectedAndHasId()
                netAge = [];
                return;
            end

            if isempty(this.networkAgeAtJoining) | isempty(this.localTimeAtJoining)
                netAge = [];
                return;
            end

            netAge = localTime - this.localTimeAtJoining + this.networkAgeAtJoining;
        end

        function isForeignPing = isPingFromForeignNetwork(this, msg, localTime, receivedPingNetAgeNow)
            if ~isequal(msg.type, MessageTypes.PING)
                isForeignPing = false;
                return;
            end

            if ~this.isConnectedAndHasId()
                isForeignPing = true;
                return;
            end
            
            ownNetAge = this.calculateNetworkAge(localTime);
            tolerance = 2;
            sameAge = (receivedPingNetAgeNow <= ownNetAge + tolerance) & (receivedPingNetAgeNow >= ownNetAge - tolerance);

            if isequal(msg.networkId, this.networkId) & sameAge
                isForeignPing = false;
                return;
            else
                isForeignPing = true;
            end
        end

        function foreignPrecedes = isForeignNetworkPreceding(this, localTime, foreignNetAgeNow)
            foreignPrecedes = false;
            ownNetAgeNow = this.calculateNetworkAge(localTime);
            if foreignNetAgeNow > ownNetAgeNow
                foreignPrecedes = true;
            end
        end

        function result = networkStartedByThisNode(this)
            if NetworkStatus.CONNECTED
                result = this.currentNetworkStartedByThisNode;
            else
                result = false;
            end
        end

        function setNodeId(this, id)
            this.nodeId = id;
        end
    end

    methods(Access = private)
        function result = isConnectedAndHasId(this)
            isConnected = this.networkStatus == NetworkStatus.CONNECTED;
            hasId = ~isempty(this.networkId);
            if isConnected && hasId
                result = true;
            else
                result = false;
            end
        end
    end
end