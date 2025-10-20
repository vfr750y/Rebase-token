//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {Script} from "@forge-std/src/Script.sol";
import {Vault} from "../src/Vault.sol";
import {IRebaseToken} from "../src/Interfaces/IRebaseToken.sol";

contract TokenAndPoolDeployer {}

contract VaultDeployer is Script {
    function run(address _rebaseToken) public {
        vm.startBroadcast();
        Vault vault = new Vault(IRebaseToken(_rebaseToken));
        IRebaseToken(_rebaseToken).grantMintAndBurnRole(address(vault));
        vm.stopBroadcast();
    }
}
