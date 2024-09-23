// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import {NFTContract} from "src/NFTContract.sol";
import {HelperConfig} from "script/helpers/HelperConfig.s.sol";
import {DeployNFTContract} from "script/deployment/DeployNFTContract.s.sol";
import {MintNft, BatchMint, TransferNft, ApproveNft, BurnNft} from "script/interactions/Interactions.s.sol";

contract TestInteractions is Test {
    /*//////////////////////////////////////////////////////////////
                             CONFIGURATION
    //////////////////////////////////////////////////////////////*/
    DeployNFTContract deployment;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;

    /*//////////////////////////////////////////////////////////////
                               CONTRACTS
    //////////////////////////////////////////////////////////////*/
    NFTContract nftContract;
    ERC20Mock token;

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/
    address contractOwner;
    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 500_000_000 ether;

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    modifier funded(address account) {
        // fund user with eth
        deal(account, 1000 ether);

        // fund user with tokens
        token.mint(account, STARTING_BALANCE);

        // approve Tokens
        vm.prank(account);
        token.approve(address(nftContract), STARTING_BALANCE);
        _;
    }

    modifier unpaused() {
        vm.startPrank(nftContract.owner());
        nftContract.unpause();
        vm.stopPrank();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() external {
        deployment = new DeployNFTContract();
        (nftContract, helperConfig) = deployment.run();
        contractOwner = nftContract.owner();

        networkConfig = helperConfig.getActiveNetworkConfigStruct();
        token = ERC20Mock(nftContract.getFeeToken());
    }

    /*//////////////////////////////////////////////////////////////
                               TEST MINT
    //////////////////////////////////////////////////////////////*/
    function test__SingleMint() public funded(msg.sender) unpaused {
        MintNft mintNft = new MintNft();
        mintNft.mintNft(address(nftContract));
        assertEq(nftContract.balanceOf(msg.sender), 1);
    }

    /*//////////////////////////////////////////////////////////////
                            TEST BATCH MINT
    //////////////////////////////////////////////////////////////*/
    function test__BatchMint() public funded(msg.sender) unpaused {
        BatchMint batchMint = new BatchMint();
        batchMint.batchMint(address(nftContract));
        assertEq(nftContract.balanceOf(msg.sender), nftContract.getBatchLimit());
    }
}
