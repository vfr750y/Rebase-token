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
        // add funds of 1 ETH to the vault
        (bool success,) = payable(address(vault)).call{value: 1e18}("");
        vm.stopPrank();
    }

    // check interest is linear -
    // get balance before deposit,
    // deposit 1 eth ,
    // get balance after deposit,
    // check balance after - balance before =  1 Eth.

    function testDepositLinear(uint256 amount) public {
        // resrict the amount of ETH to a value between 1e5 and uint96.max without discarding any test runs.
        amount = bound(amount, 1e5, type(uint96).max);
        // deposit 1 eth
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();

        // get balance after deposit,
        uint256 startBalance = rebaseToken.balanceOf(user);
        console.log("startBalance", startBalance);
        assertEq(startBalance, amount);
        // warp the time and check the balance again
        vm.warp(block.timestamp + 1 hours);
        uint256 middleBalance = rebaseToken.balanceOf(user);
        assertGt(middleBalance, startBalance);
        // warp the time again by same amount and check the balance again
        vm.warp(block.timestamp + 1 hours);
        uint256 endBalance = rebaseToken.balanceOf(user);
        assertGt(endBalance, middleBalance);

        // check difference
        assertEq((endBalance - middleBalance), (middleBalance - startBalance));

        vm.stopPrank();
    }
}
