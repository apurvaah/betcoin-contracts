// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PollBetContract {

    struct Poll {
        uint id;
        address creator;
        uint startTime;
        uint endTime;
        string[] choices;
        bool isOpen;
    }

    struct Voter {
        uint pollId;
        address voterAddress;
        uint choice;
    }

    struct Bet {
        uint pollId;
        string pollChoice;
        address user;
        uint amount;
    }

    // Events
    event PollCreated(uint indexed id, address indexed creator, uint startTime, uint endTime, string[] options);
    event PollClosed(uint indexed id, address indexed winner);
    event BetPlaced(uint indexed pollId, string pollChoice, address indexed user, uint amount);
    event RewardsDistributed(uint indexed pollId, address[] winners, uint[] rewards);
    event VoteCasted(uint indexed pollId, address indexed voter, uint choice);


    // Variables
    uint public pollCount;
    uint public betCount;
    // mapping - to store data on blockchain
    mapping(uint => uint) public pollBetTotal;
    mapping(uint => mapping(address => uint)) public pollBets;
    mapping(uint => uint[]) public pollWinners;
    mapping(address => uint) public balances;
    mapping(uint => Bet[]) public pollBetsList;
    mapping(uint => mapping(address => bool)) public hasVoted;
    mapping(uint => mapping(address => Voter)) public voters;

    Poll[] public polls;
    //mapping(uint => Poll) public polls; // change to mapping

    function createPoll(uint _startTime, uint _endTime, string[] memory _options) public {
        require(_endTime > _startTime, "Invalid poll end time");
        require(_options.length > 1, "At least two options required");

        pollCount++;

        Poll memory newPoll = Poll({
            id: pollCount,
            creator: msg.sender,
            startTime: _startTime,
            endTime: _endTime,
            choices: _options,
            isOpen: true
        });

        polls[pollCount] = newPoll;

        emit PollCreated(pollCount, msg.sender, _startTime, _endTime, _options);
    }

    function getPollVotes(uint _pollId) public view returns (uint) { // should this be public, we have used the requuire statement
        require(block.timestamp > polls[_pollId].endTime, "Poll has not ended yet");

        /*uint count = 0;
        mapping(address => Voter) storage pollVoters = voters[_pollId];
        for (uint i = 0; i < pollVoters.length; i++) {
            count++;
        }
        return count;*/
        return 0;
    }

    function voteOnPoll(uint _pollId, uint _pollChoice) public {
        Poll storage poll = polls[_pollId];
        
        require(!hasVoted[_pollId][msg.sender], "Already voted");
        require(poll.isOpen, "Poll is closed");
        require(block.timestamp >= poll.startTime && block.timestamp <= poll.endTime, "Poll is not active");
        require(_pollChoice >= 0 && _pollChoice < poll.choices.length, "Invalid choice");

        hasVoted[_pollId][msg.sender] = true;

        Voter memory newVoter = Voter({
            pollId: _pollId,
            voterAddress: msg.sender,
            choice: _pollChoice
        });
        voters[_pollId][msg.sender] = newVoter;

        emit VoteCasted(_pollId, msg.sender, _pollChoice);
    }

    function betOnPoll(uint _pollId, bytes32 _pollChoice) public payable { // Data location must be "memory" or "calldata" for parameter in function, but none was given
        require(block.timestamp >= polls[_pollId].startTime, "Poll has not started yet, you cannot bet on it");
        require(block.timestamp < polls[_pollId].endTime, "Poll has ended, you cannot bet on it anymore");
        require(msg.value > 0, "Amount must be greater than 0!");

        // Convert poll choice to uint
        uint pollChoiceInt;
        for (uint i = 0; i < polls[_pollId].choices.length; i++) {
            if (keccak256(bytes(polls[_pollId].choices[i])) == _pollChoice) {
                pollChoiceInt = i;
                break;
            }
        }
        require(pollChoiceInt > 0, "Invalid poll choice, please select one of the poll choices to bet on");

        pollBetTotal[_pollId] += msg.value;
        pollBets[_pollId][msg.sender] += msg.value;
        betCount++;

        pollBetsList[_pollId].push(Bet({
            pollId: _pollId,
            pollChoice: bytes32ToString(_pollChoice),
            user: msg.sender,
            amount: msg.value
        }));

        emit BetPlaced(_pollId, bytes32ToString(_pollChoice), msg.sender, msg.value);
    }

    function getBetCount(uint _pollId) public view returns(uint) {
        return pollBetsList[_pollId].length;
    }

    function getOdds(uint _pollId, uint _pollChoice) public view returns(uint){}

    function closePoll() public {} //publish to blockchain as well

    function distributeRewards() public {}

    function bytes32ToString(bytes32 _bytes32) private pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < bytesArray.length; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

}