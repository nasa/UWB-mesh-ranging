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

classdef SlotMapTest < matlab.mock.TestCase

    properties
        slotMap;

        config;

        randomNumbersStub;
        randomNumbersBehaviour;
    end

    methods(TestMethodSetup)
        function addSrcPath(testCase)
            addpath('../src');
        end

        function setUpTest(testCase)
            testCase.config.slotsPerFrame = 4;
            testCase.config.slotLength = 100;
            testCase.config.occupiedSlotTimeout = 800;
            testCase.config.collidingSlotTimeout = 100;
            testCase.config.collidingSlotTimeoutMultiHop = 400;
            testCase.config.occupiedSlotTimeoutMultiHop = 500;
            testCase.config.slotExpirationTimeout = 500;
            testCase.config.ownSlotExpirationTimeout = 800;
            testCase.config.slotGoal = 1;

            [testCase.randomNumbersStub, testCase.randomNumbersBehaviour] = StubFactory.makeRandomNumbersStub(testCase);

            testCase.slotMap = SlotMap(testCase.config, testCase.randomNumbersStub);
        end
    end

    methods(Test)
        function allOneHopSlotsFreeAtCreation(testCase)
            
            oneHopSlotMap = testCase.slotMap.getOneHopSlotMap();
                
            freeStatus = zeros(1, testCase.config.slotsPerFrame);
            freeIds = zeros(1, testCase.config.slotsPerFrame);
            freeLastUpdated = zeros(1, testCase.config.slotsPerFrame);

            testCase.verifyEqual(oneHopSlotMap.status, freeStatus);
            testCase.verifyEqual(oneHopSlotMap.ids, freeIds);
            testCase.verifyEqual(oneHopSlotMap.lastUpdated, freeLastUpdated);
        end

        function slotNumberIsUsedFromConfig(testCase)
            oneHopSlotMap = testCase.slotMap.getOneHopSlotMap();
            twoHopSlotMap = testCase.slotMap.getTwoHopSlotMap();
            threeHopSlotMap = testCase.slotMap.getThreeHopSlotMap();

            testCase.verifyEqual(size(oneHopSlotMap.status, 2), testCase.config.slotsPerFrame);
            testCase.verifyEqual(size(oneHopSlotMap.ids, 2), testCase.config.slotsPerFrame);
            testCase.verifyEqual(size(oneHopSlotMap.lastUpdated, 2), testCase.config.slotsPerFrame);

            testCase.verifyEqual(size(twoHopSlotMap.status, 2), testCase.config.slotsPerFrame);
            testCase.verifyEqual(size(twoHopSlotMap.ids, 2), testCase.config.slotsPerFrame);
            testCase.verifyEqual(size(twoHopSlotMap.lastUpdated, 2), testCase.config.slotsPerFrame);

            testCase.verifyEqual(size(threeHopSlotMap.status, 2), testCase.config.slotsPerFrame);
            testCase.verifyEqual(size(threeHopSlotMap.ids, 2), testCase.config.slotsPerFrame);
            testCase.verifyEqual(size(threeHopSlotMap.lastUpdated, 2), testCase.config.slotsPerFrame);
        end

        function updateOneHopSlotsUsesCurrentSlot(testCase)
            localTime = 1000;
            msg.type = MessageTypes.PING;
            msg.senderId = 3;
            currentSlot = 1;
            
            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime);

            currentSlot2 = 4;
            msg2.type = MessageTypes.PING;
            msg2.senderId = 2;
            testCase.slotMap.updateOneHopSlotMap(msg2, currentSlot2, localTime);

            oneHopSlots = testCase.slotMap.getOneHopSlotMap();

            expectedStatus = zeros(1, testCase.config.slotsPerFrame);
            expectedStatus(1, currentSlot) = 1;
            expectedStatus(1, currentSlot2) = 1;

            expectedIds = zeros(1, testCase.config.slotsPerFrame);
            expectedIds(1, currentSlot) = msg.senderId;
            expectedIds(1, currentSlot2) = msg2.senderId;

            testCase.verifyEqual(oneHopSlots.status, expectedStatus);
            testCase.verifyEqual(oneHopSlots.ids, expectedIds);
        end

        function allTwoHopSlotsFreeAtCreation(testCase)
            twoHopSlotMap = testCase.slotMap.getTwoHopSlotMap();
                
            freeStatus = zeros(1, testCase.config.slotsPerFrame);
            freeIds = zeros(1, testCase.config.slotsPerFrame);
            freeLastUpdated = zeros(1, testCase.config.slotsPerFrame);

            testCase.verifyEqual(twoHopSlotMap.status, freeStatus);
            testCase.verifyEqual(twoHopSlotMap.ids, freeIds);
            testCase.verifyEqual(twoHopSlotMap.lastUpdated, freeLastUpdated);
        end

        function allThreeHopSlotsFreeAtCreation(testCase)
            threeHopSlotMap = testCase.slotMap.getThreeHopSlotMap();
                
            freeStatus = zeros(1, testCase.config.slotsPerFrame);
            freeIds = zeros(1, testCase.config.slotsPerFrame);
            freeLastUpdated = zeros(1, testCase.config.slotsPerFrame);

            testCase.verifyEqual(threeHopSlotMap.status, freeStatus);
            testCase.verifyEqual(threeHopSlotMap.ids, freeIds);
            testCase.verifyEqual(threeHopSlotMap.lastUpdated, freeLastUpdated);
        end

        function updateOneHopSlotsOnPingSlotFree(testCase)
            localTime = 1000;
            msg.type = MessageTypes.PING;
            msg.senderId = 3;
            currentSlot = 2;

            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime);
            oneHopSlots = testCase.slotMap.getOneHopSlotMap();

            expectedStatus = zeros(1, testCase.config.slotsPerFrame);
            expectedStatus(1, currentSlot) = SlotOccupancyStates.OCCUPIED;

            expectedIds = zeros(1, testCase.config.slotsPerFrame);
            expectedIds(1, currentSlot) = 3;

            expectedLastUpdated = zeros(1, testCase.config.slotsPerFrame);
            expectedLastUpdated(1, currentSlot) = localTime;

            testCase.verifyEqual(oneHopSlots.status, expectedStatus);
            testCase.verifyEqual(oneHopSlots.ids, expectedIds);
            testCase.verifyEqual(oneHopSlots.lastUpdated, expectedLastUpdated);
        end

        function updateOneHopSlotsOnCollisionSlotFree(testCase)
            localTime = 1000;
            msg.type = MessageTypes.COLLISION;
            currentSlot = 2;

            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime);
            oneHopSlots = testCase.slotMap.getOneHopSlotMap();

            expectedStatus = zeros(1, testCase.config.slotsPerFrame);
            expectedStatus(1, currentSlot) = SlotOccupancyStates.COLLIDING;

            expectedIds = zeros(1, testCase.config.slotsPerFrame);
            expectedIds(1, currentSlot) = 0;

            expectedLastUpdated = zeros(1, testCase.config.slotsPerFrame);
            expectedLastUpdated(1, currentSlot) = localTime;

            testCase.verifyEqual(oneHopSlots.status, expectedStatus);
            testCase.verifyEqual(oneHopSlots.ids, expectedIds);
            testCase.verifyEqual(oneHopSlots.lastUpdated, expectedLastUpdated);
        end

        function updateOneHopSlotMapOnPingSlotOccupiedNotExpired(testCase)
            % slot should not be updated when it is already occupied and not
            % expired
            % set slot to occupied
            localTime = 1000;
            msg.type = MessageTypes.PING;
            msg.senderId = 1;
            currentSlot = 1;
            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime);
            
            % send another ping
            localTime2 = 1600;
            msg.type = MessageTypes.PING;
            msg.senderId = 3;
            currentSlot = 1;

            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime2);
            oneHopSlots = testCase.slotMap.getOneHopSlotMap();

            expectedStatus = zeros(1, testCase.config.slotsPerFrame);
            expectedStatus(1, currentSlot) = SlotOccupancyStates.OCCUPIED;

            expectedIds = zeros(1, testCase.config.slotsPerFrame);
            expectedIds(1, currentSlot) = 1;

            expectedLastUpdated = zeros(1, testCase.config.slotsPerFrame);
            expectedLastUpdated(1, currentSlot) = localTime;

            testCase.verifyEqual(oneHopSlots.status, expectedStatus);
            testCase.verifyEqual(oneHopSlots.ids, expectedIds);
            testCase.verifyEqual(oneHopSlots.lastUpdated, expectedLastUpdated);
        end

        function updateOneHopSlotsOnCollisionSlotOccupiedNotExpired(testCase)
            % slot should be updated even though it is already occupied and not
            % expired
            % set slot to occupied
            localTime = 1000;
            msg.type = MessageTypes.PING;
            msg.senderId = 1;
            currentSlot = 1;
            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime);
            
            % send collision
            localTime2 = 1600;
            msg.type = MessageTypes.COLLISION;
            currentSlot = 1;

            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime2);
            oneHopSlots = testCase.slotMap.getOneHopSlotMap();

            expectedStatus = zeros(1, testCase.config.slotsPerFrame);
            expectedStatus(1, currentSlot) = SlotOccupancyStates.COLLIDING;

            expectedIds = zeros(1, testCase.config.slotsPerFrame);
            expectedIds(1, currentSlot) = 0;

            expectedLastUpdated = zeros(1, testCase.config.slotsPerFrame);
            expectedLastUpdated(1, currentSlot) = localTime2;

            testCase.verifyEqual(oneHopSlots.status, expectedStatus);
            testCase.verifyEqual(oneHopSlots.ids, expectedIds);
            testCase.verifyEqual(oneHopSlots.lastUpdated, expectedLastUpdated);
        end

        function updateOneHopSlotMapOnPingSlotOccupiedExpired(testCase)
            % slot should be updated when it is already occupied and also
            % expired

            % set slot to occupied
            localTime = 1000;
            msg.type = MessageTypes.PING;
            msg.senderId = 1;
            currentSlot = 1;
            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime);
            
            % send another ping
            localTime2 = 2000;
            msg.type = MessageTypes.PING;
            msg.senderId = 3;
            currentSlot = 1;

            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime2);
            oneHopSlots = testCase.slotMap.getOneHopSlotMap();

            expectedStatus = zeros(1, testCase.config.slotsPerFrame);
            expectedStatus(1, 1) = SlotOccupancyStates.OCCUPIED;

            expectedIds = zeros(1, testCase.config.slotsPerFrame);
            expectedIds(1, 1) = 3;

            expectedLastUpdated = zeros(1, testCase.config.slotsPerFrame);
            expectedLastUpdated(1, currentSlot) = localTime2;

            testCase.verifyEqual(oneHopSlots.status, expectedStatus);
            testCase.verifyEqual(oneHopSlots.ids, expectedIds);
            testCase.verifyEqual(oneHopSlots.lastUpdated, expectedLastUpdated);
        end

        function updateOneHopSlotMapOnCollisionSlotOccupiedExpired(testCase)
            % slot should be updated 

            % set slot to occupied
            localTime = 1000;
            msg.type = MessageTypes.PING;
            msg.senderId = 1;
            currentSlot = 1;
            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime);
            
            % send collision
            localTime2 = 2000;
            msg.type = MessageTypes.COLLISION;
            currentSlot = 1;

            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime2);
            oneHopSlots = testCase.slotMap.getOneHopSlotMap();

            expectedStatus = zeros(1, testCase.config.slotsPerFrame);
            expectedStatus(1, 1) = SlotOccupancyStates.COLLIDING;

            expectedIds = zeros(1, testCase.config.slotsPerFrame);
            expectedIds(1, 1) = 0;

            expectedLastUpdated = zeros(1, testCase.config.slotsPerFrame);
            expectedLastUpdated(1, currentSlot) = localTime2;

            testCase.verifyEqual(oneHopSlots.status, expectedStatus);
            testCase.verifyEqual(oneHopSlots.ids, expectedIds);
            testCase.verifyEqual(oneHopSlots.lastUpdated, expectedLastUpdated);
        end

        function updateOneHopSlotMapOnPingSlotCollidingNotExpired(testCase)
            % slot should not be updated when it is already occupied and not
            % expired
            % set slot to colliding
            localTime = 1000;
            msg.type = MessageTypes.COLLISION;
            currentSlot = 1;
            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime);
            
            % send ping
            localTime2 = 1099;
            msg.type = MessageTypes.PING;
            msg.senderId = 3;
            currentSlot = 1;

            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime2);
            oneHopSlots = testCase.slotMap.getOneHopSlotMap();

            expectedStatus = zeros(1, testCase.config.slotsPerFrame);
            expectedStatus(1, currentSlot) = SlotOccupancyStates.COLLIDING;

            expectedIds = zeros(1, testCase.config.slotsPerFrame);
            expectedIds(1, currentSlot) = 0;

            expectedLastUpdated = zeros(1, testCase.config.slotsPerFrame);
            expectedLastUpdated(1, currentSlot) = localTime;

            testCase.verifyEqual(oneHopSlots.status, expectedStatus);
            testCase.verifyEqual(oneHopSlots.ids, expectedIds);
            testCase.verifyEqual(oneHopSlots.lastUpdated, expectedLastUpdated);
        end

        function updateOneHopSlotMapOnPingSlotCollidingExpired(testCase)
            % slot should be updated when it is already occupied and
            % expired
            % set slot to colliding
            localTime = 1000;
            msg.type = MessageTypes.COLLISION;
            currentSlot = 1;
            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime);
            
            % send ping
            localTime2 = 1100;
            msg.type = MessageTypes.PING;
            msg.senderId = 3;
            currentSlot = 1;

            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime2);
            oneHopSlots = testCase.slotMap.getOneHopSlotMap();

            expectedStatus = zeros(1, testCase.config.slotsPerFrame);
            expectedStatus(1, currentSlot) = SlotOccupancyStates.OCCUPIED;

            expectedIds = zeros(1, testCase.config.slotsPerFrame);
            expectedIds(1, currentSlot) = 3;

            expectedLastUpdated = zeros(1, testCase.config.slotsPerFrame);
            expectedLastUpdated(1, currentSlot) = localTime2;

            testCase.verifyEqual(oneHopSlots.status, expectedStatus);
            testCase.verifyEqual(oneHopSlots.ids, expectedIds);
            testCase.verifyEqual(oneHopSlots.lastUpdated, expectedLastUpdated);
        end

        function timeIsUpdatedForOccupiedSlot(testCase)
            % slot should be updated when it is already occupied and also
            % expired

            % set slot to occupied
            localTime = 1000;
            msg.type = MessageTypes.PING;
            msg.senderId = 1;
            currentSlot = 1;
            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime);
            
            % send another ping
            localTime2 = 1400;
            msg.type = MessageTypes.PING;
            msg.senderId = 1;
            currentSlot = 1;
            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime2);

            oneHopSlots = testCase.slotMap.getOneHopSlotMap();

            expectedLastUpdated = zeros(1, testCase.config.slotsPerFrame);
            expectedLastUpdated(1, currentSlot) = localTime2;

            testCase.verifyEqual(oneHopSlots.lastUpdated, expectedLastUpdated);
        end

        %% updateMultiHopSlotMap (tested using updateTwoHopSlotMap)

        function updateMultiHopSlotFreeNewOccupied(testCase)
            % slot currently free, new status is occupied
            msg.oneHopSlotsStatus = [0, 0, 1, 0];
            msg.oneHopSlotsIds = [0, 0, 2, 0];
            
            localTime = 1000;

            testCase.slotMap.updateTwoHopSlotMap(msg, localTime);
            twoHopSlots = testCase.slotMap.getTwoHopSlotMap();

            expectedLastUpdates = [0, 0, 1000, 0];

            testCase.verifyEqual(twoHopSlots.status, msg.oneHopSlotsStatus);
            testCase.verifyEqual(twoHopSlots.ids, msg.oneHopSlotsIds);
            testCase.verifyEqual(twoHopSlots.lastUpdated, expectedLastUpdates);
        end

        function updateMultiHopSlotUsesCorrectMapSize(testCase)
            config.slotsPerFrame = 5;
            config.occupiedSlotTimeoutMultiHop = 500;

            testSlotMap = SlotMap(config, []);

            msg.oneHopSlotsStatus = [0, 0, 1, 0, 1];
            msg.oneHopSlotsIds = [0, 0, 2, 0, 3];
            
            localTime = 1000;

            testSlotMap.updateTwoHopSlotMap(msg, localTime);
            twoHopSlots = testSlotMap.getTwoHopSlotMap();

            expectedLastUpdates = [0, 0, 1000, 0, 1000];

            testCase.verifyEqual(twoHopSlots.status, msg.oneHopSlotsStatus);
            testCase.verifyEqual(twoHopSlots.ids, msg.oneHopSlotsIds);
            testCase.verifyEqual(twoHopSlots.lastUpdated, expectedLastUpdates);
        end

        function updateMultiHopSlotOccupiedNotExpiredNewOccupiedOtherNode(testCase)
            % slot currently occupied and not expired, new status occupied
            % by other node; should be set to colliding
            
            % setup slot map 
            localTime = 1000;
            msg.oneHopSlotsStatus = [0, 0, 1, 0];
            msg.oneHopSlotsIds = [0, 0, 2, 0];
            
            testCase.slotMap.updateTwoHopSlotMap(msg, localTime);

            localTime2 = 1400;
            msg2.oneHopSlotsStatus = [1, 0, 1, 0];
            msg2.oneHopSlotsIds = [3, 0, 4, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg2, localTime2);

            twoHopSlots = testCase.slotMap.getTwoHopSlotMap();

            expectedStatus = [1, 0, 2, 0];
            expectedIds = [3, 0, 0, 0];
            expectedLastUpdates = [localTime2, 0, localTime2, 0];

            testCase.verifyEqual(twoHopSlots.status, expectedStatus);
            testCase.verifyEqual(twoHopSlots.ids, expectedIds);
            testCase.verifyEqual(twoHopSlots.lastUpdated, expectedLastUpdates);
        end

        function updateMultiHopSlotOccupiedExpiredNewOccupiedOtherNode(testCase)
            % slot currently occupied but expired, new status occupied
            % by other node; should be updated

            % setup slot map 
            localTime = 1000;
            msg.oneHopSlotsStatus = [0, 0, 1, 0];
            msg.oneHopSlotsIds = [0, 0, 2, 0];
            
            testCase.slotMap.updateTwoHopSlotMap(msg, localTime);

            localTime2 = 1900;
            msg2.oneHopSlotsStatus = [1, 0, 1, 0];
            msg2.oneHopSlotsIds = [3, 0, 4, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg2, localTime2);

            twoHopSlots = testCase.slotMap.getTwoHopSlotMap();

            expectedStatus = [1, 0, 1, 0];
            expectedIds = [3, 0, 4, 0];
            expectedLastUpdates = [localTime2, 0, localTime2, 0];

            testCase.verifyEqual(twoHopSlots.status, expectedStatus);
            testCase.verifyEqual(twoHopSlots.ids, expectedIds);
            testCase.verifyEqual(twoHopSlots.lastUpdated, expectedLastUpdates);
        end

        function updateMultiHopSlotOccupiedNewOccupiedSameNode(testCase)
            % slot currently occupied, new status occupied
            % by same node; should be updated

            % setup slot map 
            localTime = 1000;
            msg.oneHopSlotsStatus = [0, 0, 1, 0];
            msg.oneHopSlotsIds = [0, 0, 2, 0];
            
            testCase.slotMap.updateTwoHopSlotMap(msg, localTime);

            localTime2 = 1500;
            msg2.oneHopSlotsStatus = [1, 0, 1, 0];
            msg2.oneHopSlotsIds = [3, 0, 2, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg2, localTime2);

            twoHopSlots = testCase.slotMap.getTwoHopSlotMap();

            expectedStatus = [1, 0, 1, 0];
            expectedIds = [3, 0, 2, 0];
            expectedLastUpdated = [localTime2, 0, localTime2, 0];

            testCase.verifyEqual(twoHopSlots.status, expectedStatus);
            testCase.verifyEqual(twoHopSlots.ids, expectedIds);
            testCase.verifyEqual(twoHopSlots.lastUpdated, expectedLastUpdated);
        end

        function updateMultiHopSlotFreeNewColliding(testCase)
            % slot currently free, new status colliding
            % should be updated
            localTime = 1000;
            msg.oneHopSlotsStatus = [0, 2, 0, 0];
            msg.oneHopSlotsIds = [0, 0, 0, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg, localTime);

            twoHopSlots = testCase.slotMap.getTwoHopSlotMap();
            expectedLastUpdated = [0, localTime, 0, 0];
            testCase.verifyEqual(twoHopSlots.status, msg.oneHopSlotsStatus);
            testCase.verifyEqual(twoHopSlots.ids, msg.oneHopSlotsIds);
            testCase.verifyEqual(twoHopSlots.lastUpdated, expectedLastUpdated);
        end

        function updateMultiHopSlotCollidingNotExpiredNewOccupied(testCase)
            % slot currently colliding and not expired, new status occupied
            % should not be updated
            % setup slot map
            localTime = 1000;
            msg.oneHopSlotsStatus = [0, 2, 0, 0];
            msg.oneHopSlotsIds = [0, 0, 0, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg, localTime);

            localTime2 = 1300;
            msg2.oneHopSlotsStatus = [0, 1, 0, 0];
            msg2.oneHopSlotsIds = [0, 2, 0, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg2, localTime2);

            twoHopSlots = testCase.slotMap.getTwoHopSlotMap();
            expectedLastUpdated = [0, localTime, 0, 0];
            testCase.verifyEqual(twoHopSlots.status, msg.oneHopSlotsStatus);
            testCase.verifyEqual(twoHopSlots.ids, msg.oneHopSlotsIds);
            testCase.verifyEqual(twoHopSlots.lastUpdated, expectedLastUpdated);
        end

        function updateMultiHopSlotCollidingExpiredNewOccupied(testCase)
            % slot currently colliding and not expired, new status occupied
            % should not be updated
            % setup slot map
            localTime = 1000;
            msg.oneHopSlotsStatus = [0, 2, 0, 0];
            msg.oneHopSlotsIds = [0, 0, 0, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg, localTime);

            localTime2 = 1500;
            msg2.oneHopSlotsStatus = [0, 1, 0, 0];
            msg2.oneHopSlotsIds = [0, 2, 0, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg2, localTime2);

            twoHopSlots = testCase.slotMap.getTwoHopSlotMap();
            expectedLastUpdated = [0, localTime2, 0, 0];
            testCase.verifyEqual(twoHopSlots.status, msg2.oneHopSlotsStatus);
            testCase.verifyEqual(twoHopSlots.ids, msg2.oneHopSlotsIds);
            testCase.verifyEqual(twoHopSlots.lastUpdated, expectedLastUpdated);
        end

        function updateMultiHopSlotOccupiedExpiredNewFree(testCase)
            % slot currently occupied but expired, new status free
            % should be updated

            localTime = 1000;
            msg.oneHopSlotsStatus = [0, 1, 0, 0];
            msg.oneHopSlotsIds = [0, 1, 0, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg, localTime);

            localTime2 = 1600;
            msg2.oneHopSlotsStatus = [0, 0, 0, 0];
            msg2.oneHopSlotsIds = [0, 0, 0, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg2, localTime2);

            twoHopSlots = testCase.slotMap.getTwoHopSlotMap();
            expectedLastUpdated = [0, localTime, 0, 0];
            testCase.verifyEqual(twoHopSlots.status, msg2.oneHopSlotsStatus);
            testCase.verifyEqual(twoHopSlots.ids, msg2.oneHopSlotsIds);
            testCase.verifyEqual(twoHopSlots.lastUpdated, expectedLastUpdated);
        end

        function updateMultiHopSlotOccupiedNotExpiredNewFree(testCase)
            % slot currently occupied and not expired, new status free
            % should not be updated

            localTime = 1000;
            msg.oneHopSlotsStatus = [0, 1, 0, 0];
            msg.oneHopSlotsIds = [0, 1, 0, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg, localTime);

            localTime2 = 1400;
            msg2.oneHopSlotsStatus = [0, 0, 0, 0];
            msg2.oneHopSlotsIds = [0, 0, 0, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg2, localTime2);

            twoHopSlots = testCase.slotMap.getTwoHopSlotMap();
            expectedLastUpdated = [0, localTime, 0, 0];
            testCase.verifyEqual(twoHopSlots.status, msg.oneHopSlotsStatus);
            testCase.verifyEqual(twoHopSlots.ids, msg.oneHopSlotsIds);
            testCase.verifyEqual(twoHopSlots.lastUpdated, expectedLastUpdated);
        end

        function slotOccupiedByThisNodeAndReportedOccupiedByOther(testCase)
            % a slot is reported occupied by another node, but the slot is
            % also own slot of the receiving node
            % slot should be set to colliding (and not to occupied) to 
            % prevent deadlocks

            % add own slot
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);
            
            testCase.slotMap.addAcknowledgedPendingSlotsToOwn();

            msg.oneHopSlotsStatus = [0, 0, 1, 0];
            msg.oneHopSlotsIds = [0, 0, 2, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg, localTime);


            twoHopSlots = testCase.slotMap.getTwoHopSlotMap();
            expectedStatus = [0, 0, 2, 0];
            expectedIds = [0, 0, 0, 0];
            expectedLastUpdated = [0, 0, localTime, 0];
            testCase.verifyEqual(twoHopSlots.status, expectedStatus);
            testCase.verifyEqual(twoHopSlots.ids, expectedIds);
            testCase.verifyEqual(twoHopSlots.lastUpdated, expectedLastUpdated);
        end

        function slotPendingByThisNodeAndReportedOccupiedByOther(testCase)
            % a slot is reported occupied by another node, but the slot is
            % also own slot of the receiving node
            % slot should be set to colliding (and not to occupied) to 
            % prevent deadlocks

            % add own slot
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);
            
            msg.oneHopSlotsStatus = [0, 0, 1, 0];
            msg.oneHopSlotsIds = [0, 0, 2, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg, localTime);


            twoHopSlots = testCase.slotMap.getTwoHopSlotMap();
            expectedStatus = [0, 0, 2, 0];
            expectedIds = [0, 0, 0, 0];
            expectedLastUpdated = [0, 0, localTime, 0];
            testCase.verifyEqual(twoHopSlots.status, expectedStatus);
            testCase.verifyEqual(twoHopSlots.ids, expectedIds);
            testCase.verifyEqual(twoHopSlots.lastUpdated, expectedLastUpdated);
        end

        %% addPendingSlot

        function addPendingSlotCurrentlyEmpty(testCase)
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);

            result = testCase.slotMap.isPendingSlot(testSlot);

            testCase.verifyTrue(result);
        end

        %% isPendingSlot

        function isPendingSlotWorks(testCase)
            testCase.slotMap.setId(42);
            testSlot = 3;
            testSlot2 = 5;
            neighbors = [];
            localTime = 1000;

            resultBefore = testCase.slotMap.isPendingSlot(testSlot);
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);            
            resultAfter = testCase.slotMap.isPendingSlot(testSlot);
            resultNotAdded = testCase.slotMap.isPendingSlot(testSlot2);

            testCase.verifyFalse(resultBefore);
            testCase.verifyTrue(resultAfter);
            testCase.verifyFalse(resultNotAdded);
        end

        %% updatePendingSlotAcks

        function addSlotThatWasAcknowledged(testCase)
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);

            msg.oneHopSlotsStatus = [0, 0, 1, 0];
            msg.oneHopSlotsIds = [0, 0, 42, 0];
            msg.senderId = 2;
            
            acknowledgedBy = testCase.slotMap.updatePendingSlotAcks(msg);

            testCase.verifyTrue(ismember(msg.senderId, acknowledgedBy(testSlot, :)));
        end

        function dontAddSlotIfItsNotPending(testCase)
            testCase.slotMap.setId(42);
            testSlot = 3;

            msg.oneHopSlotsStatus = [0, 0, 1, 0];
            msg.oneHopSlotsIds = [0, 0, 42, 0];
            msg.senderId = 2;
            
            acknowledgedBy = testCase.slotMap.updatePendingSlotAcks(msg);

            testCase.verifyFalse(ismember(msg.senderId, acknowledgedBy(testSlot, :)));
        end

        function dontAddSlotIfIdIsNotOwn(testCase)
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);

            msg.oneHopSlotsStatus = [0, 0, 1, 0];
            msg.oneHopSlotsIds = [0, 0, 2, 0];
            msg.senderId = 2;
            
            acknowledgedBy = testCase.slotMap.updatePendingSlotAcks(msg);

            testCase.verifyFalse(ismember(msg.senderId, acknowledgedBy(testSlot, :)));
        end

        %% addAcknowledgedPendingSlotsToOwn

        function addsPendingSlotIfNoNeighbors(testCase)
            % no neighbors so no acknowledgement necessary
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);
            
            testCase.slotMap.addAcknowledgedPendingSlotsToOwn();
            
            ownSlots = testCase.slotMap.getOwnSlots();

            testCase.verifyTrue(ismember(testSlot, ownSlots));
            testCase.verifyFalse(testCase.slotMap.isPendingSlot(testSlot));
        end

        function addAcknowledgedSlotConsidersNeighbors(testCase)
            % all neighbors that were already neighbors when the pending
            % slot was added need to acknowledge it, unless they are not
            % neighbors anymore; 

            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [2, 4];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);

            % let first neighbor ack
            msg.oneHopSlotsStatus = [0, 0, 1, 0];
            msg.oneHopSlotsIds = [0, 0, 42, 0];
            msg.senderId = 2;
            
            acknowledgedBy = testCase.slotMap.updatePendingSlotAcks(msg);

            testCase.slotMap.addAcknowledgedPendingSlotsToOwn();
            
            ownSlots = testCase.slotMap.getOwnSlots();

            testCase.verifyFalse(ismember(testSlot, ownSlots));
            testCase.verifyTrue(testCase.slotMap.isPendingSlot(testSlot));
            
            % let second neighbor ack
            msg.oneHopSlotsStatus = [0, 0, 1, 0];
            msg.oneHopSlotsIds = [0, 0, 42, 0];
            msg.senderId = 4;
            
            acknowledgedBy = testCase.slotMap.updatePendingSlotAcks(msg);

            testCase.slotMap.addAcknowledgedPendingSlotsToOwn();
            
            ownSlots = testCase.slotMap.getOwnSlots();

            testCase.verifyTrue(ismember(testSlot, ownSlots));
            testCase.verifyFalse(testCase.slotMap.isPendingSlot(testSlot));
        end
        
        function addAcknowledgedSlotConsidersTheCorrectNeighbors(testCase)
            % two neighbors ack, but one neighbor that needs to ack does
            % not, so slot should not be added to own

            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [2, 4];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);

            % let first neighbor ack
            msg.oneHopSlotsStatus = [0, 0, 1, 0];
            msg.oneHopSlotsIds = [0, 0, 42, 0];
            msg.senderId = 2;
           
            acknowledgedBy = testCase.slotMap.updatePendingSlotAcks(msg);

            % let wrong neighbor ack
            msg.oneHopSlotsStatus = [0, 0, 1, 0];
            msg.oneHopSlotsIds = [0, 0, 42, 0];
            msg.senderId = 1;
            
            acknowledgedBy = testCase.slotMap.updatePendingSlotAcks(msg);

            testCase.slotMap.addAcknowledgedPendingSlotsToOwn();
            
            ownSlots = testCase.slotMap.getOwnSlots();

            testCase.verifyFalse(ismember(testSlot, ownSlots));
            testCase.verifyTrue(testCase.slotMap.isPendingSlot(testSlot));
        end

        %% isOwnSlot
        function isOwnSlotWorks(testCase)
            testCase.slotMap.setId(42);
            testSlot = 3;
            testSlot2 = 5;
            neighbors = [];
            localTime = 1000;

            resultBefore = testCase.slotMap.isPendingSlot(testSlot);
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime); 

            msg.oneHopSlotsStatus = [0, 0, 1, 0];
            msg.oneHopSlotsIds = [0, 0, 42, 0];
            msg.senderId = 2;
            acknowledgedBy = testCase.slotMap.updatePendingSlotAcks(msg);

            testCase.slotMap.addAcknowledgedPendingSlotsToOwn();

            resultAfter = testCase.slotMap.isOwnSlot(testSlot);
            resultNotAdded = testCase.slotMap.isOwnSlot(testSlot2);
            
            testCase.verifyFalse(resultBefore);
            testCase.verifyTrue(resultAfter);
            testCase.verifyFalse(resultNotAdded);
        end

        %% checkOwnSlotsForCollisions / checkSlotsForCollisions

        function checkOwnSlotsWhenEmpty(testCase)
            testCase.slotMap.setId(42);

            msg.oneHopSlotsStatus = [1, 1, 1, 1];
            msg.oneHopSlotsIds = [1, 2, 3, 4];

            collidingOwnSlots = testCase.slotMap.checkOwnSlotsForCollisions(msg);

            testCase.verifyEmpty(collidingOwnSlots);
        end

        function checkOwnSlotsWhenColldingOneHop(testCase)
            % own slot is reported colliding in one hop slot map

            % add own slot
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);
            testCase.slotMap.addAcknowledgedPendingSlotsToOwn();

            msg.oneHopSlotsStatus = [0, 0, 2, 0];
            msg.oneHopSlotsIds = [0, 0, 0, 0];
            msg.twoHopSlotsStatus = [0, 0, 1, 0];
            msg.twoHopSlotsIds = [0, 0, 42, 0];
            msg.senderId = 2;

            collidingOwnSlots = testCase.slotMap.checkOwnSlotsForCollisions(msg);

            testCase.verifyTrue(ismember(testSlot, collidingOwnSlots));
        end

        function checkOwnSlotsWhenColldingTwoHop(testCase)
            % own slot is reported colliding in two hop slot map

            % add own slot
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);
            testCase.slotMap.addAcknowledgedPendingSlotsToOwn();
            
            msg.oneHopSlotsStatus = [0, 0, 1, 0];
            msg.oneHopSlotsIds = [0, 0, 42, 0];
            msg.twoHopSlotsStatus = [0, 0, 2, 0];
            msg.twoHopSlotsIds = [0, 0, 0, 0];
            msg.senderId = 2;

            collidingOwnSlots = testCase.slotMap.checkOwnSlotsForCollisions(msg);

            testCase.verifyTrue(ismember(testSlot, collidingOwnSlots));
        end

        function checkOwnSlotsWhenOccupiedOneHop(testCase)
            % own slot is reported occupied by another node in one hop slot
            % map

            % add own slot
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);
            testCase.slotMap.addAcknowledgedPendingSlotsToOwn();

            msg.oneHopSlotsStatus = [0, 0, 1, 0];
            msg.oneHopSlotsIds = [0, 0, 3, 0];
            msg.twoHopSlotsStatus = [0, 0, 1, 0];
            msg.twoHopSlotsIds = [0, 0, 42, 0];
            msg.senderId = 2;

            collidingOwnSlots = testCase.slotMap.checkOwnSlotsForCollisions(msg);

            testCase.verifyTrue(ismember(testSlot, collidingOwnSlots));
        end

        function checkOwnSlotsWhenOccupiedTwoHop(testCase)
            % own slot is reported occupied by another node in two hop slot
            % map

            % add own slot
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);
            testCase.slotMap.addAcknowledgedPendingSlotsToOwn();

            msg.oneHopSlotsStatus = [0, 0, 1, 0];
            msg.oneHopSlotsIds = [0, 0, 42, 0];
            msg.twoHopSlotsStatus = [0, 0, 1, 0];
            msg.twoHopSlotsIds = [0, 0, 3, 0];
            msg.senderId = 2;

            collidingOwnSlots = testCase.slotMap.checkOwnSlotsForCollisions(msg);

            testCase.verifyTrue(ismember(testSlot, collidingOwnSlots));
        end

        function slotReportedTwiceIsOnlyReturnedOnce(testCase)
            % add own slot
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);
            testCase.slotMap.addAcknowledgedPendingSlotsToOwn();

            msg.oneHopSlotsStatus = [0, 0, 2, 0];
            msg.oneHopSlotsIds = [0, 0, 0, 0];
            msg.twoHopSlotsStatus = [0, 0, 2, 0];
            msg.twoHopSlotsIds = [0, 0, 0, 0];
            msg.senderId = 2;

            collidingOwnSlots = testCase.slotMap.checkOwnSlotsForCollisions(msg);

            testCase.verifyTrue(size(unique(collidingOwnSlots), 2) == size(collidingOwnSlots, 2));
        end

        function findMultipleCollidingOwnSlots(testCase)
            % add own slot
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);
            testSlot2 = 1;
            testCase.slotMap.addPendingSlot(testSlot2, neighbors, localTime);
            testCase.slotMap.addAcknowledgedPendingSlotsToOwn();

            msg.oneHopSlotsStatus = [0, 0, 2, 0];
            msg.oneHopSlotsIds = [0, 0, 0, 0];
            msg.twoHopSlotsStatus = [2, 0, 0, 0];
            msg.twoHopSlotsIds = [0, 0, 0, 0];
            msg.senderId = 2;

            collidingOwnSlots = testCase.slotMap.checkOwnSlotsForCollisions(msg);

            testCase.verifyTrue(ismember(testSlot, collidingOwnSlots));
            testCase.verifyTrue(ismember(testSlot2, collidingOwnSlots));
        end

        %% releaseSlots

        function dontReleaseSlotWhenEmpty(testCase)
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);
            testCase.slotMap.addAcknowledgedPendingSlotsToOwn();

            ownSlotsBefore = testCase.slotMap.getOwnSlots();

            slotsToRelease = [];
            testCase.slotMap.releaseOwnSlots(slotsToRelease);

            ownSlotsAfter = testCase.slotMap.getOwnSlots();

            testCase.verifyEqual(ownSlotsAfter, ownSlotsBefore);
        end

        function dontReleaseWhenNoOwnSlots(testCase)
            testCase.slotMap.setId(42);
            slotsToRelease = [3];
            testCase.slotMap.releaseOwnSlots(slotsToRelease);

            ownSlotsAfter = testCase.slotMap.getOwnSlots();

            testCase.verifyEqual(ownSlotsAfter, []);
        end

        function releaseSlotsWhenNotEmpty(testCase)
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);
            testSlot2 = 1;
            testCase.slotMap.addPendingSlot(testSlot2, neighbors, localTime);
            testCase.slotMap.addAcknowledgedPendingSlotsToOwn();

            slotsToRelease = [3];
            testCase.slotMap.releaseOwnSlots(slotsToRelease);

            ownSlots = testCase.slotMap.getOwnSlots();

            testCase.verifyFalse(ismember(3, ownSlots));
            testCase.verifyTrue(ismember(1, ownSlots));
        end

        function removeReleasedSlotsFromOtherSlotMaps(testCase)
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);
            testSlot2 = 1;
            testCase.slotMap.addPendingSlot(testSlot2, neighbors, localTime);
            testCase.slotMap.addAcknowledgedPendingSlotsToOwn();

            localTime = 1000;
            msg.oneHopSlotsStatus = [1, 1, 1, 0];
            msg.oneHopSlotsIds = [42, 2, 42, 0];
            msg.twoHopSlotsStatus = [1, 1, 1, 0];
            msg.twoHopSlotsIds = [42, 2, 42, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg, localTime);
            testCase.slotMap.updateThreeHopSlotMap(msg, localTime);

            slotsToRelease = [3, 1];
            testCase.slotMap.releaseOwnSlots(slotsToRelease);

            twoHopSlotMap = testCase.slotMap.getTwoHopSlotMap();
            threeHopSlotMap = testCase.slotMap.getThreeHopSlotMap();

            expectedStatus = [0, 1, 0, 0];
            expectedIds = [0, 2, 0, 0];

            testCase.verifyEqual(twoHopSlotMap.status, expectedStatus);
            testCase.verifyEqual(twoHopSlotMap.ids, expectedIds);
            testCase.verifyEqual(threeHopSlotMap.status, expectedStatus);
            testCase.verifyEqual(threeHopSlotMap.ids, expectedIds);
        end

        %% slotReservationGoalMet

        function slotReservationGoalNotMet(testCase)
            result = testCase.slotMap.slotReservationGoalMet();

            testCase.verifyFalse(result);
        end

        function slotReservationGoalMetWithOwnSlots(testCase)
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);
            testCase.slotMap.addAcknowledgedPendingSlotsToOwn();

            result = testCase.slotMap.slotReservationGoalMet();

            testCase.verifyTrue(result);
        end

        function slotReservationGoalMetWithPendingSlots(testCase)
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);

            result = testCase.slotMap.slotReservationGoalMet();

            testCase.verifyTrue(result);
        end

        %% getReservableSlot
        function excludeOccupiedSlotsInOneHopMap(testCase)
            import matlab.mock.constraints.WasCalled;
            % occupied slot in any slot map should not be considered for
            % reservation 
            localTime = 1000;
            currentSlot = 1;
            msg.type = MessageTypes.PING;
            msg.senderId = 3;
            msg.oneHopSlotsStatus = [0, 0, 0, 0];
            msg.oneHopSlotsIds = [0, 0, 0, 0];

            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime);

            slot = testCase.slotMap.getReservableSlot();
            reservableSlots = [2, 3, 4];

            testCase.verifyThat(testCase.randomNumbersBehaviour.getRandomElementFrom(reservableSlots), WasCalled('WithCount', 1));
        end

        function excludeOccupiedSlotsInTwoHopMap(testCase)
            import matlab.mock.constraints.WasCalled;
            % occupied slot in any slot map should not be considered for
            % reservation 
            localTime = 1000;
            msg.oneHopSlotsStatus = [0, 1, 0, 0];
            msg.oneHopSlotsIds = [0, 2, 0, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg, localTime);

            slot = testCase.slotMap.getReservableSlot();
            reservableSlots = [1, 3, 4];

            testCase.verifyThat(testCase.randomNumbersBehaviour.getRandomElementFrom(reservableSlots), WasCalled('WithCount', 1));
        end

        function excludeOccupiedSlotsInThreeHopMap(testCase)
            import matlab.mock.constraints.WasCalled;
            % occupied slot in any slot map should not be considered for
            % reservation 
            localTime = 1000;
            msg.twoHopSlotsStatus = [0, 0, 1, 0];
            msg.twoHopSlotsIds = [0, 0, 3, 0];

            testCase.slotMap.updateThreeHopSlotMap(msg, localTime);

            slot = testCase.slotMap.getReservableSlot();
            reservableSlots = [1, 2, 4];

            testCase.verifyThat(testCase.randomNumbersBehaviour.getRandomElementFrom(reservableSlots), WasCalled('WithCount', 1));
        end

        function combineAllSlotMaps(testCase)
            import matlab.mock.constraints.WasCalled;
            % occupied slot in any slot map should not be considered for
            % reservation 
            localTime = 1000;
            currentSlot = 1;
            msg.type = MessageTypes.PING;
            msg.senderId = 3;
            msg.oneHopSlotsStatus = [0, 1, 0, 0];
            msg.oneHopSlotsIds = [0, 2, 0, 0];
            msg.twoHopSlotsStatus = [0, 0, 1, 0];
            msg.twoHopSlotsIds = [0, 0, 3, 0];

            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime);
            testCase.slotMap.updateTwoHopSlotMap(msg, localTime);
            testCase.slotMap.updateThreeHopSlotMap(msg, localTime);

            slot = testCase.slotMap.getReservableSlot();
            reservableSlots = [4];

            testCase.verifyThat(testCase.randomNumbersBehaviour.getRandomElementFrom(reservableSlots), WasCalled('WithCount', 1));
        end

        %% removeExpiredSlotsFromSlotMap

        function expiredSlotsAreRemovedFromOneHop(testCase)
            localTime = 1000;
            currentSlot = 1;
            msg.type = MessageTypes.PING;
            msg.senderId = 3;
            msg.oneHopSlotsStatus = [0, 1, 0, 0];
            msg.oneHopSlotsIds = [0, 2, 0, 0];
            msg.twoHopSlotsStatus = [0, 0, 1, 0];
            msg.twoHopSlotsIds = [0, 0, 3, 0];

            testCase.slotMap.updateOneHopSlotMap(msg, currentSlot, localTime);

            localTime2 = 1300;
            currentSlot = 4;
            msg2.type = MessageTypes.PING;
            msg2.senderId = 3;
            msg2.oneHopSlotsStatus = [0, 0, 0, 1];
            msg2.oneHopSlotsIds = [0, 0, 0, 1];

            testCase.slotMap.updateOneHopSlotMap(msg2, currentSlot, localTime2);

            localTime3 = 1600;
            testCase.slotMap.removeExpiredSlotsFromOneHopSlotMap(localTime3);

            oneHopSlotMap = testCase.slotMap.getOneHopSlotMap();


            expectedOneHopSlotMapStatus = [0, 0, 0, 1];
            expectedOneHopSlotMapIds = [0, 0, 0, 3];
            testCase.verifyEqual(oneHopSlotMap.status, expectedOneHopSlotMapStatus);
            testCase.verifyEqual(oneHopSlotMap.ids, expectedOneHopSlotMapIds);
        end

        function expiredSlotsAreRemovedFromTwoHop(testCase)
            localTime = 1000;
            currentSlot = 1;
            msg.type = MessageTypes.PING;
            msg.senderId = 3;
            msg.oneHopSlotsStatus = [0, 1, 0, 0];
            msg.oneHopSlotsIds = [0, 2, 0, 0];
            msg.twoHopSlotsStatus = [0, 0, 1, 0];
            msg.twoHopSlotsIds = [0, 0, 3, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg, localTime);

            localTime2 = 1300;
            currentSlot = 4;
            msg2.type = MessageTypes.PING;
            msg2.senderId = 3;
            msg2.oneHopSlotsStatus = [0, 0, 0, 1];
            msg2.oneHopSlotsIds = [0, 0, 0, 1];

            testCase.slotMap.updateTwoHopSlotMap(msg2, localTime2);

            localTime3 = 1600;
            testCase.slotMap.removeExpiredSlotsFromTwoHopSlotMap(localTime3);

            twoHopSlotMap = testCase.slotMap.getTwoHopSlotMap();

            expectedTwoHopSlotMapStatus = [0, 0, 0, 1];
            expectedTwoHopSlotMapIds = [0, 0, 0, 1];
            testCase.verifyEqual(twoHopSlotMap.status, expectedTwoHopSlotMapStatus);
            testCase.verifyEqual(twoHopSlotMap.ids, expectedTwoHopSlotMapIds);
        end

        function expiredSlotsAreRemovedFromThreeHop(testCase)
            localTime = 1000;
            currentSlot = 1;
            msg.type = MessageTypes.PING;
            msg.senderId = 3;
            msg.oneHopSlotsStatus = [0, 1, 0, 0];
            msg.oneHopSlotsIds = [0, 2, 0, 0];
            msg.twoHopSlotsStatus = [0, 0, 1, 0];
            msg.twoHopSlotsIds = [0, 0, 3, 0];

            testCase.slotMap.updateThreeHopSlotMap(msg, localTime);

            localTime3 = 1600;
            testCase.slotMap.removeExpiredSlotsFromThreeHopSlotMap(localTime3);

            threeHopSlotMap = testCase.slotMap.getThreeHopSlotMap();

            expectedThreeHopSlotMapStatus = [0, 0, 0, 0];
            expectedThreeHopSlotMapIds = [0, 0, 0, 0];
            testCase.verifyEqual(threeHopSlotMap.status, expectedThreeHopSlotMapStatus);
            testCase.verifyEqual(threeHopSlotMap.ids, expectedThreeHopSlotMapIds);
        end

        %% removeExpiredPendingSlots

        function removeExpiredPendingSlots(testCase)
            % removes expired slot, does not remove non expired slot

            % add pending slot
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [1];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);

            % add pending slot
            testSlot = 1;
            neighbors = [1];
            localTime = 1300;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);
            
            localTime2 = 2100;
            testCase.slotMap.removeExpiredPendingSlots(localTime2);
            
            testCase.verifyTrue(testCase.slotMap.isPendingSlot(1));
            testCase.verifyFalse(testCase.slotMap.isPendingSlot(3));
        end

        function removeExpiredOwnSlots(testCase)
            % add pending slot
            testCase.slotMap.setId(42);
            testSlot = 3;
            neighbors = [];
            localTime = 1000;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);

            msg.type = MessageTypes.PING;
            msg.senderId = 3;
            msg.oneHopSlotsStatus = [0, 0, 1, 0];
            msg.oneHopSlotsIds = [0, 0, 42, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg, localTime);

            % add pending slot
            testSlot = 1;
            neighbors = [];
            localTime2 = 1300;
            testCase.slotMap.addPendingSlot(testSlot, neighbors, localTime);
            testCase.slotMap.addAcknowledgedPendingSlotsToOwn();

            msg2.type = MessageTypes.PING;
            msg2.senderId = 3;
            msg2.oneHopSlotsStatus = [1, 0, 0, 0];
            msg2.oneHopSlotsIds = [42, 0, 0, 0];

            testCase.slotMap.updateTwoHopSlotMap(msg2, localTime2);

            localTime3 = 2100;
            testCase.slotMap.removeExpiredOwnSlots(localTime3);

            testCase.verifyTrue(testCase.slotMap.isOwnSlot(1));
            testCase.verifyFalse(testCase.slotMap.isOwnSlot(3));
        end

        %% other
        function otherOccupiedSlotsOfNodeAreDeleted(testCase)
            % if every node can only have one slot, and a node attempts to
            % reserve a second one, remove the previous slot (as it is
            % apparently not using it anymore)
            assumeFail(testCase);
        end

    end

end