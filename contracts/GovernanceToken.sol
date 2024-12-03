// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GovernanceToken is ERC20, Ownable {
    // Maximum total supply of tokens
    uint256 public constant MAX_SUPPLY = 1_000_000 * 10 ** 18;

    // Vesting periods and allocations
    struct VestingSchedule {
        uint256 totalAmount;
        uint256 released;
        uint256 startTime;
        uint256 cliffDuration;
        uint256 vestingDuration;
    }

    // Mapping of vesting schedules for each address
    mapping(address => VestingSchedule) public vestingSchedules;

    // Events
    event TokensAllocated(address indexed recipient, uint256 amount);
    event TokensVested(address indexed recipient, uint256 amount);

    constructor() ERC20("DexGovernanceToken", "DGT") Ownable(msg.sender) {
        // Initial token allocation to contract owner
        _mint(msg.sender, 100_000 * 10 ** 18);
    }

    // Allocate tokens with vesting
    function allocateTokensWithVesting(
        address _recipient,
        uint256 _amount,
        uint256 _cliffDuration,
        uint256 _vestingDuration
    ) external onlyOwner {
        require(totalSupply() + _amount <= MAX_SUPPLY, "Exceeds max supply");

        vestingSchedules[_recipient] = VestingSchedule({
            totalAmount: _amount,
            released: 0,
            startTime: block.timestamp,
            cliffDuration: _cliffDuration,
            vestingDuration: _vestingDuration
        });

        _mint(_recipient, _amount);
        emit TokensAllocated(_recipient, _amount);
    }

    // Calculate vested tokens
    function calculateVestedTokens(
        address _account
    ) public view returns (uint256) {
        VestingSchedule memory schedule = vestingSchedules[_account];

        // If no vesting schedule or before cliff period
        if (
            schedule.totalAmount == 0 ||
            block.timestamp < schedule.startTime + schedule.cliffDuration
        ) {
            return 0;
        }

        // Calculate vested amount
        uint256 timePassedSinceCliff = block.timestamp -
            (schedule.startTime + schedule.cliffDuration);
        uint256 vestedAmount = (schedule.totalAmount * timePassedSinceCliff) /
            schedule.vestingDuration;

        // Ensure we don't exceed total allocated amount
        return
            vestedAmount > schedule.totalAmount
                ? schedule.totalAmount
                : vestedAmount;
    }

    // Allow token holders to claim vested tokens
    function claimVestedTokens() external {
        VestingSchedule storage schedule = vestingSchedules[msg.sender];

        uint256 vestedAmount = calculateVestedTokens(msg.sender);
        uint256 unclaimedVested = vestedAmount - schedule.released;

        require(unclaimedVested > 0, "No tokens available to claim");

        schedule.released += unclaimedVested;

        emit TokensVested(msg.sender, unclaimedVested);
    }

    // Governance functions for proposal and voting (simplified)
    function createProposal(string memory, uint256) external view {
        require(
            balanceOf(msg.sender) >= 10_000 * 10 ** 18,
            "Insufficient tokens to create proposal"
        );
        // Proposal creation logic would be implemented here
    }
}
