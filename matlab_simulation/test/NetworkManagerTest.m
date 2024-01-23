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

classdef NetworkManagerTest < matlab.mock.TestCase

    properties
        networkManager;
    end

    methods(TestMethodSetup)
        function addSrcPath(testCase)
            addpath('../src');
        end

        function setUpTest(testCase)
            testCase.networkManager = NetworkManager();
        end
    end

    methods(Test)
        function notConnectedOnCreation(testCase)
            netStatus = testCase.networkManager.getNetworkStatus();
           
            testCase.verifyEqual(netStatus, NetworkStatus.NOT_CONNECTED);
        end

        function idIsEmptyOnCreation(testCase)
            currentNetId = testCase.networkManager.getNetworkId();
            testCase.verifyEmpty(currentNetId);
        end

        function setNetworkStatusToConnected(testCase)
            testCase.networkManager.setNetworkStatusToConnected();

            netStatus = testCase.networkManager.getNetworkStatus();

            testCase.verifyEqual(netStatus, NetworkStatus.CONNECTED);
        end

        function setNetworkStatusToConnectedTwice(testCase)
            testCase.networkManager.setNetworkStatusToConnected();
            testCase.networkManager.setNetworkStatusToConnected();

            netStatus = testCase.networkManager.getNetworkStatus();

            testCase.verifyEqual(netStatus, NetworkStatus.CONNECTED);
        end

        function setNetworkIdWhenConnected(testCase)
            testCase.networkManager.setNetworkStatusToConnected();
            
            testId = 1;
            idWasSet = testCase.networkManager.setNetworkId(testId);

            currentNetId = testCase.networkManager.getNetworkId();

            testCase.verifyTrue(idWasSet);
            testCase.verifyEqual(currentNetId, testId);
        end

        function dontSetNetworkIdWhenNotConnected(testCase)            
            testId = 1;
            idWasSet = testCase.networkManager.setNetworkId(testId);

            currentNetId = testCase.networkManager.getNetworkId();

            testCase.verifyFalse(idWasSet);
            testCase.verifyEmpty(currentNetId);
        end

        function saveNetworkAgeAtJoiningWhenConnectedWithId(testCase)
            testCase.networkManager.setNetworkStatusToConnected();
            testId = 1;
            idWasSet = testCase.networkManager.setNetworkId(testId);
            
            testNetAge = 333;
            ageWasSet = testCase.networkManager.saveNetworkAgeAtJoining(testNetAge);

            testCase.verifyTrue(ageWasSet);
        end

        function dontSaveNetworkAgeAtJoiningNotConnected(testCase)
            testNetAge = 333;
            ageWasSet = testCase.networkManager.saveNetworkAgeAtJoining(testNetAge);

            testCase.verifyFalse(ageWasSet);
        end

        function dontSaveNetworkAgeAtJoiningNoId(testCase)
            testCase.networkManager.setNetworkStatusToConnected();

            testNetAge = 333;
            ageWasSet = testCase.networkManager.saveNetworkAgeAtJoining(testNetAge);

            testCase.verifyFalse(ageWasSet);
        end

        function saveLocalTimeAtJoiningWhenConnectedWithId(testCase)
            testCase.networkManager.setNetworkStatusToConnected();
            testId = 1;
            idWasSet = testCase.networkManager.setNetworkId(testId);
            
            testLocalTime = 222;
            timeWasSet = testCase.networkManager.saveLocalTimeAtJoining(testLocalTime);

            testCase.verifyTrue(timeWasSet);
        end

        function dontSaveLocalTimeAtJoiningWhenNotConnected(testCase)
            testLocalTime = 222;
            timeWasSet = testCase.networkManager.saveLocalTimeAtJoining(testLocalTime);

            testCase.verifyFalse(timeWasSet);
        end

        function calculateNetworkAgeWhenConnected(testCase)
            testCase.networkManager.setNetworkStatusToConnected();
            testId = 1;
            idWasSet = testCase.networkManager.setNetworkId(testId);
            
            testLocalTime = 1000;
            timeWasSet = testCase.networkManager.saveLocalTimeAtJoining(testLocalTime);
            testNetAge = 400;
            ageWasSet = testCase.networkManager.saveNetworkAgeAtJoining(testNetAge);
            
            currentTime = 1450;
            netAge = testCase.networkManager.calculateNetworkAge(currentTime);
            expectedNetAge = currentTime + testNetAge - testLocalTime;

            testCase.verifyEqual(netAge, expectedNetAge);
        end

        function dontCalculateNetworkAgeWhenNotConnected(testCase)
            testLocalTime = 1000;
            timeWasSet = testCase.networkManager.saveLocalTimeAtJoining(testLocalTime);
            testNetAge = 400;
            ageWasSet = testCase.networkManager.saveNetworkAgeAtJoining(testNetAge);

            currentTime = 1450;
            netAge = testCase.networkManager.calculateNetworkAge(currentTime);

            testCase.verifyEmpty(netAge);
        end

        function dontCalculateNetworkAgeWhenAgeAtJoiningEmpty(testCase)
            testLocalTime = 1000;
            timeWasSet = testCase.networkManager.saveLocalTimeAtJoining(testLocalTime);

            currentTime = 1450;
            netAge = testCase.networkManager.calculateNetworkAge(currentTime);

            testCase.verifyEmpty(netAge);
        end

        function dontCalculateNetworkAgeWhenTimeAtJoiningEmpty(testCase)
            testNetAge = 400;
            ageWasSet = testCase.networkManager.saveNetworkAgeAtJoining(testNetAge);

            currentTime = 1450;
            netAge = testCase.networkManager.calculateNetworkAge(currentTime);

            testCase.verifyEmpty(netAge);
        end

        function identifyMsgFromForeignNetworkIfNotPing(testCase)
            msg.type = "";
            msg.networkId = 2;
            isForeign = testCase.networkManager.isPingFromForeignNetwork(msg);

            testCase.verifyFalse(isForeign);
        end

        function identifyPingFromForeignNetworkIfNotConnected(testCase)
            msg.type = MessageTypes.PING;
            msg.networkId = 2;
            isForeign = testCase.networkManager.isPingFromForeignNetwork(msg);

            testCase.verifyTrue(isForeign);
        end

        function identifyPingFromForeignNetworkIfIdIsDifferent(testCase)
            testCase.networkManager.setNetworkStatusToConnected();
            testId = 1;
            idWasSet = testCase.networkManager.setNetworkId(testId);

            msg.type = MessageTypes.PING;
            msg.networkId = 2;
            isForeign = testCase.networkManager.isPingFromForeignNetwork(msg);

            testCase.verifyTrue(isForeign);
        end

%         function identifyPingFromForeignNetworkIfNetAgeIsDifferent(testCase)
%             testCase.networkManager.setNetworkStatusToConnected();
%             testId = 1;
%             testCase.networkManager.setNetworkId(testId);
%             testLocalTime = 1000;
%             testCase.networkManager.saveLocalTimeAtJoining(testLocalTime);
%             testNetAge = 400;
%             testCase.networkManager.saveNetworkAgeAtJoining(testNetAge);
% 
% 
%             msg.type = MessageTypes.PING;
%             msg.networkId = 1;
%             isForeign = testCase.networkManager.isPingFromForeignNetwork(msg);
% 
%             testCase.verifyTrue(isForeign);
%         end
        
    end

end




