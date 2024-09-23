// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {NFTContract} from "src/NFTContract.sol";
import {HelperConfig} from "script/helpers/HelperConfig.s.sol";

contract DeployNFTContract is Script {
    HelperConfig public helperConfig;

    function run() external returns (NFTContract, HelperConfig) {
        helperConfig = new HelperConfig();
        HelperConfig.ConstructorArguments memory args = helperConfig.activeNetworkConfig();

        console.log("initial owner: ", args.owner);
        console.log("base uri: ", args.baseURI);
        console.log("fee address: ", args.feeAddress);

        // after broadcast is real transaction, before just simulation
        vm.startBroadcast();
        uint256 gasLeft = gasleft();
        NFTContract nfts = new NFTContract(
            args.name,
            args.symbol,
            args.baseURI,
            args.contractURI,
            args.owner,
            args.feeAddress,
            args.tokenAddress,
            args.tokenFee,
            args.ethFee,
            args.maxSupply
        );
        console.log("Deployment gas: ", gasLeft - gasleft());
        vm.stopBroadcast();
        return (nfts, helperConfig);
    }
}
