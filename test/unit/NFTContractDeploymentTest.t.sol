// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721A} from "@erc721a/contracts/IERC721A.sol";
import {DeployNFTContract} from "./../../script/deployment/DeployNFTContract.s.sol";
import {NFTContract} from "./../../src/NFTContract.sol";
import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";

contract NFTContractDeploymentTest is Test {
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

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() external virtual {
        deployment = new DeployNFTContract();
        (nftContract, helperConfig) = deployment.run();

        networkConfig = helperConfig.getActiveNetworkConfigStruct();
    }

    /*//////////////////////////////////////////////////////////////
                          TEST   INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    function test__unit__Initialization() public {
        assertEq(nftContract.getMaxSupply(), 1000);

        assertEq(nftContract.getFeeAddress(), networkConfig.feeAddress);
        assertEq(nftContract.getFeeToken(), networkConfig.feeToken);
        assertEq(nftContract.owner(), networkConfig.initialOwner);

        assertEq(nftContract.getEthFee(), 0.001 ether);
        assertEq(nftContract.getTokenFee(), 1000 ether);

        assertEq(nftContract.getMaxWalletSize(), 25);
        assertEq(nftContract.getBatchLimit(), 10);

        assertEq(nftContract.isPaused(), true);

        assertEq(nftContract.supportsInterface(0x80ac58cd), true); // ERC721
        assertEq(nftContract.supportsInterface(0x2a55205a), true); // ERC2981

        vm.expectRevert(IERC721A.OwnerQueryForNonexistentToken.selector);
        nftContract.tokenURI(1);
    }

    /*//////////////////////////////////////////////////////////////
                             TEST ROYALTIES
    //////////////////////////////////////////////////////////////*/
    function test__unit__InitialRoyalties() public view {
        uint256 salePrice = 100;
        (address feeAddress, uint256 royaltyAmount) = nftContract.royaltyInfo(1, salePrice);
        assertEq(feeAddress, networkConfig.feeAddress);
        assertEq(royaltyAmount, (500 * 100) / 10000);
    }

    /*//////////////////////////////////////////////////////////////
                            TEST DEPLOYMENT
    //////////////////////////////////////////////////////////////*/

    function test__unit__RevertWhen__ZeroFeeAddress() public {
        (address feeToken,, address initialOwner) = helperConfig.activeNetworkConfig();

        vm.expectRevert(NFTContract.NFTContract_FeeAddressIsZeroAddress.selector);
        new NFTContract(feeToken, address(0), initialOwner);
    }
}
