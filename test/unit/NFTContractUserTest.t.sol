// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Errors} from "@openzeppelin/contracts/interfaces/draft-IERC6093.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import {StringToNumber} from "../utils/Utils.sol";
import {DeployNFTContract} from "./../../script/deployment/DeployNFTContract.s.sol";
import {NFTContract} from "./../../src/NFTContract.sol";
import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";

contract TestHelper {
    mapping(string => bool) public tokenUris;

    function setTokenUri(string memory tokenUri) public {
        tokenUris[tokenUri] = true;
    }

    function isTokenUriSet(string memory tokenUri) public view returns (bool) {
        return tokenUris[tokenUri];
    }
}

contract TestUserFunctions is Test {
    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/
    enum Trait {
        None,
        Green,
        Blue,
        Yellow,
        Red,
        Purple
    }

    /*//////////////////////////////////////////////////////////////
                             CONFIGURATION
    //////////////////////////////////////////////////////////////*/
    DeployNFTContract deployment;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;

    /*//////////////////////////////////////////////////////////////
                               CONTRACTS
    //////////////////////////////////////////////////////////////*/
    ERC20Mock token;
    NFTContract nftContract;

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/
    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 500_000_000 ether;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event MetadataUpdated(uint256 indexed tokenId);

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

        _;
    }

    modifier unpaused() {
        vm.startPrank(nftContract.owner());
        nftContract.pause(false);
        vm.stopPrank();
        _;
    }

    modifier noMaxWallet() {
        address owner = nftContract.owner();
        vm.prank(owner);
        nftContract.setMaxWalletSize(0);
        _;
    }

    modifier noBatchLimit() {
        address owner = nftContract.owner();
        vm.prank(owner);
        nftContract.setBatchLimit(100);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() external virtual {
        deployment = new DeployNFTContract();
        (nftContract, helperConfig) = deployment.run();

        networkConfig = helperConfig.getActiveNetworkConfigStruct();

        token = ERC20Mock(nftContract.getFeeToken());
    }

    function fund(address account) public {
        // fund user with eth
        deal(account, 10000 ether);

        // fund user with tokens
        token.mint(account, 500_000_000 ether);
    }

    /*//////////////////////////////////////////////////////////////
                               TEST MINT
    //////////////////////////////////////////////////////////////*/

    /// SUCCESS
    //////////////////////////////////////////////////////////////*/
    function test__unit__Mint(uint256 quantity, address account) public unpaused skipFork {
        quantity = bound(quantity, 1, nftContract.getBatchLimit());
        vm.assume(account != address(0));
        vm.assume(account != nftContract.getFeeAddress());

        fund(account);

        uint256 feeEthBalance = nftContract.getFeeAddress().balance;
        uint256 feeTokenBalance = token.balanceOf(nftContract.getFeeAddress());

        uint256 ethBalance = account.balance;
        uint256 tokenBalance = token.balanceOf(account);

        uint256 ethFee = quantity * nftContract.getEthFee();
        uint256 tokenFee = quantity * nftContract.getTokenFee();

        vm.startPrank(account);
        token.approve(address(nftContract), tokenFee);
        nftContract.mint{value: ethFee}(quantity);
        vm.stopPrank();

        assertEq(nftContract.balanceOf(account), quantity);

        assertEq(account.balance, ethBalance - ethFee);
        assertEq(token.balanceOf(account), tokenBalance - tokenFee);

        assertEq(nftContract.getFeeAddress().balance, feeEthBalance + ethFee);
        assertEq(token.balanceOf(nftContract.getFeeAddress()), feeTokenBalance + tokenFee);
    }

    function test__unit__MintNoMaxWallet(uint256 quantity, address account)
        public
        unpaused
        noMaxWallet
        noBatchLimit
        skipFork
    {
        quantity = bound(quantity, 1, nftContract.getBatchLimit());
        vm.assume(account != address(0));
        vm.assume(account != nftContract.getFeeAddress());

        fund(account);

        uint256 ethFee = quantity * nftContract.getEthFee();
        uint256 tokenFee = quantity * nftContract.getTokenFee();

        vm.startPrank(account);
        token.approve(address(nftContract), tokenFee);
        nftContract.mint{value: ethFee}(quantity);
        vm.stopPrank();

        assertEq(nftContract.balanceOf(account), quantity);
    }

    /// EVENT EMITTED
    //////////////////////////////////////////////////////////////*/
    function test__unit__EmitEvent__Mint() public funded(USER) unpaused noBatchLimit {
        uint256 ethFee = nftContract.getEthFee();
        uint256 tokenFee = nftContract.getTokenFee();

        vm.prank(USER);
        token.approve(address(nftContract), tokenFee);

        vm.expectEmit(true, true, true, true);
        emit MetadataUpdated(1);

        vm.prank(USER);
        nftContract.mint{value: ethFee}(1);
    }

    /// REVERTS
    //////////////////////////////////////////////////////////////*/
    function test__unit__RevertWhen__MintPaused() public funded(USER) {
        uint256 ethFee = nftContract.getEthFee();
        uint256 tokenFee = nftContract.getTokenFee();

        vm.prank(USER);
        token.approve(address(nftContract), tokenFee);

        vm.expectRevert(NFTContract.NFTContract_ContractIsPaused.selector);
        vm.prank(USER);
        nftContract.mint{value: ethFee}(1);
    }

    function test__unit__RevertWhen__InsufficientMintQuantity() public funded(USER) unpaused {
        uint256 ethFee = nftContract.getEthFee();
        uint256 tokenFee = nftContract.getTokenFee();

        vm.prank(USER);
        token.approve(address(nftContract), tokenFee);

        vm.expectRevert(NFTContract.NFTContract_InsufficientMintQuantity.selector);
        vm.prank(USER);
        nftContract.mint{value: ethFee}(0);
    }

    function test__unit__RevertWhen__MintExceedsBatchLimit() public funded(USER) unpaused {
        uint256 quantity = nftContract.getBatchLimit() + 1;
        uint256 ethFee = nftContract.getEthFee() * quantity;
        uint256 tokenFee = nftContract.getTokenFee() * quantity;

        vm.prank(USER);
        token.approve(address(nftContract), tokenFee);

        vm.expectRevert(NFTContract.NFTContract_ExceedsBatchLimit.selector);
        vm.prank(USER);
        nftContract.mint{value: ethFee}(quantity);
    }

    function test__unit__RevertWhen__MintExceedsMaxWalletSize() public funded(USER) unpaused {
        uint256 quantity = nftContract.getMaxWalletSize() + 1;
        uint256 ethFee = nftContract.getEthFee() * quantity;
        uint256 tokenFee = nftContract.getTokenFee() * quantity;

        address owner = nftContract.owner();
        vm.prank(owner);
        nftContract.setBatchLimit(quantity);

        vm.prank(USER);
        token.approve(address(nftContract), tokenFee);

        vm.expectRevert(NFTContract.NFTContract_ExceedsMaxPerWallet.selector);
        vm.prank(USER);
        nftContract.mint{value: ethFee}(quantity);
    }

    function test__unit__RevertWhen__MaxSupplyExceeded() public funded(USER) unpaused {
        uint256 maxSupply = nftContract.getMaxSupply();
        uint256 tokenFee = nftContract.getTokenFee();
        uint256 ethFee = nftContract.getEthFee();

        vm.prank(USER);
        token.approve(address(nftContract), tokenFee * maxSupply);

        for (uint256 index = 0; index < maxSupply; index++) {
            vm.prank(USER);
            nftContract.mint{value: ethFee}(1);
        }

        vm.expectRevert(NFTContract.NFTContract_ExceedsMaxSupply.selector);
        vm.prank(USER);
        nftContract.mint{value: ethFee}(1);
    }

    function test__unit__RevertWhen__InsufficientEthFee(uint256 quantity) public funded(USER) unpaused skipFork {
        quantity = bound(quantity, 1, nftContract.getBatchLimit());

        address owner = nftContract.owner();
        vm.prank(owner);
        nftContract.setEthFee(0.1 ether);

        uint256 tokenFee = nftContract.getTokenFee() * quantity;
        uint256 ethFee = nftContract.getEthFee() * quantity;
        uint256 insufficientFee = ethFee - 0.01 ether;

        vm.prank(USER);
        token.approve(address(nftContract), tokenFee);

        vm.expectRevert(
            abi.encodeWithSelector(NFTContract.NFTContract_InsufficientEthFee.selector, insufficientFee, ethFee)
        );
        vm.prank(USER);
        nftContract.mint{value: insufficientFee}(quantity);
    }

    function test__unit__RevertWhen__InsufficientAllowance() public funded(USER) unpaused {
        uint256 ethFee = nftContract.getEthFee();
        uint256 tokenFee = nftContract.getTokenFee();

        vm.expectRevert(
            abi.encodeWithSelector(IERC20Errors.ERC20InsufficientAllowance.selector, address(nftContract), 0, tokenFee)
        );
        vm.prank(USER);
        nftContract.mint{value: ethFee}(1);
    }

    function test__unit__RevertWhen__MintTokenTransferFails(uint256 quantity, address account)
        public
        unpaused
        skipFork
    {
        quantity = bound(quantity, 1, nftContract.getBatchLimit());
        vm.assume(account != address(0));

        fund(account);

        uint256 ethFee = nftContract.getEthFee() * quantity;
        uint256 tokenFee = nftContract.getTokenFee() * quantity;

        address feeAddress = nftContract.getFeeAddress();

        vm.mockCall(
            address(token),
            abi.encodeWithSelector(token.transferFrom.selector, account, feeAddress, tokenFee),
            abi.encode(false)
        );

        vm.expectRevert(NFTContract.NFTContract_TokenTransferFailed.selector);
        vm.prank(account);
        nftContract.mint{value: ethFee}(quantity);
    }

    function test__unit__RevertWhen__MintEthTransferFails(uint256 quantity, address account) public unpaused skipFork {
        quantity = bound(quantity, 1, nftContract.getBatchLimit());
        vm.assume(account != address(0));

        fund(account);

        uint256 ethFee = nftContract.getEthFee() * quantity;
        uint256 tokenFee = nftContract.getTokenFee() * quantity;

        address feeAddress = nftContract.getFeeAddress();
        vm.prank(account);
        token.approve(address(nftContract), tokenFee);

        vm.mockCallRevert(feeAddress, "", "");

        vm.expectRevert(NFTContract.NFTContract_EthTransferFailed.selector);
        vm.prank(account);
        nftContract.mint{value: ethFee}(quantity);
    }

    function test__unit__ChargesNoFeeIfZeroEthFee() public unpaused funded(USER) {
        uint256 tokenFee = nftContract.getTokenFee();

        uint256 ethBalance = USER.balance;

        address owner = nftContract.owner();
        vm.prank(owner);
        nftContract.setEthFee(0);
        console.log(nftContract.getEthFee());

        vm.prank(USER);
        token.approve(address(nftContract), tokenFee);

        vm.prank(USER);
        nftContract.mint(1);

        // correct nft balance
        assertEq(nftContract.balanceOf(USER), 1);

        // correct nft ownership
        assertEq(nftContract.ownerOf(1), USER);

        // correct eth fee charged
        assertEq(USER.balance, ethBalance);
    }

    /*//////////////////////////////////////////////////////////////
                             TEST TRANSFER
    //////////////////////////////////////////////////////////////*/
    function test__Transfer(address account, address receiver) public unpaused noBatchLimit skipFork {
        uint256 quantity = 1; //bound(numOfNfts, 1, 100);
        vm.assume(account != address(0));
        vm.assume(receiver != address(0));

        fund(account);

        uint256 ethFee = nftContract.getEthFee() * quantity;
        uint256 tokenFee = nftContract.getTokenFee() * quantity;

        vm.prank(account);
        token.approve(address(nftContract), tokenFee);

        vm.prank(account);
        nftContract.mint{value: ethFee}(quantity);

        assertEq(nftContract.balanceOf(account), quantity);
        assertEq(nftContract.ownerOf(1), account);

        vm.prank(account);
        nftContract.transferFrom(account, receiver, 1);

        assertEq(nftContract.ownerOf(1), receiver);
        assertEq(nftContract.balanceOf(receiver), quantity);
    }

    /*//////////////////////////////////////////////////////////////
                             TEST TOKENURI
    //////////////////////////////////////////////////////////////*/
    function test__unit__RetrieveTokenUri() public funded(USER) unpaused {
        uint256 ethFee = nftContract.getEthFee();
        uint256 tokenFee = nftContract.getTokenFee();

        vm.prank(USER);
        token.approve(address(nftContract), tokenFee);

        vm.prank(USER);
        nftContract.mint{value: ethFee}(1);

        assertEq(nftContract.balanceOf(USER), 1);
        assertEq(nftContract.tokenURI(1), string.concat(nftContract.getBaseURI(), "532"));
    }

    function test__unit__batchTokenURI() public funded(USER) unpaused {
        uint256 roll = 2;
        uint256 batchLimit = nftContract.getBatchLimit();
        uint256 ethFee = nftContract.getEthFee() * batchLimit;
        uint256 tokenFee = nftContract.getTokenFee() * batchLimit;
        for (uint256 index = 0; index < 20; index++) {
            vm.prevrandao(bytes32(uint256(index + roll)));

            vm.startPrank(USER);
            token.approve(address(nftContract), tokenFee);

            nftContract.mint{value: ethFee}(batchLimit);
            vm.stopPrank();
        }

        for (uint256 index = 0; index < nftContract.totalSupply() - 1; index++) {
            console.log(nftContract.tokenURI(index + 1));
        }
    }

    /// forge-config: default.fuzz.runs = 3
    // function test__unit__UniqueTokenURI(uint256 roll) public funded(USER) unpaused skipFork {
    //     roll = bound(roll, 0, 100000000000);
    //     TestHelper testHelper = new TestHelper();

    //     uint256 maxSupply = nftContract.getMaxSupply();
    //     uint256 ethFee = nftContract.getEthFee();
    //     uint256 tokenFee = nftContract.getTokenFee();

    //     vm.startPrank(USER);
    //     for (uint256 index = 0; index < maxSupply; index++) {
    //         vm.prevrandao(bytes32(uint256(index + roll)));

    //         token.approve(address(nftContract), tokenFee);

    //         nftContract.mint{value: ethFee}(1);
    //         assertEq(testHelper.isTokenUriSet(nftContract.tokenURI(index + 1)), false);
    //         console.log(nftContract.tokenURI(index + 1));
    //         testHelper.setTokenUri(nftContract.tokenURI(index + 1));
    //     }
    //     vm.stopPrank();
    // }
}
