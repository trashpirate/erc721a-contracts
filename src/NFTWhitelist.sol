// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Whitelist} from "src/extensions/Whitelist.sol";
import {NFTBasic} from "src/NFTBasic.sol";

/// @title NFTWhitelist
/// @author Nadina Oates
/// @notice Contract implementing ERC721A standard with Whitelist extension

contract NFTWhitelist is NFTBasic, Whitelist {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    error NFTWhitelist__InvalidMinter();

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
        uint256 maxSupply_,
        bytes32 merkleRoot_
    ) NFTBasic(name_, symbol_, baseURI_, contractURI_, owner_, maxSupply_) Whitelist(merkleRoot_) {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints NFT for a eth and a token fee
    /// @param quantity number of NFTs to mint
    function mint(uint256 quantity, bytes32[] calldata merkleProof) external validQuantity(quantity) {
        if (_verifyClaimer(msg.sender, merkleProof) && !hasClaimed(msg.sender)) {
            _setClaimStatus(msg.sender, true);
            _mint(msg.sender, quantity);
        } else {
            revert NFTWhitelist__InvalidMinter();
        }
    }

    /// @notice Sets the merkle root
    /// @param merkleRoot New merkle root
    function setMerkleRoot(bytes32 merkleRoot) external onlyOwner {
        _setMerkleRoot(merkleRoot);
    }
}
