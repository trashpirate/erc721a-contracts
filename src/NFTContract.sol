// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Pausable} from "src/utils/Pausable.sol";
import {PseudoRandomized} from "src/extensions/PseudoRandomized.sol";
import {FeeHandler} from "src/extensions/FeeHandler.sol";
import {NFTBasic, ERC721A} from "src/NFTBasic.sol";

/// @title NFTContract NFTs
/// @author Nadina Oates
/// @notice Contract implementing ERC721A standard using ERC20 token and/or ETH for minting
/// @dev Inherits from ERC721A and ERC721ABurnable and openzeppelin Ownable

contract NFTContract is NFTBasic, Pausable, PseudoRandomized, FeeHandler {
    /*//////////////////////////////////////////////////////////////
                                 TYPES
    //////////////////////////////////////////////////////////////*/
    struct ConstructorArguments {
        string name;
        string symbol;
        string baseURI;
        string contractURI;
        address owner;
        address feeAddress;
        address tokenAddress;
        uint256 tokenFee;
        uint256 ethFee;
        uint256 maxSupply;
        uint256 maxWalletSize;
        uint256 batchLimit;
        uint96 royaltyNumerator;
    }

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Constructor
    /// @param name_ collection name
    /// @param symbol_ nft symbol
    /// @param baseURI_ base uri
    /// @param contractURI_ contract uri
    /// @param owner_ contract owner
    /// @param feeAddress_ address for fees
    /// @param tokenAddress_ erc20 token address used for fees
    /// @param maxSupply_ maximum nfts mintable
    /// @param ethFee_ minting fee in native coin
    /// @param tokenFee_ minting fee in erc20
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        address owner_,
        address feeAddress_,
        address tokenAddress_,
        uint256 tokenFee_,
        uint256 ethFee_,
        uint256 maxSupply_
    )
        NFTBasic(name_, symbol_, baseURI_, contractURI_, owner_, maxSupply_)
        PseudoRandomized(maxSupply_)
        FeeHandler(tokenAddress_, feeAddress_, tokenFee_, ethFee_)
    {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints NFT for a eth and a token fee
    /// @param quantity number of NFTs to mint
    function mint(uint256 quantity) external payable override whenNotPaused validQuantity(quantity) {
        _mintRandom(msg.sender, quantity);

        _chargeEthFee(quantity);
        _chargeTokenFee(quantity);
    }

    /// @notice Pauses contract (only owner)
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract (only owner)
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Sets minting fee in ETH (only owner)
    /// @param fee New fee in ETH
    function setEthFee(uint256 fee) external onlyOwner {
        _setEthFee(fee);
    }

    /// @notice Sets minting fee in ERC20 (only owner)
    /// @param fee New fee in ERC20
    function setTokenFee(uint256 fee) external onlyOwner {
        _setTokenFee(fee);
    }

    /// @notice Sets the receiver address for the token/ETH fee (only owner)
    /// @param feeAddress New receiver address for tokens and ETH received through minting
    function setFeeAddress(address feeAddress) external onlyOwner {
        _setFeeAddress(feeAddress);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice retrieves tokenURI
    /// @dev override required by ERC721A
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(NFTBasic, PseudoRandomized)
        returns (string memory)
    {
        return PseudoRandomized.tokenURI(tokenId);
    }

    /// @notice checks for supported interface
    /// @dev function override required by ERC721A
    /// @param interfaceId interfaceId to be checked
    function supportsInterface(bytes4 interfaceId) public view override(ERC721A, NFTBasic) returns (bool) {
        return NFTBasic.supportsInterface(interfaceId);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Retrieves base uri
    /// @dev override required by ERC721A
    function _baseURI() internal view override(ERC721A, NFTBasic) returns (string memory) {
        return NFTBasic._baseURI();
    }

    /// @notice sets first tokenId to 1
    /// @dev override required by ERC721A
    function _startTokenId() internal view override(NFTBasic, PseudoRandomized) returns (uint256) {
        return PseudoRandomized._startTokenId();
    }
}
