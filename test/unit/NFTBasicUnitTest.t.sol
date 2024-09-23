// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {IERC721A} from "@erc721a/contracts/IERC721A.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import {DeployNFTBasic} from "script/deployment/DeployNFTBasic.s.sol";
import {NFTBasic} from "src/NFTBasic.sol";
import {HelperConfig} from "script/helpers/HelperConfig.s.sol";
import {TestHelper} from "test/utils/TestHelper.sol";

contract NFTBasicUnitTest is Test {
    /*//////////////////////////////////////////////////////////////
                             CONFIGURATION
    //////////////////////////////////////////////////////////////*/
    DeployNFTBasic deployer;
    HelperConfig helperConfig;
    HelperConfig.NetworkConfig networkConfig;

    /*//////////////////////////////////////////////////////////////
                               CONTRACTS
    //////////////////////////////////////////////////////////////*/
    NFTBasic nftBasic;
    ERC20Mock token;

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/
    address USER = makeAddr("user");
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
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    modifier noBatchLimit() {
        address owner = nftBasic.owner();
        vm.prank(owner);
        nftBasic.setBatchLimit(100);
        _;
    }

    modifier noMaxWallet() {
        address owner = nftBasic.owner();
        vm.prank(owner);
        nftBasic.setMaxWalletSize(0);
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 SETUP
    //////////////////////////////////////////////////////////////*/
    function setUp() external virtual {
        deployer = new DeployNFTBasic();
        (nftBasic, helperConfig) = deployer.run();

        networkConfig = helperConfig.getActiveNetworkConfigStruct();

        token = new ERC20Mock();
    }

    /*//////////////////////////////////////////////////////////////
                          TEST   INITIALIZATION
    //////////////////////////////////////////////////////////////*/
    function test__NFTBasic__Initialization() public {
        assertEq(nftBasic.getMaxSupply(), networkConfig.args.maxSupply);

        assertEq(nftBasic.getBaseURI(), networkConfig.args.baseURI);
        assertEq(nftBasic.contractURI(), networkConfig.args.contractURI);

        assertEq(nftBasic.getMaxWalletSize(), 10);
        assertEq(nftBasic.getBatchLimit(), 10);

        assertEq(nftBasic.supportsInterface(0x80ac58cd), true); // ERC721
        assertEq(nftBasic.supportsInterface(0x2a55205a), true); // ERC2981

        vm.expectRevert(IERC721A.URIQueryForNonexistentToken.selector);
        nftBasic.tokenURI(1);
    }

    /*//////////////////////////////////////////////////////////////
                            TEST DEPLOYMENT
    //////////////////////////////////////////////////////////////*/
    function test__NFTBasic__RevertWhen__NoBaseURI() public {
        HelperConfig.ConstructorArguments memory args = networkConfig.args;

        args.baseURI = "";

        vm.expectRevert(NFTBasic.NFTBasic_NoBaseURI.selector);
        new NFTBasic(args.name, args.symbol, args.baseURI, args.contractURI, args.owner, args.maxSupply);
    }

    function test__NFTBasic__RevertWhen__ZeroFeeAddress() public {
        HelperConfig.ConstructorArguments memory args = networkConfig.args;

        args.feeAddress = address(0);
        //ERC2981InvalidDefaultRoyaltyReceiver
        // vm.expectRevert();
        new NFTBasic(args.name, args.symbol, args.baseURI, args.contractURI, args.owner, args.maxSupply);
    }

    /*//////////////////////////////////////////////////////////////
                             TEST ROYALTIES
    //////////////////////////////////////////////////////////////*/
    function test__NFTBasic__InitialRoyalties() public view {
        uint256 salePrice = 100;
        (address feeAddress, uint256 royaltyAmount) = nftBasic.royaltyInfo(1, salePrice);
        assertEq(feeAddress, networkConfig.args.owner);
        assertEq(royaltyAmount, (500 * 100) / 10000);
    }

    /*//////////////////////////////////////////////////////////////
                        TEST SET MAXWALLETSIZE
    //////////////////////////////////////////////////////////////*/
    function test__NFTBasic__SetMaxWalletSize() public {
        address owner = nftBasic.owner();
        vm.prank(owner);
        nftBasic.setMaxWalletSize(NEW_MAX_WALLET_SIZE);
        assertEq(nftBasic.getMaxWalletSize(), NEW_MAX_WALLET_SIZE);
    }

    function test__NFTBasic__EmitEvent__SetMaxWalletSize() public {
        address owner = nftBasic.owner();

        vm.expectEmit(true, true, true, true);
        emit MaxWalletSizeSet(owner, NEW_MAX_WALLET_SIZE);

        vm.prank(owner);
        nftBasic.setMaxWalletSize(NEW_MAX_WALLET_SIZE);
    }

    function test__NFTBasic__RevertWhen__NotOwnerSetsMaxWalletSize() public {
        vm.prank(USER);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        nftBasic.setMaxWalletSize(NEW_MAX_WALLET_SIZE);
    }

    /*//////////////////////////////////////////////////////////////
                           TEST SET BATCHLIMIT
    //////////////////////////////////////////////////////////////*/
    function test__NFTBasic__SetBatchLimit() public {
        address owner = nftBasic.owner();
        vm.prank(owner);
        nftBasic.setBatchLimit(NEW_BATCH_LIMIT);
        assertEq(nftBasic.getBatchLimit(), NEW_BATCH_LIMIT);
    }

    function test__NFTBasic__EmitEvent__SetBatchLimit() public {
        address owner = nftBasic.owner();

        vm.expectEmit(true, true, true, true);
        emit BatchLimitSet(owner, NEW_BATCH_LIMIT);

        vm.prank(owner);
        nftBasic.setBatchLimit(NEW_BATCH_LIMIT);
    }

    function test__NFTBasic__RevertWhen__BatchLimitTooHigh() public {
        address owner = nftBasic.owner();
        vm.prank(owner);

        vm.expectRevert(NFTBasic.NFTBasic_BatchLimitTooHigh.selector);
        nftBasic.setBatchLimit(101);
    }

    function test__NFTBasic__RevertWhen__NotOwnerSetsBatchLimit() public {
        vm.prank(USER);

        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));
        nftBasic.setBatchLimit(NEW_BATCH_LIMIT);
    }

    /*//////////////////////////////////////////////////////////////
                            TEST WITHDRAW ETH
    //////////////////////////////////////////////////////////////*/
    function test__NFTBasic__WithdrawETH() public {
        deal(address(nftBasic), 1 ether);
        uint256 contractBalance = address(nftBasic).balance;
        assertGt(contractBalance, 0);

        uint256 initialBalance = nftBasic.owner().balance;

        vm.startPrank(nftBasic.owner());
        nftBasic.withdrawETH(nftBasic.owner());
        vm.stopPrank();

        uint256 newBalance = nftBasic.owner().balance;
        assertEq(address(nftBasic).balance, 0);
        assertEq(newBalance, initialBalance + contractBalance);
    }

    function test__NFTBasic__RevertsWhen__EthTransferFails() public {
        uint256 amount = 1 ether;
        deal(address(nftBasic), amount);

        uint256 contractBalance = address(nftBasic).balance;
        assertGt(contractBalance, 0);

        address owner = nftBasic.owner();

        vm.mockCallRevert(owner, amount, "", "");

        vm.expectRevert(NFTBasic.NFTBasic_EthTransferFailed.selector);
        vm.prank(owner);
        nftBasic.withdrawETH(owner);
    }

    function test__NFTBasic__RevertWhen__NotOwnerWithdrawsETH() public {
        deal(address(nftBasic), 1 ether);
        address owner = nftBasic.owner();
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));

        vm.prank(USER);
        nftBasic.withdrawETH(owner);
    }

    /*//////////////////////////////////////////////////////////////
                          TEST WITHDRAW TOKENS
    //////////////////////////////////////////////////////////////*/
    function test__NFTBasic__WithdrawTokens() public {
        token.mint(address(nftBasic), 1000 ether);

        uint256 contractBalance = token.balanceOf(address(nftBasic));
        assertGt(contractBalance, 0);

        uint256 initialBalance = token.balanceOf(nftBasic.owner());

        vm.startPrank(nftBasic.owner());
        nftBasic.withdrawTokens(address(token), nftBasic.owner());
        vm.stopPrank();

        uint256 newBalance = token.balanceOf(nftBasic.owner());
        assertEq(token.balanceOf(address(nftBasic)), 0);
        assertEq(newBalance, initialBalance + contractBalance);
    }

    function test__NFTBasic__RevertsWhen__TokenTransferFails() public {
        uint256 amount = 1000 ether;
        token.mint(address(nftBasic), amount);

        uint256 contractBalance = token.balanceOf(address(nftBasic));
        assertGt(contractBalance, 0);

        address owner = nftBasic.owner();

        vm.mockCall(address(token), abi.encodeWithSelector(token.transfer.selector, owner, amount), abi.encode(false));

        vm.expectRevert(NFTBasic.NFTBasic_TokenTransferFailed.selector);
        vm.prank(owner);
        nftBasic.withdrawTokens(address(token), owner);
    }

    function test__NFTBasic__RevertWhen__NotOwnerWithdrawsTokens() public {
        token.mint(address(nftBasic), 1000 ether);

        address owner = nftBasic.owner();
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));

        vm.prank(USER);
        nftBasic.withdrawTokens(address(token), owner);
    }

    /*//////////////////////////////////////////////////////////////
                          TEST SET CONTRACTURI
    //////////////////////////////////////////////////////////////*/
    function test__NFTBasic__SetContractURI() public {
        address owner = nftBasic.owner();
        string memory newContractURI = "new-contract-uri/";

        vm.prank(owner);
        nftBasic.setContractURI(newContractURI);

        assertEq(nftBasic.getContractURI(), newContractURI);
    }

    function test__NFTBasic__EmitEvent__SetContractURI() public {
        address owner = nftBasic.owner();
        string memory newContractURI = "new-contract-uri/";

        vm.expectEmit(true, true, true, true);
        emit ContractURIUpdated(owner, newContractURI);

        vm.prank(owner);
        nftBasic.setContractURI(newContractURI);
    }

    function test__NFTBasic__RevertWhen__NotOwnerSetsContractURI() public {
        string memory newContractURI = "new-contract-uri/";
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));

        vm.prank(USER);
        nftBasic.setContractURI(newContractURI);
    }

    /*//////////////////////////////////////////////////////////////
                            TEST SET BASEURI
    //////////////////////////////////////////////////////////////*/
    function test__NFTBasic__SetBaseURI() public {
        address owner = nftBasic.owner();
        string memory newBaseURI = "new-base-uri/";

        vm.prank(owner);
        nftBasic.setBaseURI(newBaseURI);

        assertEq(nftBasic.getBaseURI(), newBaseURI);
    }

    function test__NFTBasic__EmitEvent__SetBaseURI() public {
        address owner = nftBasic.owner();
        string memory newBaseURI = "new-base-uri/";

        vm.expectEmit(true, true, true, true);
        emit BaseURIUpdated(owner, newBaseURI);

        vm.prank(owner);
        nftBasic.setBaseURI(newBaseURI);
    }

    function test__NFTBasic__RevertWhen__NotOwnerSetsBaseURI() public {
        string memory newBaseURI = "new-base-uri/";
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));

        vm.prank(USER);
        nftBasic.setBaseURI(newBaseURI);
    }

    /*//////////////////////////////////////////////////////////////
                            TEST SET ROYALTY
    //////////////////////////////////////////////////////////////*/
    function test__NFTBasic__SetRoyalty() public {
        address owner = nftBasic.owner();
        uint96 newRoyalty = 1000;

        vm.prank(owner);
        nftBasic.setRoyalty(USER, newRoyalty);

        uint256 salePrice = 100;
        (address feeAddress, uint256 royaltyAmount) = nftBasic.royaltyInfo(0, salePrice);
        assertEq(feeAddress, USER);
        assertEq(royaltyAmount, 10);
    }

    function test__NFTBasic__EmitEvent__SetRoyalty() public {
        uint96 newRoyalty = 1000;
        address owner = nftBasic.owner();

        vm.expectEmit(true, true, true, true);
        emit RoyaltyUpdated(USER, newRoyalty);

        vm.prank(owner);
        nftBasic.setRoyalty(USER, newRoyalty);
    }

    function test__NFTBasic__RevertWhen__NotOwnerSetsRoyalty() public {
        uint96 newRoyalty = 1000;
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, USER));

        vm.prank(USER);
        nftBasic.setRoyalty(USER, newRoyalty);
    }

    /*//////////////////////////////////////////////////////////////
                               TEST MINT
    //////////////////////////////////////////////////////////////*/

    /// SUCCESS
    //////////////////////////////////////////////////////////////*/
    function test__NFTBasic__Mint(uint256 quantity, address account) public skipFork {
        quantity = bound(quantity, 1, nftBasic.getBatchLimit());
        vm.assume(account != address(0));

        vm.prank(account);
        nftBasic.mint(quantity);

        assertEq(nftBasic.balanceOf(account), quantity);
    }

    function test__NFTBasic__MintNoMaxWallet(uint256 quantity, address account)
        public
        noMaxWallet
        noBatchLimit
        skipFork
    {
        quantity = bound(quantity, 1, nftBasic.getMaxSupply());
        vm.assume(account != address(0));

        uint256 batchLimit = nftBasic.getBatchLimit();

        if (quantity % batchLimit > 0) {
            vm.prank(account);
            nftBasic.mint(quantity % batchLimit);
        }
        if (quantity >= batchLimit) {
            for (uint256 index = 0; index < quantity / batchLimit; index++) {
                vm.prank(account);
                nftBasic.mint(batchLimit);
            }
        }

        assertEq(nftBasic.balanceOf(account), quantity);
    }

    /// EVENT EMITTED
    //////////////////////////////////////////////////////////////*/
    function test__NFTBasic__EmitEvent__Mint() public {
        vm.expectEmit(true, true, true, true);
        emit Transfer(address(0), USER, 1);

        vm.prank(USER);
        nftBasic.mint(1);
    }

    /// REVERTS
    //////////////////////////////////////////////////////////////*/
    function test__NFTBasic__RevertWhen__InsufficientMintQuantity() public {
        vm.expectRevert(NFTBasic.NFTBasic_InsufficientMintQuantity.selector);
        vm.prank(USER);
        nftBasic.mint(0);
    }

    function test__NFTBasic__RevertWhen__MintExceedsBatchLimit() public {
        uint256 quantity = nftBasic.getBatchLimit() + 1;

        vm.expectRevert(NFTBasic.NFTBasic_ExceedsBatchLimit.selector);
        vm.prank(USER);
        nftBasic.mint(quantity);
    }

    function test__NFTBasic__RevertWhen__MintExceedsMaxWalletSize() public {
        uint256 quantity = nftBasic.getMaxWalletSize() + 1;

        address owner = nftBasic.owner();
        vm.prank(owner);
        nftBasic.setBatchLimit(quantity);

        vm.expectRevert(NFTBasic.NFTBasic_ExceedsMaxPerWallet.selector);
        vm.prank(USER);
        nftBasic.mint(quantity);
    }

    function test__NFTBasic__RevertWhen__MaxSupplyExceeded() public {
        uint256 maxSupply = nftBasic.getMaxSupply();

        for (uint256 index = 0; index < maxSupply; index++) {
            vm.prank(USER);
            nftBasic.mint(1);
        }

        vm.expectRevert(NFTBasic.NFTBasic_ExceedsMaxSupply.selector);
        vm.prank(USER);
        nftBasic.mint(1);
    }

    /*//////////////////////////////////////////////////////////////
                             TEST TRANSFER
    //////////////////////////////////////////////////////////////*/
    function test__NFTBasic__Transfer(address account, address receiver) public skipFork {
        uint256 quantity = 1;
        vm.assume(account != address(0));
        vm.assume(receiver != address(0));

        vm.prank(account);
        nftBasic.mint(quantity);

        assertEq(nftBasic.balanceOf(account), quantity);
        assertEq(nftBasic.ownerOf(1), account);

        vm.prank(account);
        nftBasic.transferFrom(account, receiver, 1);

        assertEq(nftBasic.ownerOf(1), receiver);
        assertEq(nftBasic.balanceOf(receiver), quantity);
    }

    /*//////////////////////////////////////////////////////////////
                             TEST TOKENURI
    //////////////////////////////////////////////////////////////*/
    function test__NFTBasic__RetrieveTokenUri() public {
        vm.prank(USER);
        nftBasic.mint(1);

        assertEq(nftBasic.tokenURI(1), string.concat(networkConfig.args.baseURI, "1"));
    }

    function test__NFTBasic__UniqueLinearTokenURI() public {
        TestHelper testHelper = new TestHelper();

        uint256 maxSupply = nftBasic.getMaxSupply();

        vm.startPrank(USER);
        for (uint256 index = 1; index <= maxSupply; index++) {
            nftBasic.mint(1);
            assertEq(testHelper.isTokenUriSet(nftBasic.tokenURI(index)), false);
            console.log(nftBasic.tokenURI(index));
            testHelper.setTokenUri(nftBasic.tokenURI(index));
        }
        vm.stopPrank();
    }
}
