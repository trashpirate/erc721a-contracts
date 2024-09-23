// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {NFTBasic} from "src/NFTBasic.sol";
import {HelperConfig} from "script/helpers/HelperConfig.s.sol";

contract DeployNFTBasic is Script {
    HelperConfig public helperConfig;

    function run() external returns (NFTBasic, HelperConfig) {
        helperConfig = new HelperConfig();
        HelperConfig.ConstructorArguments memory args = helperConfig.getActiveNetworkConfigStruct().args;

        console.log("NFTBasic - initial owner: ", args.owner);
        console.log("NFTBasic - base uri: ", args.baseURI);

        // after broadcast is real transaction, before just simulation
        vm.startBroadcast();
        uint256 gasLeft = gasleft();
        NFTBasic nfts = new NFTBasic(args.name, args.symbol, args.baseURI, args.contractURI, args.owner, args.maxSupply);
        console.log("NFTBasic - Deployment gas: ", gasLeft - gasleft());
        vm.stopBroadcast();
        return (nfts, helperConfig);
    }
}
