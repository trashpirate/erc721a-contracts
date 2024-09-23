// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {ERC721A, IERC721A} from "@erc721a/contracts/ERC721A.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 *  @title Whitelist
 *  @notice This contract provides a mechanism to whitelist addresses for minting NFTs.
 */
abstract contract Whitelist {
    /*//////////////////////////////////////////////////////////////
                           STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/
    bytes32 private s_merkleRoot;

    mapping(address claimer => bool) private s_hasClaimed;

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/
    error Whitelist__InvalidProof();
    error Whitelist__AlreadyClaimed();

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/
    modifier onlyNotClaimed(address account) {
        if (!s_hasClaimed[account]) {
            revert Whitelist__AlreadyClaimed();
        }
        _;
    }

    constructor() {}

    /*//////////////////////////////////////////////////////////////
                           EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the merkle root
    /// @param merkleRoot New merkle root
    function setMerkleRoot(bytes32 merkleRoot) external {
        s_merkleRoot = merkleRoot;
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Verifies the claimer's address
    /// @param account Account to verify
    /// @param merkleProof Proof of the claimer's address
    function _verifyClaimer(address account, bytes32[] calldata merkleProof) internal view {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(account))));

        if (!MerkleProof.verify(merkleProof, s_merkleRoot, leaf)) {
            revert Whitelist__InvalidProof();
        }
    }

    /// @notice Sets the claim status of an account
    /// @param account Account to set the claim status for
    /// @param claimed Claim status
    function _hasClaimed(address account, bool claimed) internal {
        s_hasClaimed[account] = claimed;
    }

    /*//////////////////////////////////////////////////////////////
                                GETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Returns the merkle root
    function getMerkleRoot() external view returns (bytes32) {
        return s_merkleRoot;
    }
}
