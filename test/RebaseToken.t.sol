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

    function addRewardsToVault(uint256 rewardAmount) public {
        (bool success,) = payable(address(vault)).call{value: rewardAmount}("");
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
        assertApproxEqAbs((endBalance - middleBalance), (middleBalance - startBalance), 1);

        vm.stopPrank();
    }

    function testRedeemStraightAway(uint256 amount) public {
        amount = bound(amount, 1e5, type(uint96).max);
        // 1. deposit
        vm.startPrank(user);
        vm.deal(user, amount);
        vault.deposit{value: amount}();
        assertEq(rebaseToken.balanceOf(user), amount);
        // 2. Redeem
        vault.redeem(type(uint256).max);
        // 3. Check balances after redemption
        assertEq(rebaseToken.balanceOf(user), 0);
        assertEq(address(user).balance, amount);
        vm.stopPrank();
    }

    function testRedeemAfterTimePassed(uint256 depositAmount, uint256 time) public {
        time = bound(time, 1000, type(uint32).max);
        depositAmount = bound(depositAmount, 1e5, type(uint96).max);
        // 1. Deposit

        vm.deal(user, depositAmount);
        vm.prank(user);
        vault.deposit{value: depositAmount}();
        // 2. Warp the time
        vm.warp(block.timestamp + time);
        uint256 balanceAfterSomeTime = rebaseToken.balanceOf(user);
        // Add the rewards to the vault
        vm.deal(owner, balanceAfterSomeTime - depositAmount);
        vm.prank(owner);
        addRewardsToVault(balanceAfterSomeTime - depositAmount);
        // 3. Redeem

        vm.prank(user);
        vault.redeem(type(uint256).max);

        vm.stopPrank();
        uint256 ethBalance = address(user).balance;

        assertEq(ethBalance, balanceAfterSomeTime);
        assertGt(ethBalance, depositAmount);
    }
}
