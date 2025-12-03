classdef farkleBackend < handle

    properties (Access = private)

    end

    properties (Access = public)
        currentPlayer
        selectedHand
        selectedSlots
        turnPoints
        gameOver
        currentHandIndex
        currentHand
        mobileDevConnection
        playerScores
        TargetSignalA; % Orientation Azimuth signal
        TargetSignalP; % Orientation Pitch signal
        TargetSignalR; % Orientation Roll signal
        TargetSignalTs; % Signal Time Stamp
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
            obj.selectedSlots = [];
        end

        function connectDevice(obj)
            obj.mobileDevConnection = mobiledev(); % creates mobile connection
            obj.mobileDevConnection.OrientationSensorEnabled = 1; % turns on orientation sensor
            disp('Device Connected!');
        end

        function initialRoll(obj)
            obj.currentHand = randi([1 6], 1, 6); % creates a random 6 length array with each index ranging from 1-6
            obj.selectedHand = [];
            obj.currentHandIndex = 1;
            disp('Running Initial Roll');
        end

        function rollRemainingDice(obj)
            diceRemaining = length(obj.currentHand);
            obj.currentHand = randi([1 6], 1, diceRemaining); % re-rolls the number of dice remaining in players hand
            obj.selectedHand = [];
            obj.currentHandIndex = 1;
        end

        function incrementHandIndex(obj)
            n = length(obj.currentHand);
            obj.currentHandIndex = mod(obj.currentHandIndex, n) + 1; % incrementing +1 from 1 to the length of currentHand, looping back around if needed
        end

        function selectDie(obj, handIndex)
            obj.currentHandIndex = handIndex; % Will cycle through 1-6, moves index of currentHand into new array for scoring. currentHandIndex will shift +1 or -1 depending on sensor controls to be implemented
            obj.selectedHand(end+1) = obj.currentHand(obj.currentHandIndex); % Selects the die at the current hand index and adds it to array selectedHand
            obj.currentHand(obj.currentHandIndex) = []; % dice which was moved to selectedHand is removed from currentHand
        end

        function scoreHand(obj)
            scoringHand = obj.selectedHand;
            counts = histcounts(scoringHand, 0.5:6.5); % creates 1x6 array, each element contains the number of entries with that corresponding index
            % scoring combinations

            % 1. Check for straights (exclusive rules)
            % Full straight: 1–6
            if isequal(counts, [1 1 1 1 1 1])
                obj.turnPoints = obj.turnPoints + 1500;
                return;
            end

            % Partial straight: 1–5
            if isequal(counts(1:5), [1 1 1 1 1])
                obj.turnPoints = obj.turnPoints + 500;
                return;
            end

            % Partial straight: 2–6
            if isequal(counts(2:6), [1 1 1 1 1])
                obj.turnPoints = obj.turnPoints + 750;
                return;
            end

            % 2. Score three-or-more-of-a-kind
            for face = 1:6
                if counts(face) >= 3
            
                    % Base value for three-of-a-kind
                    if face == 1
                        base = 1000;
                    else
                        base = face * 100;
                    end

                    % Multiplier for 4,5,6 of a kind
                    multiplier = 1;

                    if counts(face) == 4
                        multiplier = 2;
                    end
                    if counts(face) == 5
                        multiplier = 4;
                    end
                    if counts(face) == 6
                        multiplier = 8;
                    end

                    obj.turnPoints = obj.turnPoints + (base * multiplier);
                    counts(face) = 0; % Remove these dice from further single-die scoring
                end
            end

            % 3. Score leftover single 1s and 5s only
            if counts(1) == 1
                obj.turnPoints = obj.turnPoints + 100;   % single 1s
            end
            if counts(5) == 1
                obj.turnPoints = obj.turnPoints + 50;    % single 5s  
            end
        end

        function isBust = checkForBust(obj)
            initialHand = obj.currentHand;
            counts = histcounts(initialHand, 0.5:6.5);
            isBust = true;

            % 1. Check for straights
            if isequal(counts, [1 1 1 1 1 1])
                isBust = false; 
                return;
            end
            if isequal(counts(1:5), [1 1 1 1 1])
                isBust = false; 
                return;
            end
            if isequal(counts(2:6), [1 1 1 1 1])
                isBust = false; 
                return;
            end

            % 2. Three+ of a kind
            if any(counts >= 3)
                isBust = false; 
                return;
            end

            % 3. Single 1s or 5s (checking for one or more)
            if counts(1) >= 1
                isBust = false; 
                return;
            end
            if counts(5) >= 1
                isBust = false; 
                return;
            end
        end

        function endTurn(obj)
            obj.playerScores(obj.currentPlayer) = obj.playerScores(obj.currentPlayer) + obj.turnPoints; % adds points from the turn to the players total score

            obj.turnPoints = 0;
            obj.currentHand = [];
            obj.selectedHand = [];
        end

        function switchPlayer(obj)
            obj.currentPlayer = 3 - obj.currentPlayer; % swaps from player 1 to player 2
        end

        function beginLogging(obj)
            obj.mobileDevConnection.Logging = 1;
            [ang, ts] = orientlog(obj.mobileDevConnection);

            if isempty(ang)
                return;
            end

            azimuth = ang(end, 1);
            pitch = ang(end, 2);
            roll = ang(end, 3);

            obj.TargetSignalA = azimuth;
            obj.TargetSignalP = pitch;
            obj.TargetSignalR = roll;

            obj.TargetSignalTs = ts;
        end

        function endLogging(obj)
            obj.mobileDevConnection.Logging = 0;
        end

        function updateOrientation(obj)
            [ang, ts] = orientlog(obj.mobileDevConnection);
    
            % FIX: prevent invalid indexing when no samples exist yet
            if isempty(ang)
                return;
            end

            obj.TargetSignalA  = ang(end, 1);
            obj.TargetSignalP  = ang(end, 2);
            obj.TargetSignalR  = ang(end, 3);
            obj.TargetSignalTs = ts(end);
            %disp(ang(end, :)); % BUGFIX LINE: WILL CONSTANTLY DISPLAY PHONE ORIENTATION VALUES IN CONSOLE
        end
    end
end