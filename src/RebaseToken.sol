// SDPX-License-Identifier: MIT

// Contract Layout
// License
// Version
// Imports
// Interfaces
// Libraries
// -- Contracts
// ----Errors
// ----Type declarations
// ----State Variables
// ----events
// ----modifiers
// ----functions
// ------Constructors
// ------Receive functions
// ------Fallback functions
// ------External functions
// ------Public functions
// ------Internal functions
// ------Private functions
// --------View and pure functions

pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title Rebase Token
 *
 * @author Ajay Curry
 * @notice This is a cross-chain rebase token that incentivises users to deposit inta a vault and gain interest in reqards
 * @notice the interest rate in the smart contract can only decrease
 * @notice Each user will have their own interest rate which is the global interest rate at the time.
 */
contract RebaseToken is ERC20 {
    error RebaseToken__InterestRateCanOnlyDecrease(uint256 oldInterestRate, uint256 newInterestRate);

    uint256 private s_interestRate = 5e10;
    mapping(address => uint256) private s_userInterestRate;

    event InterestRateSet(uint256 newInterestRate);

    constructor() ERC20("Rebase Token", "RBT") {}

    /**
     * @notice Set the inteset rate in the contract
     * @param _newInterestRate New interest rate
     * @dev The interest rate can only decrease
     */
    function setInterestRate(uint256 _newInterestRate) external {
        // Set the interest rate
        if (_newInterestRate < s_interestRate) {
            revert RebaseToken__InterestRateCanOnlyDecrease(s_interestRate, _newInterestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateSet(_newInterestRate);
    }

    /**
     *
     */
    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }
}
