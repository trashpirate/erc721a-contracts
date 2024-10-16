// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {FeeHandler} from "src/extensions/FeeHandler.sol";
import {NFTBasic} from "src/NFTBasic.sol";

/// @title NFTFeeHandler
/// @author Nadina Oates
/// @notice Contract implementing ERC721A standard with token and eth fee extension

contract NFTFeeHandler is NFTBasic, FeeHandler {
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
        FeeHandler(tokenAddress_, feeAddress_, tokenFee_, ethFee_)
    {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Mints NFT for a eth and a token fee
    /// @param quantity number of NFTs to mint
    function mint(uint256 quantity) external payable override validQuantity(quantity) {
        _safeMint(msg.sender, quantity);

        _chargeEthFee(quantity);
        _chargeTokenFee(quantity);
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
}
