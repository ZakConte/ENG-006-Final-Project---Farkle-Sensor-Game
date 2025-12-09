classdef farkleBackend_p2 < handle

    properties (Access = private)

    end

    properties (Access = public)

        tsChannelID = 3196892;
        tsWriteKey = 'AIVYB5ZSJL8TO06U';
        tsReadKey = 'C8WDRTJ1HDIAEIHN';
        tsPlayerID = 2;

        currentPlayer
        selectedHand
        turnPoints
        gameOver
        gamePoints
        currentHandIndex
        currentHand
        mobileDevConnection
        playerScores
        scoredDice
        loadedDie
        previousScoredDice
        bgPlayer %background music
        TargetSignalA % Orientation Azimuth signal
        TargetSignalP % Orientation Pitch signal
        TargetSignalR % Orientation Roll signal
        TargetSignalTs % Signal Time Stamp
    end

    methods

        function obj = farkleBackend_p2()
            % initialize game state
            obj.playerScores = [0 0];
            obj.currentPlayer = 1;
            obj.currentHand = [];
            obj.selectedHand = [];
            obj.turnPoints = 0;
            obj.scoredDice = 0;
            obj.gameOver = false;
            obj.gamePoints = 1500;
            obj.loadedDie = "None";

            [y, Fs] = audioread('happy medieval.mp3');
            obj.bgPlayer = audioplayer(y,Fs);
            obj.bgPlayer.StopFcn = @(~,~) play(obj.bgPlayer); %loop audio
            play(obj.bgPlayer);
        end

        function connectDevice(obj)
            obj.mobileDevConnection = mobiledev(); % creates mobile connection
            obj.mobileDevConnection.OrientationSensorEnabled = 1; % turns on orientation sensor
            disp('Device Connected!');
        end

        function initialRoll(obj)
            obj.currentHand = randi([1 6], 1, 5); % creates a random 6 length array with each index ranging from 1-6
            obj.rollLoadedDie;
            obj.selectedHand = [];
            obj.currentHandIndex = 1;
            disp('Running Initial Roll');
        end

        function rollRemainingDice(obj)
            diceRemaining = length(obj.currentHand);
            obj.currentHand = randi([1 6], 1, diceRemaining-1); % re-rolls the number of dice remaining in players hand
            obj.rollLoadedDie;
            obj.selectedHand = [];
            obj.currentHandIndex = 1;
            disp('Rerolling Dice');
        end

        function incrementHandIndex(obj)
            n = length(obj.currentHand);
            if n == 0
                return;
            end
            obj.currentHandIndex = mod(obj.currentHandIndex, n) + 1; % incrementing +1 from 1 to the length of currentHand, looping back around if needed
            disp('Incrementing Hand');
        end

        function selectDie(obj, handIndex)
            obj.currentHandIndex = handIndex; % Will cycle through 1-6, moves index of currentHand into new array for scoring. currentHandIndex will shift +1 or -1 depending on sensor controls to be implemented
            obj.selectedHand(end+1) = obj.currentHand(obj.currentHandIndex); % Selects the die at the current hand index and adds it to array selectedHand
            obj.currentHand(obj.currentHandIndex) = []; % dice which was moved to selectedHand is removed from currentHand
            disp('Selecting Dice');
        end

        function scoreHand(obj)
            scoringHand = obj.selectedHand;
            counts = histcounts(scoringHand, 0.5:6.5); % creates 1x6 array, each element contains the number of entries with that corresponding index
            remaining = counts;

            % scoring combinations

            % 1. Check for straights (exclusive rules)
            % Full straight: 1–6
            if isequal(counts, [1 1 1 1 1 1])
                obj.turnPoints = obj.turnPoints + 1500;
                obj.scoredDice = 6;
                return;
            end

            % Partial straight: 1–5
            if isequal(counts(1:5), [1 1 1 1 1]) && counts(6) == 0
                obj.turnPoints = obj.turnPoints + 500;
                obj.scoredDice = 5;
                return;
            end

            % Partial straight: 2–6
            if isequal(counts(2:6), [1 1 1 1 1])
                obj.turnPoints = obj.turnPoints + 750;
                obj.scoredDice = 5;
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

                    n = remaining(face);

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
                    
                    obj.scoredDice = obj.scoredDice + counts(face);
                    remaining(face) = remaining(face) - n; % will be zero if only scoring combinations are selecting
                    obj.turnPoints = obj.turnPoints + (base * multiplier);
                    counts(face) = 0; % Remove these dice from further single-die scoring
                end
            end

            % 3. Score leftover single 1s and 5s only
            if counts(1) == 1
                obj.turnPoints = obj.turnPoints + 100;   % single 1s
                remaining(1) = remaining(1) - 1;
                obj.scoredDice = obj.scoredDice + 1;
            end
            if counts(5) == 1
                obj.turnPoints = obj.turnPoints + 50;    % single 5s
                remaining(5) = remaining(5) - 1;
                obj.scoredDice = obj.scoredDice + 1;
            end

            % checks if any additional non-scoring dice are selected alongside scoring
            % combinations, if so, turnPoints = 0
            if any(remaining > 0)
                obj.turnPoints = 0;
                obj.scoredDice = obj.previousScoredDice;
            end

            disp('Scoring Hand');
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

        function scoreTurn(obj)
            obj.playerScores(obj.currentPlayer) = obj.playerScores(obj.currentPlayer) + obj.turnPoints; % adds points from the turn to the players total score

            obj.turnPoints = 0;
        end

        function switchPlayer(obj)
            obj.currentPlayer = 3 - obj.currentPlayer; % swaps from player 1 to player 2
            obj.scoredDice = 0;
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

        function rollLoadedDie(obj)
            if(obj.loadedDie == "None")
                obj.currentHand = [obj.currentHand, randi([1 6], 1, 1)]; %if no loaded die selected, simply roll an additional regular die
            end
            chance = randi([0 100]);

            % roll for biased die
            if(obj.loadedDie == "Biased Die")
                if(chance <= 25)
                    obj.currentHand = [obj.currentHand, 1];
                elseif(chance <= 58)
                    obj.currentHand = [obj.currentHand, 2];
                elseif(chance <= 66)
                    obj.currentHand = [obj.currentHand, 3];
                elseif(chance <= 75)
                    obj.currentHand = [obj.currentHand, 4];
                elseif(chance <= 92)
                    obj.currentHand = [obj.currentHand, 5];
                else
                    obj.currentHand = [obj.currentHand, 6];
                end
            end

            % roll for Ci Die
            if(obj.loadedDie == "Ci Die")
                if(chance <= 13)
                    obj.currentHand = [obj.currentHand, 1];
                elseif(chance <= 26)
                    obj.currentHand = [obj.currentHand, 2];
                elseif(chance <= 39)
                    obj.currentHand = [obj.currentHand, 3];
                elseif(chance <= 52)
                    obj.currentHand = [obj.currentHand, 4];
                elseif(chance <= 65)
                    obj.currentHand = [obj.currentHand, 5];
                else
                    obj.currentHand = [obj.currentHand, 6];
                end
            end

            % roll for even numbered die
            if(obj.loadedDie == "Even Numbers")
                if(chance <= 7)
                    obj.currentHand = [obj.currentHand, 1];
                elseif(chance <= 33)
                    obj.currentHand = [obj.currentHand, 2];
                elseif(chance <= 40)
                    obj.currentHand = [obj.currentHand, 3];
                elseif(chance <= 66)
                    obj.currentHand = [obj.currentHand, 4];
                elseif(chance <= 73)
                    obj.currentHand = [obj.currentHand, 5];
                else
                    obj.currentHand = [obj.currentHand, 6];
                end
            end

            % roll for ones and fives
            if(obj.loadedDie == "Ones and Fives")
                if(chance <= 20)
                    obj.currentHand = [obj.currentHand, 1];
                elseif(chance <= 35)
                    obj.currentHand = [obj.currentHand, 2];
                elseif(chance <= 50)
                    obj.currentHand = [obj.currentHand, 3];
                elseif(chance <= 65)
                    obj.currentHand = [obj.currentHand, 4];
                elseif(chance <= 85)
                    obj.currentHand = [obj.currentHand, 5];
                else
                    obj.currentHand = [obj.currentHand, 6];
                end
            end

            % roll for odd numbered dice
            if(obj.loadedDie == "Odd Numbers")
                if(chance <= 26)
                    obj.currentHand = [obj.currentHand, 1];
                elseif(chance <= 33)
                    obj.currentHand = [obj.currentHand, 2];
                elseif(chance <= 59)
                    obj.currentHand = [obj.currentHand, 3];
                elseif(chance <= 66)
                    obj.currentHand = [obj.currentHand, 4];
                elseif(chance <= 92)
                    obj.currentHand = [obj.currentHand, 5];
                else
                    obj.currentHand = [obj.currentHand, 6];
                end
            end
        end
        function writeGameState(obj)
            dataValues = [obj.currentPlayer, obj.playerScores(1), obj.playerScores(2)];
            fieldIDs = [1, 2, 3];

           
            thingspeakwrite(obj.tsChannelID, dataValues, ...
                    'FieldName', fieldIDs, ...
                    'WriteKey', obj.tsWriteKey);
            
        end

        function readGameState(obj)
            [readData, ~] = thingspeakread(obj.tsChannelID, 'Fields', [1, 2, 3], ...
                'ReadKey', obj.tsReadKey, ...
                'NumPoints', 1);
            if ~isempty(readData)
                obj.currentPlayer = readData(1);
                obj.playerScores(1) = readData(2);
                obj.playerScores(2) = readData(3);
            end
        end
    end
end