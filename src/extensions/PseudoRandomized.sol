// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC721A, IERC721A} from "@erc721a/contracts/ERC721A.sol";

/**
 *  @title PseudoRandomized
 *  @notice This contract provides a mechanism pseudo randomize token URIs for NFTs.
 */
abstract contract PseudoRandomized is ERC721A {
    /*//////////////////////////////////////////////////////////////
                           STORAGE VARIABLES
    //////////////////////////////////////////////////////////////*/
    mapping(uint256 tokenId => uint256) private s_tokenURINumber;
    mapping(uint256 id => uint256) private s_ids;
    uint256 private s_numAvailableIds;
    uint256 private s_nonce;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event MetadataUpdated(uint256 indexed tokenId);

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    constructor(uint256 maxSupply) {
        // initialize randomization
        s_numAvailableIds = maxSupply;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice retrieves tokenURI
    /// @dev adapted from openzeppelin ERC721URIStorage contract
    /// @param tokenId tokenID of NFT
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireOwned(tokenId);

        string memory _tokenURI = Strings.toString(s_tokenURINumber[tokenId]);

        string memory base = _baseURI();

        // If both are set, concatenate the baseURI and tokenURI (via string.concat).
        if (bytes(_tokenURI).length > 0) {
            return string.concat(base, _tokenURI);
        }

        return super.tokenURI(tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                           INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    /// @notice Checks if token owner exists
    /// @dev adapted code from openzeppelin ERC721
    /// @param tokenId token id of NFT
    function _requireOwned(uint256 tokenId) internal view {
        ownerOf(tokenId);
    }

    /// @notice sets first tokenId to 1
    function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

    /// @notice Checks if token owner exists
    /// @dev adapted code from openzeppelin ERC721URIStorage
    /// @param tokenId tokenId of nft
    function _setTokenURI(uint256 tokenId) internal {
        s_tokenURINumber[tokenId] = _randomTokenURI();
        emit MetadataUpdated(tokenId);
    }

    /// @notice generates a random number
    function _random(uint256 nonce) internal view virtual returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, nonce)));
    }

    function _mintRandom(address to, uint256 quantity) internal virtual {
        // mint nfts
        uint256 tokenId = _nextTokenId();

        for (uint256 i = 0; i < quantity;) {
            _setTokenURI(tokenId);
            unchecked {
                tokenId++;
                i++;
            }
        }

        super._safeMint(to, quantity);
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice generates a random tokenURI
    function _randomTokenURI() private returns (uint256 randomTokenURI) {
        uint256 numAvailableIds = s_numAvailableIds;
        uint256 randIdx = _random(s_numAvailableIds) % numAvailableIds;

        // get new and nonexisting random id
        randomTokenURI = (s_ids[randIdx] > 0) ? s_ids[randIdx] : randIdx;

        // update helper array
        s_ids[randIdx] = (s_ids[numAvailableIds - 1] == 0) ? numAvailableIds - 1 : s_ids[numAvailableIds - 1];

        unchecked {
            s_numAvailableIds = numAvailableIds - 1;
        }
    }
}
