// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {NFTPausable} from "src/NFTPausable.sol";
import {HelperConfig} from "script/helpers/HelperConfig.s.sol";

contract DeployNFTPausable is Script {
    HelperConfig public helperConfig;

    function run() external returns (NFTPausable, HelperConfig) {
        helperConfig = new HelperConfig();
        HelperConfig.ConstructorArguments memory args = helperConfig.activeNetworkConfig();

        console.log("initial owner: ", args.owner);
        console.log("base uri: ", args.baseURI);

        // after broadcast is real transaction, before just simulation
        vm.startBroadcast();
        uint256 gasLeft = gasleft();
        NFTPausable nfts =
            new NFTPausable(args.name, args.symbol, args.baseURI, args.contractURI, args.owner, args.maxSupply);
        console.log("Deployment gas: ", gasLeft - gasleft());
        vm.stopBroadcast();
        return (nfts, helperConfig);
    }
}
