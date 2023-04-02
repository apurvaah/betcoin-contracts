pragma solidity ^0.8.0;

contract PollBetContract {

    struct Poll {
        uint id;
        address creator;
        uint startTime;
        uint endTime;
        //mapping(address => uint) votes;
    }

    struct Bet {
        uint pollId;
        uint pollChoice;
        address user;
        uint amount;
    }

    function createPoll(){}

    function getPollCount(){} //condition: only after poll ends

    function voteOnPoll(){}

    function betOnPoll(){}

    function getBetCount(){}

    function getOdds(){}

    function closePoll(){} //publish to blockchain as well

    function distributeRewards(){}
}