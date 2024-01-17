// Candidates ID starts from 1
/* 
Decentralized Voting System

Problem Description:
Design a decentralized voting system smart contract using Solidity. The contract should support the
following features:
● Users can register to vote.
● The owner of the contract can add candidates.
● Registered voters can cast their votes for a specific candidate.
● The voting process should be transparent, and the results should be publicly accessible.
Requirements:
● Implement the smart contract in Solidity.
● Use appropriate data structures to store voter information and election results.
● Ensure that voters can only vote once.
● Include events to log important actions.
*/

/*
Design choice :
1 address for owner
2 structs for candidate & voter needed
2 mappings for identifying candidate & voter
There are 3 major event: Candidate Registered, Voter Registered, Vote Casted, Declare Winner
*/


// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

contract DecentralizedVotingSystem {
    address public owner;
    uint public candidatesCount;
    
    // Struct to represent a candidate
    struct Candidate {
        string name;
        uint256 voteCount;
    }
    
    // Struct to represent a registered voter
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedCandidateId;
    }
    
    // Mapping from candidate ID to Candidate struct
    mapping(uint256 => Candidate) public candidates;
    
    // Mapping from voter's address to Voter struct
    mapping(address => Voter) public voters;
    
    // Event to log when a new candidate is added
    event CandidateAdded(uint256 candidateId, string name);
    
    // Event to log when a voter is registered
    event VoterRegistered(address voterAddress);
    
    // Event to log when a vote is cast
    event VoteCasted(address voterAddress, uint256 candidateId);

    // Event to declare winner
    event DeclareWinner(string winner);
    
    // Constructor to set the owner of the contract
    constructor() {
        owner = msg.sender;
    }
    
    // Modifier to ensure that only the owner can perform certain actions
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
    
    // Function for the owner to add a new candidate
    function addCandidate(string memory _name) public onlyOwner {
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(_name, 0);
        emit CandidateAdded(candidatesCount, _name);
    }
    
    // Function for users to register to vote
    function registerToVote() public {
        require(!voters[msg.sender].isRegistered, "Already registered to vote");
        voters[msg.sender].isRegistered = true;
        emit VoterRegistered(msg.sender);
    }
    
    // Function for registered voters to cast their vote
    function vote(uint256 _candidateId) public {
        require(voters[msg.sender].isRegistered, "Not registered to vote");
        require(!voters[msg.sender].hasVoted, "Already voted");
        require(_candidateId > 0 && _candidateId <= candidatesCount, "Invalid candidate");
        
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedCandidateId = _candidateId;
        candidates[_candidateId].voteCount++;
        
        emit VoteCasted(msg.sender, _candidateId);
    }

     // Function to get the winner
    function getWinner() public returns (string memory) {
        require(msg.sender == owner, "Only the owner can check the winner");

        uint256 maxVotes = 0;
        string memory winnerName;

        for (uint256 i = 1; i <= candidatesCount; i++) {
            if (candidates[i].voteCount > maxVotes) {
                maxVotes = candidates[i].voteCount;
                winnerName = candidates[i].name;
            } else if (candidates[i].voteCount == maxVotes) {
                // Handle a draw if needed
                winnerName = "Draw";
            }
        }
        emit DeclareWinner(winnerName);
        return winnerName;

    }
}
