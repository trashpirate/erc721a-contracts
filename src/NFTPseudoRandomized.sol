// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {PseudoRandomized} from "src/extensions/PseudoRandomized.sol";
import {NFTBasic, ERC721A} from "src/NFTBasic.sol";

/// @title NFTPseudoRandomized
/// @author Nadina Oates
/// @notice Contract implementing ERC721A standard with pseudorandomized token uris

contract NFTPseudoRandomized is NFTBasic, PseudoRandomized {
    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Constructor
    /// @param name_ collection name
    /// @param symbol_ nft symbol
    /// @param baseURI_ base uri
    /// @param contractURI_ contract uri
    /// @param owner_ contract owner
    /// @param maxSupply_ maximum nfts mintable
    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseURI_,
        string memory contractURI_,
        address owner_,
        uint256 maxSupply_
    ) NFTBasic(name_, symbol_, baseURI_, contractURI_, owner_, maxSupply_) PseudoRandomized(maxSupply_) {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints NFT for a eth and a token fee
    /// @param quantity number of NFTs to mint
    function mint(uint256 quantity) external payable override validQuantity(quantity) {
        _mintRandom(msg.sender, quantity);
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
