// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC721A, IERC721A} from "@erc721a/contracts/ERC721A.sol";

/**
 *  @title FeeHandler
 *  @notice This contract provides a mechanism to charge fees for minting NFTs.
 */
abstract contract FeeHandler {
    /*//////////////////////////////////////////////////////////////
                           STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IERC20 private immutable i_feeToken;

    address private s_feeAddress;
    uint256 private s_tokenFee;
    uint256 private s_ethFee;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event TokenFeeSet(address indexed sender, uint256 indexed fee);
    event EthFeeSet(address indexed sender, uint256 indexed fee);
    event FeeAddressSet(address indexed sender, address feeAddress);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error FeeHandler_FeeAddressIsZeroAddress();
    error FeeHandler_InsufficientEthFee(uint256 value, uint256 fee);
    error FeeHandler_TokenTransferFailed();
    error FeeHandler_EthTransferFailed();

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(address feeToken, address feeAddress, uint256 tokenFee, uint256 ethFee) {
        if (feeAddress == address(0)) {
            revert FeeHandler_FeeAddressIsZeroAddress();
        }

        i_feeToken = IERC20(feeToken);
        s_feeAddress = feeAddress;
        s_tokenFee = tokenFee;
        s_ethFee = ethFee;
    }

    receive() external payable {}

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Charges the minting fee in tokens
    /// @param quantity Number of NFTs to mint
    function _chargeTokenFee(uint256 quantity) internal {
        // pay mint fee in tokens
        uint256 tokenFee = s_tokenFee;
        if (tokenFee > 0) {
            uint256 totalTokenFee = tokenFee * quantity;
            bool success = i_feeToken.transferFrom(msg.sender, s_feeAddress, totalTokenFee);
            if (!success) revert FeeHandler_TokenTransferFailed();
        }
    }

    /// @notice Charges the minting fee in ETH
    /// @param quantity Number of NFTs to mint
    function _chargeEthFee(uint256 quantity) internal {
        // pay mint fee in ETH
        uint256 ethFee = s_ethFee;
        if (ethFee > 0) {
            uint256 totalEthFee = ethFee * quantity;
            if (msg.value < totalEthFee) {
                revert FeeHandler_InsufficientEthFee(msg.value, totalEthFee);
            }
            (bool success,) = payable(s_feeAddress).call{value: totalEthFee}("");
            if (!success) revert FeeHandler_EthTransferFailed();
        }
    }

    // @notice Sets minting fee in ETH
    /// @param fee New fee in ETH
    function _setEthFee(uint256 fee) internal {
        s_ethFee = fee;
        emit EthFeeSet(msg.sender, fee);
    }

    /// @notice Sets minting fee in ERC20
    /// @param fee New fee in ERC20
    function _setTokenFee(uint256 fee) internal {
        s_tokenFee = fee;
        emit TokenFeeSet(msg.sender, fee);
    }

    /// @notice Sets the receiver address for the token/ETH fee
    /// @param feeAddress New receiver address for tokens and ETH received through minting
    function _setFeeAddress(address feeAddress) internal {
        if (feeAddress == address(0)) {
            revert FeeHandler_FeeAddressIsZeroAddress();
        }
        s_feeAddress = feeAddress;
        emit FeeAddressSet(msg.sender, feeAddress);
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns minting fee in ETH
    function getEthFee() external view returns (uint256) {
        return s_ethFee;
    }

    /// @notice Returns minting fee in ERC20
    function getTokenFee() external view returns (uint256) {
        return s_tokenFee;
    }

    /// @notice Returns fee token address
    function getFeeToken() external view returns (address) {
        return address(i_feeToken);
    }

    /// @notice Returns address that receives minting fees
    function getFeeAddress() external view returns (address) {
        return s_feeAddress;
    }
}
