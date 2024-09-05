// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import {DeployNFTContract} from "./../../script/deployment/DeployNFTContract.s.sol";
import {NFTContract} from "./../../src/NFTContract.sol";
import {HelperConfig} from "../../script/helpers/HelperConfig.s.sol";

contract TestUserFunctions is Test {
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
    address USER = makeAddr("user");
    address NEW_FEE_ADDRESS = makeAddr("fee");
    uint256 constant NEW_FEE = 0.001 ether;
    uint256 constant NEW_BATCH_LIMIT = 20;
    uint256 constant NEW_MAX_WALLET_SIZE = 20;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event BatchLimitSet(address indexed sender, uint256 batchLimit);
    event MaxWalletSizeSet(address indexed sender, uint256 maxWalletSize);
    event BaseURIUpdated(address indexed sender, string indexed baseUri);
    event ContractURIUpdated(address indexed sender, string indexed contractUri);
    event RoyaltyUpdated(address indexed feeAddress, uint96 indexed royaltyNumerator);
    event EthFeeSet(address indexed sender, uint256 indexed fee);
    event TokenFeeSet(address indexed sender, uint256 indexed fee);
    event FeeAddressSet(address indexed sender, address feeAddress);
    event Paused(address indexed sender, bool isPaused);

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
        _;
    }

    modifier unpaused() {
        vm.startPrank(nftContract.owner());
        nftContract.pause(false);
        vm.stopPrank();
        _;
    }

    modifier noBatchLimit() {
        vm.startPrank(nftContract.owner());
        nftContract.setBatchLimit(100);
        vm.stopPrank();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() external virtual {
        deployment = new DeployNFTContract();
        (nftContract, helperConfig) = deployment.run();

        networkConfig = helperConfig.getActiveNetworkConfigStruct();

        token = ERC20Mock(networkConfig.feeToken);
    }

    /*//////////////////////////////////////////////////////////////
                               TEST PAUSE
    //////////////////////////////////////////////////////////////*/
    function test__unit__UnPause() public {
        address owner = nftContract.owner();

        vm.prank(owner);
        nftContract.pause(false);

        assertEq(nftContract.isPaused(), false);
    }

    function test__unit__Pause() public {
        address owner = nftContract.owner();

        vm.prank(owner);
        nftContract.pause(false);

        vm.prank(owner);
        nftContract.pause(true);

        assertEq(nftContract.isPaused(), true);
    }

    function test__unit__EmitEvent__Pause() public {
        address owner = nftContract.owner();

        vm.expectEmit(true, true, true, true);
        emit Paused(owner, false);

        vm.prank(owner);
        nftContract.pause(false);
    }

    function test__unit__RevertsWhen__NotOwnerPauses() public {
        address owner = nftContract.owner();

        vm.prank(owner);
        nftContract.pause(false);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        vm.prank(USER);
        nftContract.pause(true);
    }

    /*//////////////////////////////////////////////////////////////
                           TEST SET BATCHLIMIT
    //////////////////////////////////////////////////////////////*/
    function test__unit__SetBatchLimit() public {
        address owner = nftContract.owner();
        vm.prank(owner);
        nftContract.setBatchLimit(NEW_BATCH_LIMIT);
        assertEq(nftContract.getBatchLimit(), NEW_BATCH_LIMIT);
    }

    function test__unit__EmitEvent__SetBatchLimit() public {
        address owner = nftContract.owner();

        vm.expectEmit(true, true, true, true);
        emit BatchLimitSet(owner, NEW_BATCH_LIMIT);

        vm.prank(owner);
        nftContract.setBatchLimit(NEW_BATCH_LIMIT);
    }

    function test__unit__RevertWhen__BatchLimitTooHigh() public {
        address owner = nftContract.owner();
        vm.prank(owner);

        vm.expectRevert(NFTContract.NFTContract_BatchLimitTooHigh.selector);
        nftContract.setBatchLimit(101);
    }

    function test__unit__RevertWhen__NotOwnerSetsBatchLimit() public {
        vm.prank(USER);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        nftContract.setBatchLimit(NEW_BATCH_LIMIT);
    }

    /*//////////////////////////////////////////////////////////////
                        TEST SET MAXWALLETSIZE
    //////////////////////////////////////////////////////////////*/
    function test__unit__SetMaxWalletSize() public {
        address owner = nftContract.owner();
        vm.prank(owner);
        nftContract.setMaxWalletSize(NEW_MAX_WALLET_SIZE);
        assertEq(nftContract.getMaxWalletSize(), NEW_MAX_WALLET_SIZE);
    }

    function test__unit__EmitEvent__SetMaxWalletSize() public {
        address owner = nftContract.owner();

        vm.expectEmit(true, true, true, true);
        emit MaxWalletSizeSet(owner, NEW_MAX_WALLET_SIZE);

        vm.prank(owner);
        nftContract.setMaxWalletSize(NEW_MAX_WALLET_SIZE);
    }

    function test__unit__RevertWhen__NotOwnerSetsMaxWalletSize() public {
        vm.prank(USER);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        nftContract.setMaxWalletSize(NEW_MAX_WALLET_SIZE);
    }

    /*//////////////////////////////////////////////////////////////
                           TEST SET FEEADDRESS
    //////////////////////////////////////////////////////////////*/
    function test__unit__SetEthFeeAddress() public {
        address owner = nftContract.owner();
        vm.prank(owner);
        nftContract.setFeeAddress(NEW_FEE_ADDRESS);
        assertEq(nftContract.getFeeAddress(), NEW_FEE_ADDRESS);
    }

    function test__unit__EmitEvent__SetEthFeeAddress() public {
        address owner = nftContract.owner();

        vm.expectEmit(true, true, true, true);
        emit FeeAddressSet(owner, NEW_FEE_ADDRESS);

        vm.prank(owner);
        nftContract.setFeeAddress(NEW_FEE_ADDRESS);
    }

    function test__unit__RevertWhen__FeeAddressIsZero() public {
        address owner = nftContract.owner();
        vm.prank(owner);

        vm.expectRevert(NFTContract.NFTContract_FeeAddressIsZeroAddress.selector);
        nftContract.setFeeAddress(address(0));
    }

    function test__unit__RevertWhen__NotOwnerSetsFeeAddress() public {
        vm.prank(USER);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        nftContract.setFeeAddress(NEW_FEE_ADDRESS);
    }

    /*//////////////////////////////////////////////////////////////
                             TEST SET ETHFEE
    //////////////////////////////////////////////////////////////*/
    function test__unit__SetEthFee() public {
        address owner = nftContract.owner();
        vm.prank(owner);
        nftContract.setEthFee(NEW_FEE);
        assertEq(nftContract.getEthFee(), NEW_FEE);
    }

    function test__unit__EmitEvent__SetEthFee() public {
        address owner = nftContract.owner();

        vm.expectEmit(true, true, true, true);
        emit EthFeeSet(owner, NEW_FEE);

        vm.prank(owner);
        nftContract.setEthFee(NEW_FEE);
    }

    function test__unit__RevertWhen__NotOwnerSetsEthFee() public {
        vm.prank(USER);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        nftContract.setEthFee(NEW_FEE);
    }

    /*//////////////////////////////////////////////////////////////
                            TEST SET TOKENFEE
    //////////////////////////////////////////////////////////////*/
    function test__unit__SetTokenFee() public {
        address owner = nftContract.owner();
        vm.prank(owner);
        nftContract.setTokenFee(NEW_FEE);
        assertEq(nftContract.getTokenFee(), NEW_FEE);
    }

    function test__unit__EmitEvent__SetTokenFee() public {
        address owner = nftContract.owner();

        vm.expectEmit(true, true, true, true);
        emit TokenFeeSet(owner, NEW_FEE);

        vm.prank(owner);
        nftContract.setTokenFee(NEW_FEE);
    }

    function test__unit__RevertWhen__NotOwnerSetsTokenFee() public {
        vm.prank(USER);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        nftContract.setTokenFee(NEW_FEE);
    }

    /*//////////////////////////////////////////////////////////////
                            TEST WITHDRAW ETH
    //////////////////////////////////////////////////////////////*/
    function test__unit__WithdrawETH() public funded(USER) {
        deal(address(nftContract), 1 ether);
        uint256 contractBalance = address(nftContract).balance;
        assertGt(contractBalance, 0);

        uint256 initialBalance = nftContract.owner().balance;

        vm.startPrank(nftContract.owner());
        nftContract.withdrawETH(nftContract.owner());
        vm.stopPrank();

        uint256 newBalance = nftContract.owner().balance;
        assertEq(address(nftContract).balance, 0);
        assertEq(newBalance, initialBalance + contractBalance);
    }

    function test__unit__RevertsWhen__EthTransferFails() public funded(USER) unpaused {
        uint256 amount = 1 ether;
        deal(address(nftContract), amount);

        uint256 contractBalance = address(nftContract).balance;
        assertGt(contractBalance, 0);

        address owner = nftContract.owner();

        vm.mockCallRevert(owner, amount, "", "");

        vm.expectRevert(NFTContract.NFTContract_EthTransferFailed.selector);
        vm.prank(owner);
        nftContract.withdrawETH(owner);
    }

    function test__unit__RevertWhen__NotOwnerWithdrawsETH() public funded(USER) {
        deal(address(nftContract), 1 ether);
        address owner = nftContract.owner();
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        console.log(USER);
        vm.prank(USER);
        nftContract.withdrawETH(owner);
    }

    /*//////////////////////////////////////////////////////////////
                          TEST WITHDRAW TOKENS
    //////////////////////////////////////////////////////////////*/
    function test__unit__WithdrawTokens() public funded(USER) {
        token.mint(address(nftContract), 1000 ether);

        uint256 contractBalance = token.balanceOf(address(nftContract));
        assertGt(contractBalance, 0);

        uint256 initialBalance = token.balanceOf(nftContract.owner());

        vm.startPrank(nftContract.owner());
        nftContract.withdrawTokens(address(token), nftContract.owner());
        vm.stopPrank();

        uint256 newBalance = token.balanceOf(nftContract.owner());
        assertEq(token.balanceOf(address(nftContract)), 0);
        assertEq(newBalance, initialBalance + contractBalance);
    }

    function test__unit__RevertsWhen__TokenTransferFails() public funded(USER) unpaused {
        uint256 amount = 1000 ether;
        token.mint(address(nftContract), amount);

        uint256 contractBalance = token.balanceOf(address(nftContract));
        assertGt(contractBalance, 0);

        address owner = nftContract.owner();

        vm.mockCall(address(token), abi.encodeWithSelector(token.transfer.selector, owner, amount), abi.encode(false));

        vm.expectRevert(NFTContract.NFTContract_TokenTransferFailed.selector);
        vm.prank(owner);
        nftContract.withdrawTokens(address(token), owner);
    }

    function test__unit__RevertWhen__NotOwnerWithdrawsTokens() public funded(USER) {
        token.mint(address(nftContract), 1000 ether);

        address owner = nftContract.owner();
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));

        vm.prank(USER);
        nftContract.withdrawTokens(address(token), owner);
    }

    /*//////////////////////////////////////////////////////////////
                          TEST SET CONTRACTURI
    //////////////////////////////////////////////////////////////*/
    function test__unit__SetContractURI() public {
        address owner = nftContract.owner();
        string memory newContractURI = "new-contract-uri/";

        vm.prank(owner);
        nftContract.setContractURI(newContractURI);

        assertEq(nftContract.getContractURI(), newContractURI);
    }

    function test__unit__EmitEvent__SetContractURI() public {
        address owner = nftContract.owner();
        string memory newContractURI = "new-contract-uri/";

        vm.expectEmit(true, true, true, true);
        emit ContractURIUpdated(owner, newContractURI);

        vm.prank(owner);
        nftContract.setContractURI(newContractURI);
    }

    function test__unit__RevertWhen__NotOwnerSetsContractURI() public {
        string memory newContractURI = "new-contract-uri/";
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));

        vm.prank(USER);
        nftContract.setContractURI(newContractURI);
    }

    /*//////////////////////////////////////////////////////////////
                            TEST SET BASEURI
    //////////////////////////////////////////////////////////////*/
    function test__unit__SetBaseURI() public {
        address owner = nftContract.owner();
        string memory newBaseURI = "new-base-uri/";

        vm.prank(owner);
        nftContract.setBaseURI(newBaseURI);

        assertEq(nftContract.getBaseURI(), newBaseURI);
    }

    function test__unit__EmitEvent__SetBaseURI() public {
        address owner = nftContract.owner();
        string memory newBaseURI = "new-base-uri/";

        vm.expectEmit(true, true, true, true);
        emit BaseURIUpdated(owner, newBaseURI);

        vm.prank(owner);
        nftContract.setBaseURI(newBaseURI);
    }

    function test__unit__RevertWhen__NotOwnerSetsBaseURI() public {
        string memory newBaseURI = "new-base-uri/";
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));

        vm.prank(USER);
        nftContract.setBaseURI(newBaseURI);
    }

    /*//////////////////////////////////////////////////////////////
                            TEST SET ROYALTY
    //////////////////////////////////////////////////////////////*/
    function test__unit__SetRoyalty() public {
        address owner = nftContract.owner();
        uint96 newRoyalty = 1000;

        vm.prank(owner);
        nftContract.setRoyalty(USER, newRoyalty);

        uint256 salePrice = 100;
        (address feeAddress, uint256 royaltyAmount) = nftContract.royaltyInfo(0, salePrice);
        assertEq(feeAddress, USER);
        assertEq(royaltyAmount, 10);
    }

    function test__unit__EmitEvent__SetRoyalty() public {
        uint96 newRoyalty = 1000;
        address owner = nftContract.owner();

        vm.expectEmit(true, true, true, true);
        emit RoyaltyUpdated(USER, newRoyalty);

        vm.prank(owner);
        nftContract.setRoyalty(USER, newRoyalty);
    }

    function test__unit__RevertWhen__NotOwnerSetsRoyalty() public {
        uint96 newRoyalty = 1000;
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));

        vm.prank(USER);
        nftContract.setRoyalty(USER, newRoyalty);
    }
}
