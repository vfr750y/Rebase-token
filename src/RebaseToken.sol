// SPDX-License-Identifier:MIT

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
import {Ownable} from "@openzeppelin/contracts/access/ERC20/Ownable.sol";

/**
 * @title Rebase Token
 *
 * @author Ajay Curry
 * @notice This is a cross-chain rebase token that incentivises users to deposit inta a vault and gain interest in reqards
 * @notice the interest rate in the smart contract can only decrease
 * @notice Each user will have their own interest rate which is the global interest rate at the time.
 */
contract RebaseToken is ERC20, Ownable {
    error RebaseToken__InterestRateCanOnlyDecrease(uint256 oldInterestRate, uint256 newInterestRate);

    uint256 private constant PRECISION_FACTOR = 1e18;

    uint256 private s_interestRate = 5e10;
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_userLastUpdatedTimestamp;

    event InterestRateSet(uint256 newInterestRate);

    constructor() ERC20("Rebase Token", "RBT") Ownable(msg.sender) {}

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
     * @notice Get the principle balance of a user. This is the number of tokens currently minted to the user not including ay interst that has accreued since the last time the user interacted with the protocol.
     * @param _user The user to get the principle balance for
     */

    function principleBalanceOf(address _user) external view returns (uint256) {
        return super.balanceOf(_user);
    }

    /**
     * @notice Mint the user tokens when they deposit into the vault
     * @param _to The user to mint the tokens to
     * @param _amount the amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external {
        _mintAccruedInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    /**
     * @notice Burn the user tokens when they withdraw from the vault
     * @param _from The user to burn the tokens from
     * @param _amount The amount to burn
     */
    function burn(address _from, uint256 _amount) external {
        // mitigate for dust (interest accumulated whilst waiting for a transaction to complete)
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_from);
        }
        _mintAccruedInterest(_from);
        _burn(_from, _amount);
    }

    /**
     * @notice Calculate the balance fr the user includinga ny interest cince the last update
     * @param _user The user to calculate the balance for
     * @return The balance of the user including the interest that has accumulated
     */
    function balanceOf(address _user) public view override returns (uint256) {
        // get the current principle balance (the number of tokens that have actually been minted to the user)
        // multiply the principle balance by the interest that has accumulated in the time since the balance was last updated.
        return super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceLastUpdate(_user) / PRECISION_FACTOR;
    }

    /**
     * @notice Transfer tokens from one user to another
     * @param _recipient The user to transfer the tokens to
     * @param _amount  THe user to transfer the tokens from
     */
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }

        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        return super.transfer(_recipient, _amount);
    }

    /**
     * @notice Trnasfer tokens from one user to another
     * @param _sender The user to transfer the tokens from
     * @param _recipient  The user to transfer the tokens to
     * @param _amount  THe amount of tokens to transfer
     */
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        _mintAccruedInterest(msg.sender);
        _mintAccruedInterest(_recipient);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }

        if (balanceOf(_recipient) == 0) {
            s_userInterestRate[_recipient] = s_userInterestRate[msg.sender];
        }
        return super.transferFrom(_sender, _recipient, _amount);
    }

    /**
     * @notice Calculate the interst that has accumulated since the last update
     * @param _user The user to calculate the interest accumulated for
     * @return linearInterest The interest that has acumulated since the last update
     */
    function _calculateUserAccumulatedInterestSinceLastUpdate(address _user)
        internal
        view
        returns (uint256 linearInterest)
    {
        // calculate the time since the last update
        // calculate the amount of linear growth
        // (principal amount) + principal amount * interest rate * time elapsed
        // e.g. deposite = 10 tokens, interest rate 0.5 tokens per second
        // time elapsed is 2 seconds
        // 10 + (10 * 0.5 * 2)

        uint256 timeElapsed = block.timestamp - s_userLastUpdatedTimestamp[_user];
        linearInterest = (PRECISION_FACTOR + (s_userInterestRate[_user] * timeElapsed));
    }
    /**
     * @notice Mint the accrued interest to the user since the last time they interacted with the protocol (e.g. burn, mint, transfer
     * @param _user The user to mint the accrued interest to
     */

    function _mintAccruedInterest(address _user) internal {
        // Principle balance - Find their current balance of rebase tokens that have been minted to the user
        uint256 previousPrincipleBalance = super.balanceOf(_user);

        // Balance of -> calculate thier current balance including any interest
        uint256 currentBalance = balanceOf(_user);

        // calculate the number for tokens that need to be minted to the user (Balance of - Principle balance)
        uint256 balanceIncrease = currentBalance - previousPrincipleBalance;
        // call _mint to mint the tokens to the user
        // set the users last updated timestamp
        s_userLastUpdatedTimestamp[_user] = block.timestamp;
        _mint(_user, balanceIncrease);
    }

    /**
     * @notice Get the interest rate currently set for the contract. Future depositors will receive this interest rate.
     * @return The interest rate for the contract
     */
    function getInterestRate() external view returns (uint256) {
        return s_interestRate;
    }

    /**
     * @notice Get the interest rate for the user
     * @param _user address of the user
     * @return the interest rate for the user
     */
    function getUserInterestRate(address _user) external view returns (uint256) {
        return s_userInterestRate[_user];
    }
}
