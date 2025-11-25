classdef farkleBackend < handle

    properties (Access = private)
        mobileDevConnection
        playerScores
        currentPlayer
        currentHand
        currentHandIndex
        selectedHand
        turnPoints
        gameOver
    end

    methods

        function obj = farkleBackend()
            % initialize game state
            obj.playerScores = [0 0];
            obj.currentPlayer = 1;
            obj.currentHand = [];
            obj.selectedHand = [];
            obj.turnPoints = 0;
            obj.gameOver = false;
        end

        function connectDevice(obj)
            obj.mobileDevConnection = mobiledev; % creates mobile connection
            obj.mobileDevConnection.AccelerationSensorEnabled = 1; % turns on acceleration sensor
            disp('Device Connected!');
        end

        function initialRoll(obj)
            obj.currentHand = randi([1 6], 1, 6); % creates a random 6 length array with each index ranging from 1-6
            obj.selectedHand = [];
        end

        function rollRemainingDice(obj)
            diceRemaining = length(obj.currentHand);
            obj.currentHand = randi([1 6], 1, diceRemaining); % re-rolls the number of dice remaining in players hand
            obj.selectedHand = [];

        end

        function selectDie(obj, handIndex)
            obj.currentHandIndex = handIndex; % Will cycle through 1-6, moves index of currentHand into new array for scoring. currentHandIndex will shift +1 or -1 depending on sensor controls to be implemented
            obj.selectedHand(end+1) = obj.currentHand(obj.currentHandIndex); % Selects the die at the current hand index and adds it to array selectedHand
            obj.currentHand(obj.currentHandIndex) = []; % dice which was moved to selectedHand is removed from currentHand
        end
    end
end