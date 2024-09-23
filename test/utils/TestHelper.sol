// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

contract TestHelper {
    mapping(string => bool) public tokenUris;

    function setTokenUri(string memory tokenUri) public {
        tokenUris[tokenUri] = true;
    }

    function isTokenUriSet(string memory tokenUri) public view returns (bool) {
        return tokenUris[tokenUri];
    }
}
