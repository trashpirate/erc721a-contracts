// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract DeployERC20Token is Script {
    function run() external returns (ERC20Mock) {
        vm.startBroadcast();
        ERC20Mock token = new ERC20Mock();
        vm.stopBroadcast();
        return token;
    }
}
