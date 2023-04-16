// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

contract PollBetContract {

    using EnumerableSet for EnumerableSet.AddressSet;
    // State variable to keep track of the total supply of BetCoin tokens
    uint public totalSupply;

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
    event Log(string message);
    event BetCoinMined(address indexed _to, uint256 _amount);


    // Variables
    uint public pollCount;
    uint public betCount;
    // mapping - to store data on blockchain
    mapping(uint => uint) public pollBetTotal;
    mapping(uint => mapping(address => uint)) public pollBets;
    mapping(uint => uint[]) public pollWinners;
    // Mapping to keep track of the balance of BetCoin tokens for each address
    mapping(address => uint) public balances;
    mapping(uint => Bet[]) public pollBetsList;
    mapping(uint => mapping(address => bool)) public hasVoted;
    mapping(uint => mapping(address => Voter)) public voters;
    mapping(uint => EnumerableSet.AddressSet) internal voterAddressSets;

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

    function getPollVotersCount(uint _pollId) public view returns (uint) {
        uint count = 0;
        EnumerableSet.AddressSet storage voterAddresses = voterAddressSets[_pollId];

        for (uint i = 0; i < EnumerableSet.length(voterAddresses); i++) {
            //address voterAddress = EnumerableSet.at(voterAddresses, i);
            count++;
        }

        return count;
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
        addVoterAddressSet(_pollId,msg.sender);

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

    function getTotalBetAmount(uint _pollId) public view returns(uint) {
        uint totalBetAmount = 0;
        for (uint i = 0; i < pollBetsList[_pollId].length; i++) {
            totalBetAmount += pollBetsList[_pollId][i].amount;
        }
        return totalBetAmount;
    }

    function getOdds(uint _pollId, string calldata _pollChoice) public view returns(uint){

        uint totalChoiceAmount = 0;
        Bet[] storage bets = pollBetsList[_pollId];
        for (uint i = 0; i < bets.length; i++) {
            if (keccak256(bytes(bets[i].pollChoice)) == keccak256(bytes(_pollChoice))) {
                totalChoiceAmount += bets[i].amount;
            }
        }
        uint totalBetAmount = getTotalBetAmount(_pollId);
        return totalBetAmount > 0 ? totalChoiceAmount / totalBetAmount : 0;
    }

    function closePoll() public {
        //decidewinner
        //calldistributerewards
        //take encrypted blockchain data
        //decrypt it
        //publish
    }

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

    function addVoterAddressSet(uint _pollId, address _voterAddress) private {
        voterAddressSets[_pollId].add(_voterAddress);
    }

    // Function to mint new BetCoin tokens and add them to the balance of the given address
    function mineBetCoin(address _to, uint _amount) public {
        // Increase the total supply by the specified amount
        totalSupply += _amount;

        // Add the specified amount of tokens to the balance of the given address
        balances[_to] += _amount;

        // Emit an event to notify that new tokens have been mined and added to the balance of the given address
        emit BetCoinMined(_to, _amount);
    }

}