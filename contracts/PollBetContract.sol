pragma solidity ^0.8.0;

contract PollBetContract {

    struct Poll {
        uint id;
        address creator;
        uint startTime;
        uint endTime;
        string[] options;
        mapping(address => uint) votes;
        bool isOpen;
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

    // Variables
    uint public pollCount;
    uint public betCount;
    // mapping - to store data on blockchain
    mapping(uint => Poll) public polls;
    mapping(uint => uint) public pollBetTotal;
    mapping(uint => mapping(address => uint)) public pollBets;
    mapping(uint => uint[]) public pollWinners;
    mapping(address => uint) public balances;
    mapping(uint => Bet[]) public pollBetsList;

    function createPoll(uint _startTime, uint _endTime, string[] memory _options) public {
        require(_endTime > _startTime, "Invalid poll end time");
        require(_options.length > 1, "At least two options required");

        pollCount++;
        polls[pollCount] = Poll({
            id: pollCount,
            creator: msg.sender,
            startTime: _startTime,
            endTime: _endTime,
            options: _options,
            isOpen: true
        });

        //write it to blockchain?

        emit PollCreated(pollCount, msg.sender, _startTime, _endTime, _options);
    }

    function getPollVotes(uint pollId) public view returns (uint[] memory) { // should this be public, we have used the requuire statement
        require(block.timestamp > polls[pollId].endTime, "Poll has not ended yet");

        //verify this? this has to be fetched from blockchain
        uint[] memory votes = new uint[](polls[pollId].options.length);

        for (uint i = 0; i < polls[pollId].options.length; i++) {
            votes[i] = pollBets[pollId][address(i)];
        }

        return votes;
    }


    function voteOnPoll(uint _pollId, uint _pollChoice) public {
        Poll storage poll = polls[_pollId];
        require(poll.votes[msg.sender] == 0, "Already voted");
        require(poll.isOpen, "Poll is closed");
        require(block.timestamp >= poll.startTime && block.timestamp <= poll.endTime, "Poll is not active");
        require(_pollChoice >= 0 && _pollChoice < poll.options.length, "Invalid choice");

        poll.votes[msg.sender] = _pollChoice;
    }

    function betOnPoll(uint _pollId, string _pollChoice) public payable {
        require(block.timestamp >= polls[_pollId].startTime, "Poll has not started yet, you cannot bet on it");
        require(block.timestamp < polls[_pollId].endTime, "Poll has ended, you cannot bet on it anymore");
        require(msg.value > 0, "Amount must be greater than 0!");

        // Convert poll choice to uint
        uint pollChoiceInt;
        for (uint i = 0; i < polls[_pollId].options.length; i++) {
            if (keccak256(bytes(polls[_pollId].options[i])) == keccak256(bytes(_pollChoice))) {
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
            pollChoice: _pollChoice,
            user: msg.sender,
            amount: msg.value
        }));

        emit BetPlaced(_pollId, _pollChoice, msg.sender, msg.value);
    }

    function getBetCount(){}

    function getOdds(){}

    function closePoll(){} //publish to blockchain as well

    function distributeRewards(){}
}