// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";  // Import the Hardhat console for debugging

// Define the main Project contract
contract Project {
    
    // Define the possible states a project can be in
    enum State {
        Fundraising,     // Project is currently raising funds
        Successful       // Project successfully raised the required funds
    }

    // Struct representing a withdrawal request
    struct WithdrawRequest {
        string description;              // Description of the withdrawal
        uint256 amount;                 // Amount requested to withdraw
        uint256 totalVoteWeight;        // Sum of contributions of all voters who voted for this request
        mapping(address => uint256) voters;  // Maps a contributor's address to their contribution amount
        bool isCompleted;               // Flag indicating if the withdrawal is complete
        address payable recipient;      // Recipient of the withdrawal (usually the project creator)
    }

    // State variables
    address payable public creator;               // Ethereum address of the project creator
    uint256 public targetContribution;            // Amount the project aims to raise
    uint256 public minimumContribution;           // Minimum contribution a supporter can make
    uint256 public raisedAmount = 0;              // Total raised so far
    uint256 public noOfContributors;              // Count of distinct contributors
    string public projectTitle;                   // Project's title
    string public projectDes;                     // Project's description
    State public state = State.Fundraising;       // Project's current state
    mapping(address => uint) public contributors; // Maps supporter addresses to the amounts they've contributed
    mapping(uint256 => WithdrawRequest) public withdrawRequests;  // Maps withdrawal request IDs to their details
    uint256 public numOfWithdrawRequests = 0;     // Total number of withdrawal requests

    // Modifiers to enforce function access restrictions
    modifier isCreator() {
        require(msg.sender == creator, 'Only the creator can perform this operation!');
        _;
    }

    // Events to notify frontend applications or external consumers
    event FundingReceived(address contributor, uint amount, uint currentTotal);
    event WithdrawRequestCreated(uint256 requestId, string description, uint256 amount, address recipient);
    event WithdrawVote(address voter, uint256 requestId);
    event AmountWithdrawSuccessful(uint256 requestId, uint256 amount, address recipient);

    // Contract constructor: Called when the contract is deployed
    constructor(address _creator, uint256 _targetContribution, uint256 _minimumContribution, string memory _projectTitle, string memory _projectDes) {
        creator = payable(_creator);            // Set the project creator
        targetContribution = _targetContribution;
        minimumContribution = _minimumContribution;
        projectTitle = _projectTitle;
        projectDes = _projectDes;
        console.log("Project Contract Created at:", address(this));  // Debugging info
    }

    // Function to allow contributors to send funds to the project
    function contribute(address _contributor) public payable {
        require(msg.value >= minimumContribution, "Amount less than the minimum contribution!");
        require(state == State.Fundraising || state == State.Successful, 'Cannot contribute at this stage!');
        if(contributors[_contributor] == 0) {
            noOfContributors++;
        }
        contributors[_contributor] += msg.value;
        raisedAmount += msg.value;

        if(raisedAmount >= targetContribution) {
            state = State.Successful;  // If the target amount is reached, mark the project as successful
        }

        emit FundingReceived(_contributor, msg.value, raisedAmount);  // Emit an event for the contribution
    }

    // Function to check the balance of the contract (how much ether it has)
    function getContractBalance() public view returns(uint256) {
        return address(this).balance;
    }

    // Function allowing the project creator to create a request to withdraw funds
    function createWithdrawRequest(string memory _description, uint256 _amount) public isCreator() {
        require(state == State.Successful, "Project hasn't met its goal yet. You cannot withdraw while the campaign is still ongoing!");
        require(_amount <= address(this).balance, "Requested amount exceeds contract balance");

        WithdrawRequest storage newRequest = withdrawRequests[numOfWithdrawRequests++];
        newRequest.description = _description;
        newRequest.amount = _amount;
        newRequest.recipient = creator;

        emit WithdrawRequestCreated(numOfWithdrawRequests, _description, _amount, creator);  // Emit an event for the withdrawal request
    }

    // Function allowing contributors to vote on a withdrawal request
    function voteWithdrawRequest(uint256 _requestId) public {
        require(contributors[msg.sender] > 0, 'Only contributors can vote!');
        
        WithdrawRequest storage requestDetails = withdrawRequests[_requestId];
        require(requestDetails.voters[msg.sender] == 0, 'You already voted!');

        uint256 voterWeight = contributors[msg.sender];
        requestDetails.voters[msg.sender] = voterWeight;  
        requestDetails.totalVoteWeight += voterWeight;

        emit WithdrawVote(msg.sender, _requestId);
    }

    // Function allowing the project creator to withdraw funds once a request is approved
    function withdrawRequestedAmount(uint256 _requestId) isCreator() public {
        WithdrawRequest storage requestDetails = withdrawRequests[_requestId];
        require(requestDetails.isCompleted == false, 'Request already completed');
        require(requestDetails.totalVoteWeight >= raisedAmount / 2, 'At least 50% contributors (by amount) need to vote for this request');

        requestDetails.recipient.transfer(requestDetails.amount);  // Transfer the requested funds
        requestDetails.isCompleted = true;

        emit AmountWithdrawSuccessful(_requestId, requestDetails.amount, requestDetails.recipient);  // Emit an event for successful withdrawal
    }

    // Function to get the details of the project
    function getProjectDetails() public view returns(
        address payable projectStarter,
        uint256 goalAmount,
        uint256 currentAmount,
        string memory title,
        string memory desc,
        State currentState,
        uint256 balance
    ) {
        projectStarter = creator;
        goalAmount = targetContribution;
        currentAmount = raisedAmount;
        title = projectTitle;
        desc = projectDes;
        currentState = state;
        balance = address(this).balance;
    }
}
