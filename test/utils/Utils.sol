// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library StringToNumber {
    function stringToUint(string memory s) public pure returns (uint256) {
        bytes memory b = bytes(s);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] >= 0x30 && b[i] <= 0x39) {
                result = result * 10 + (uint256(uint8(b[i])) - 48);
            } else {
                // Handle invalid characters (non-digits)
                revert("Invalid character in string");
            }
        }
        return result;
    }
}
