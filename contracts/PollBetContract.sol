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

    function getPollCount(){} //condition: only after poll ends

    function voteOnPoll(){}

    function betOnPoll(){}

    function getBetCount(){}

    function getOdds(){}

    function closePoll(){} //publish to blockchain as well

    function distributeRewards(){}
}