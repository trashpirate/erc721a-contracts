// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {NFTContract} from "src/NFTContract.sol";

contract HelperConfig is Script {
    struct NetworkConfig {
        NFTContract.ConstructorArguments args;
    }

    // nft configurations
    string public NAME;
    string public SYMBOL;
    string public BASE_URI;
    string public CONTRACT_URI;
    uint256 public MAX_SUPPLY;
    uint96 public ROYALTY;
    uint256 public ETH_FEE;
    uint256 public TOKEN_FEE;
    uint256 public MAX_WALLET_SIZE;
    uint256 public BATCH_LIMIT;

    // chain configurations
    NetworkConfig public activeNetworkConfig;

    constructor() {
        NAME = vm.envString("COLLECTION_NAME");
        SYMBOL = vm.envString("SYMBOL");
        BASE_URI = vm.envString("BASE_URI");
        CONTRACT_URI = vm.envString("CONTRACT_URI");
        MAX_SUPPLY = vm.envUint("MAX_SUPPLY");
        ROYALTY = uint96(vm.envUint("ROYALTY"));
        ETH_FEE = vm.envUint("ETH_FEE");
        TOKEN_FEE = vm.envUint("TOKEN_FEE");
        MAX_WALLET_SIZE = vm.envUint("MAX_WALLET_SIZE");
        BATCH_LIMIT = vm.envUint("BATCH_LIMIT");

        console.log("NAME: ", NAME);
        console.log("SYMBOL: ", SYMBOL);
        console.log("BASE_URI: ", BASE_URI);
        console.log("CONTRACT_URI: ", CONTRACT_URI);
        console.log("MAX_SUPPLY: ", MAX_SUPPLY);
        console.log("ROYALTY: ", ROYALTY);
        console.log("ETH_FEE: ", ETH_FEE);
        console.log("TOKEN_FEE: ", TOKEN_FEE);
        console.log("MAX_WALLET_SIZE: ", MAX_WALLET_SIZE);
        console.log("BATCH_LIMIT: ", BATCH_LIMIT);

        console.log("{type: 'string', value: '%s'},", NAME);
        console.log("{type: 'string', value: '%s'},", SYMBOL);
        console.log("{type: 'string', value: '%s'},", BASE_URI);
        console.log("{type: 'string', value: '%s'},", CONTRACT_URI);
        console.log("{type: 'address', value: '%s'},", "TYR2TRfKCMQsqekiZUhVJFSmwSEK2wUTAA");
        console.log("{type: 'address', value: '%s'},", "TYR2TRfKCMQsqekiZUhVJFSmwSEK2wUTAA");
        console.log("{type: 'address', value: '%s'},", "TNEe78wmo2waTYF9Viu8AifzD3D99VXd7q");
        console.log("{type: 'uint256', value: '%d'},", TOKEN_FEE);
        console.log("{type: 'uint256', value: '%d'},", ETH_FEE);
        console.log("{type: 'uint256', value: '%d'},", MAX_SUPPLY);
        console.log("{type: 'uint256', value: '%d'},", MAX_WALLET_SIZE);
        console.log("{type: 'uint256', value: '%d'},", BATCH_LIMIT);
        console.log("{type: 'uint96', value: '%d'},", ROYALTY);

        /**
         * Example constructor input for Remix IDE: ["Touch Grassy","GRASSY","ipfs://bafybeidunoa4h3e5kvddib6gi53nhmbm32lzvcaxqccdforsiih2mwubky/","ipfs://bafkreiez4tklbxcv5e45s5zed5l2x2atmf7d26lfuo42xbbddnlppnzngm","TYR2TRfKCMQsqekiZUhVJFSmwSEK2wUTAA","TYR2TRfKCMQsqekiZUhVJFSmwSEK2wUTAA","TNEe78wmo2waTYF9Viu8AifzD3D99VXd7q",0,0,1000,100,10,500]
         */
        if (block.chainid == 1 || block.chainid == 8453 || block.chainid == 123) {
            activeNetworkConfig = getMainnetConfig();
        } else if (block.chainid == 84532 || block.chainid == 11155111) {
            activeNetworkConfig = getTestnetConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }

        bytes memory constructorArgs = abi.encode(activeNetworkConfig);

        console.logBytes(constructorArgs);
    }

    function getActiveNetworkConfigStruct() public view returns (NetworkConfig memory) {
        return activeNetworkConfig;
    }

    function getMainnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            args: NFTContract.ConstructorArguments({
                name: NAME,
                symbol: SYMBOL,
                baseURI: BASE_URI,
                contractURI: CONTRACT_URI,
                owner: vm.envAddress("OWNER_ADDRESS"),
                feeAddress: vm.envAddress("FEE_ADDRESS"),
                tokenAddress: vm.envAddress("TOKEN_ADDRESS"),
                ethFee: ETH_FEE,
                tokenFee: TOKEN_FEE,
                maxSupply: MAX_SUPPLY,
                maxWalletSize: MAX_WALLET_SIZE,
                batchLimit: BATCH_LIMIT,
                royaltyNumerator: ROYALTY
            })
        });
    }

    function getTestnetConfig() public view returns (NetworkConfig memory) {
        return NetworkConfig({
            args: NFTContract.ConstructorArguments({
                name: NAME,
                symbol: SYMBOL,
                baseURI: BASE_URI,
                contractURI: CONTRACT_URI,
                owner: vm.envAddress("OWNER_ADDRESS"),
                feeAddress: vm.envAddress("FEE_ADDRESS"),
                tokenAddress: vm.envAddress("TOKEN_ADDRESS"),
                ethFee: ETH_FEE,
                tokenFee: TOKEN_FEE,
                maxSupply: MAX_SUPPLY,
                maxWalletSize: MAX_WALLET_SIZE,
                batchLimit: BATCH_LIMIT,
                royaltyNumerator: ROYALTY
            })
        });
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        // Deploy mock contracts
        vm.startBroadcast();
        ERC20Mock token = new ERC20Mock();
        vm.stopBroadcast();

        return NetworkConfig({
            args: NFTContract.ConstructorArguments({
                name: NAME,
                symbol: SYMBOL,
                baseURI: BASE_URI,
                contractURI: CONTRACT_URI,
                owner: vm.envAddress("ANVIL_DEFAULT_ACCOUNT"),
                feeAddress: vm.envAddress("ANVIL_DEFAULT_ACCOUNT"),
                tokenAddress: address(token),
                ethFee: ETH_FEE,
                tokenFee: TOKEN_FEE,
                maxSupply: MAX_SUPPLY,
                maxWalletSize: MAX_WALLET_SIZE,
                batchLimit: BATCH_LIMIT,
                royaltyNumerator: ROYALTY
            })
        });
    }
}
