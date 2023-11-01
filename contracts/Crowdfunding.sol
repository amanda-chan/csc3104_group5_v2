// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Import the Project contract and the hardhat console for debugging
import "hardhat/console.sol";
import './Project.sol';

// Define the main Crowdfunding contract
contract Crowdfunding {
    address public admin; // Admin's Ethereum address. Used for privileged functions.

    // Struct to represent a Project Creation Request
    struct ProjectRequest {
        address requester;                 // Address of the person who requests the project
        uint256 targetContribution;        // Goal amount to raise for the project
        uint256 minimumContribution;       // Minimum amount a contributor can contribute
        string projectTitle;               // Title of the project
        string projectDesc;                // Description of the project
        bool approved;                     // Flag to denote if the project request is approved by the admin
    }

    // Mapping to keep track of each creator's project
    mapping(address => address) public creatorsToProjects;

    // Map Project contract addresses to their IDs
    mapping(address => uint) public projectAddressesToIds;

    // Dynamic array to store project creation requests
    ProjectRequest[] public projectRequests;

    // Private dynamic array to store deployed Project contracts
    Project[] private projects;

    // Contract constructor: initializes the contract's state
    constructor() {
        admin = msg.sender; // Set the person who deploys the contract as the admin
    }

    // Modifier to restrict certain functions to the admin only
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this operation!");
        _;
    }

    // Event emitted when a new project request is created
    event ProjectRequestCreated(uint256 requestId, address requester, uint256 goalAmount, string title, string desc);

    // Event emitted when a project is approved and the respective Project contract is deployed
    event ProjectStarted(address indexed projectContractAddress, address indexed creator, uint256 goalAmount, string title, string desc);

    // Event emitted when a contribution is received for a project
    event ContributionReceived(address indexed projectAddress, uint256 contributedAmount, address indexed contributor);

    // Function to allow users to request the creation of a new project
    function requestProjectCreation(uint256 _targetContribution, uint256 _minimumContribution, string memory _projectTitle, string memory _projectDesc) public {
        ProjectRequest memory newRequest = ProjectRequest({
            requester: msg.sender,
            targetContribution: _targetContribution,
            minimumContribution: _minimumContribution,
            projectTitle: _projectTitle,
            projectDesc: _projectDesc,
            approved: false
        });
        projectRequests.push(newRequest);  // Add the new request to the projectRequests array
        emit ProjectRequestCreated(projectRequests.length - 1, msg.sender, _targetContribution, _projectTitle, _projectDesc);
    }

    // Admin function to approve a project creation request and deploy the respective Project contract
    function approveProjectRequest(uint256 _requestId) public onlyAdmin {
        require(_requestId < projectRequests.length, "Invalid request ID");
        require(!projectRequests[_requestId].approved, "Project already approved");

        ProjectRequest storage request = projectRequests[_requestId];
        request.approved = true;

        Project newProject = new Project(request.requester, request.targetContribution, request.minimumContribution, request.projectTitle, request.projectDesc);
        
        // Update the projectAddressesToIds mapping
        projectAddressesToIds[address(newProject)] = _requestId + 1;  // Adding 1 to _requestId since project IDs usually start from 1

        creatorsToProjects[request.requester] = address(newProject);
        projects.push(newProject);

        console.log("New Project Contract Address:", address(newProject));
        emit ProjectStarted(address(newProject), request.requester, request.targetContribution, request.projectTitle, request.projectDesc);
    }

    function getProjectIdByAddress(address _projectAddress) public view returns (uint) {
        uint projectId = projectAddressesToIds[_projectAddress];
        require(projectId != 0, "Project address not found!");
        return projectId;
    }

    // View function to return all the deployed projects
    function returnAllProjects() external view returns(Project[] memory) {
        return projects;
    }

    // Public function allowing anyone to contribute to a project. They must send ether with the function call.
    function contribute(address _projectAddress) public payable {
        Project project = Project(_projectAddress);  // Get the Project contract instance
        require(project.state() == Project.State.Fundraising, 'Invalid state');  // Ensure the project is in Fundraising state
        project.contribute{value: msg.value}(msg.sender);  // Forward the contribution to the project
        emit ContributionReceived(_projectAddress, msg.value, msg.sender);  // Emit an event for the contribution
    }

    // View function to get a creator's project by their Ethereum address
    function getProjectByCreator(address creator) public view returns(address) {
        return creatorsToProjects[creator];  // Return the project's Ethereum address
    }
}