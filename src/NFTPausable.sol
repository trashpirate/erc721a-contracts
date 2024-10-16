// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Pausable} from "src/utils/Pausable.sol";
import {NFTBasic} from "src/NFTBasic.sol";

/// @title NFTPausable
/// @author Nadina Oates
/// @notice Contract implementing ERC721A standard with pausable extension

contract NFTPausable is NFTBasic, Pausable {
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
    ) NFTBasic(name_, symbol_, baseURI_, contractURI_, owner_, maxSupply_) {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints NFT for a eth and a token fee
    /// @param quantity number of NFTs to mint
    function mint(uint256 quantity) external payable override whenNotPaused validQuantity(quantity) {
        _safeMint(msg.sender, quantity);
    }

    /// @notice Pauses contract (only owner)
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Unpauses contract (only owner)
    function unpause() external onlyOwner {
        _unpause();
    }
}
