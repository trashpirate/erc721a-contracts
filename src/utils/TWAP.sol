// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {console} from "forge-std/console.sol";
import {IUniswapV3Pool} from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import {TickMath} from "@uniswap/v3-core/contracts/libraries/TickMath.sol";

/**
 *  @title TWAP
 *  @notice This contract allows the functionality to calculate the TWAP of a Uniswap V3 pool.
 *  @dev Needs to be adjusted if pool token1 != WETH
 */
contract TWAP {
    function calcTwapInEth(address pool, uint32 secondsAgo) public returns (uint256) {
        uint32[] memory secondsAgos = new uint32[](2);
        secondsAgos[0] = secondsAgo;
        secondsAgos[1] = 0;

        (int56[] memory tickCumulatives,) = IUniswapV3Pool(pool).observe(secondsAgos);

        // Calculate TWAP in terms of ticks
        int56 tickDifference = tickCumulatives[1] - tickCumulatives[0];
        int56 averageTick = tickDifference / int56(uint56(secondsAgo));

        // Calculate TWAP in terms of ETH per token (assuming pool token1 == WETH)
        uint256 sqrtPriceX96 = uint256(TickMath.getSqrtRatioAtTick(int24(averageTick)));
        uint256 ethPerToken = (sqrtPriceX96 * sqrtPriceX96 * 1e18) >> 192;

        return ethPerToken;
    }

    // uint256 ethUsdPrice = 2650 * 1e18; // ETH/USD price with 18 decimals
    // uint256 tokenUsdPrice = (ethPerToken * ethUsdPrice) / 1e18;
}
