// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol";

contract Crowdfunding {
    struct Project {
        address owner;
        string title;
        string description;
        uint fundingGoal;
        uint raised;
        uint deadline;
        bool funded;
    }

    ERC20 public token;
    mapping(uint => Project) public projects;
    uint public nextProjectId = 0;
    mapping(uint => mapping(address => uint)) public balances;

    event ProjectCreated(uint projectId, address owner, string title, string description, uint fundingGoal, uint deadline);
    event FundingReceived(uint projectId, address backer, uint amount, uint raised);
    event ProjectFunded(uint projectId, uint totalFunds);
    event FundingRefunded(uint projectId, address backer, uint amount, uint raised);

    constructor(ERC20 _tokenAddress) {
        token = _tokenAddress;
    }

    function createProject(string memory title, string memory description, uint fundingGoal, uint durationInSeconds) external {
        uint deadline = block.timestamp + durationInSeconds;
        Project memory newProject = Project(msg.sender, title, description, fundingGoal, 0, deadline, false);
        projects[nextProjectId]  = newProject;
        nextProjectId++;
        emit ProjectCreated(nextProjectId - 1, msg.sender, title, description, fundingGoal, deadline);
    }

    function fundProject(uint projectId, uint amount) external {
        require(token.balanceOf(msg.sender) >= amount, "You need enough tokens to make a donation");
        Project storage project = projects[projectId];
        require(block.timestamp <= project.deadline, "The deadline for funding the project has passed");
        balances[projectId][msg.sender] += amount;
        project.raised += amount;
        token.transferFrom(msg.sender, address(this), amount);
        emit FundingReceived(projectId, msg.sender, amount, project.raised);
        if (project.raised >= project.fundingGoal) {
            project.funded = true;
            emit ProjectFunded(projectId, project.raised);
        }
    }

    function claimFunds(uint projectId) external {
        Project storage project = projects[projectId];
        require(project.funded && project.owner == msg.sender, "The project must be funded and the caller must be the project owner to claim funds");
        require(block.timestamp > project.deadline, "Project is still active");
        token.transfer(project.owner, project.raised);
        project.raised = 0;
        project.fundingGoal = 0;
        project.funded = false;
    }

    function refund(uint projectId) external {
        Project storage project = projects[projectId];
        uint amount = balances[projectId][msg.sender];
        require(amount > 0, "The caller must have a balance in the project to claim a refund");
        require(!project.funded, "The project must not be funded to claim a refund");
        require(block.timestamp > project.deadline, "Project is still active");
        balances[projectId][msg.sender] = 0;
        token.transfer(msg.sender, amount);
        project.raised -= amount;
        emit FundingRefunded(projectId, msg.sender, amount, project.raised);
    }
}