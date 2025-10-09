//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {RebaseToken} from "../src/RebaseToken.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/Interfaces/IRebaseToken.sol";

contract RebaseTokenTest is Test {
    // storage variable for the token
    RebaseToken private rebaseToken;
    // storage variable for the vault
    Vault private vault;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    function setUp() public {
        // make calls seem to come from the contract owner
        vm.startPrank(owner);

        // Deploy rebase token

        rebaseToken = new RebaseToken();
        // Deploy Vault
        vault = new Vault(IRebaseToken(address(rebaseToken)));
        // Set permissions for the vault
        rebaseToken.grantMintAndBurnRole(address(vault));
        vm.stopPrank();
    }
}
