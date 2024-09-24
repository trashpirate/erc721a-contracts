// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";

import {DeployNFTWhitelist} from "script/deployment/DeployNFTWhitelist.s.sol";
import {NFTWhitelist} from "src/NFTWhitelist.sol";
import {Whitelist} from "src/extensions/Whitelist.sol";
import {HelperConfig} from "script/helpers/HelperConfig.s.sol";

contract NFTWhitelistUnitTest is Test {
    /*//////////////////////////////////////////////////////////////
                             CONFIGURATION
    //////////////////////////////////////////////////////////////*/
    DeployNFTWhitelist deployer;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;

    /*//////////////////////////////////////////////////////////////
                               CONTRACTS
    //////////////////////////////////////////////////////////////*/
    NFTWhitelist nftContract;

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/
    address USER = makeAddr("regular-user");

    // for testing add address to whitelist.csv in ../utils/merkle-tree-generator
    address VALID_USER;
    uint256 VALID_USER_KEY;

    // get merkle root by running the `generateTree.js` script in ../utils/merkle-tree-generator
    bytes32 MERKLE_ROOT = 0x7cfda1d6c2b32e261fbdf50526b103173ab06cb1879095dddc3d2c5feb96198a;
    bytes32[] PROOF = [
        bytes32(0xfd28eb2cd1dab1d4e95dafc7b249eff8e75eabe37548efb05dada899264f25b4),
        0x603ab331089101552b9dde23779eab62af9b50242bdd77dd16f4dd86fe748129,
        0xf67ea6e5dd288a14836f06064b781d7e30ca3af8ea340931d7bde127af0a0757,
        0x77f4ff80b42f3ed7f596900be1a0e7a2abf1e01b26372fe2af0957c15c93d0ac,
        0x563314bbe031d9c0bcb7e68735ffe7d64b03eb46186064d3cbcab90aee1621f7
    ];
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event ClaimStatusSet(address indexed account, bool indexed claimed);

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() external virtual {
        deployer = new DeployNFTWhitelist();
        (nftContract, helperConfig) = deployer.run();

        networkConfig = helperConfig.getActiveNetworkConfigStruct();

        (VALID_USER, VALID_USER_KEY) = makeAddrAndKey("user");
    }

    /*//////////////////////////////////////////////////////////////
                          GET VALID USER ADDRESS
    //////////////////////////////////////////////////////////////*/
    function test__NFTWhitelist__GetValidUserAddress() external view {
        console.log("VALID_USER: ", VALID_USER);
        console.log("VALID_USER_KEY: ", VALID_USER_KEY);
    }

    /*//////////////////////////////////////////////////////////////
                             INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    function test__NFTWhitelist__Initialization() external view {
        assertEq(nftContract.getMerkleRoot(), networkConfig.args.merkleRoot);
        assertEq(nftContract.hasClaimed(VALID_USER), false);
    }

    /*//////////////////////////////////////////////////////////////
                               TEST MINT
    //////////////////////////////////////////////////////////////*/

    /// SUCCESS
    //////////////////////////////////////////////////////////////*/
    function test__NFTWhitelist__Mint() external {
        uint256 balance = nftContract.balanceOf(VALID_USER);

        // mint
        vm.prank(VALID_USER);
        nftContract.mint(1, PROOF);

        assertEq(nftContract.balanceOf(VALID_USER), balance + 1);
    }

    /// EMIT EVENTS
    //////////////////////////////////////////////////////////////*/
    function test__NFTWhitelist__EmitEvent__ClaimStatusSet() external {
        vm.expectEmit(true, true, true, true);
        emit ClaimStatusSet(VALID_USER, true);

        // mint
        vm.prank(VALID_USER);
        nftContract.mint(1, PROOF);
    }

    /// REVERTS
    //////////////////////////////////////////////////////////////*/
    function test__NFTWhitelist__RevertsWhen__InvalidMinter() external {
        vm.expectRevert(NFTWhitelist.NFTWhitelist__InvalidMinter.selector);

        // mint
        vm.prank(USER);
        nftContract.mint(1, PROOF);
    }

    /*//////////////////////////////////////////////////////////////
                           TEST CLAIM STATUS
    //////////////////////////////////////////////////////////////*/
    function test__NFTWhitelist__UpdatesClaimStatus() external {
        // mint
        vm.prank(VALID_USER);
        nftContract.mint(1, PROOF);

        assertEq(nftContract.hasClaimed(VALID_USER), true);
    }
}
