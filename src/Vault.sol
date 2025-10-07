// SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

contract Vault {
    // Pass token address to the constructor
    // create a deposit function that mints tokens to the user equal to the ETH the user has sent
    // create a redeem function that burns tokens from the user and send the user ETH
    // create a way to add rewards to the vault

    address private immutable i_rebaseToken;

    constructor(address _rebaseToken) {
        i_rebaseToken = _rebaseToken;
    }

    function getRebaseTokenAddress() external view returns (address) {
        return i_rebaseToken;
    }
}
