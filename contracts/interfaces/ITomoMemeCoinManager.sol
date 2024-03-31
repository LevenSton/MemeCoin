// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {DataTypes} from "../libraries/DataTypes.sol";

interface ITomoMemeCoinManager {
    function getSwapRouter() external view returns (address, address);

    function prePairTomoMemeCoinEnv(
        address tomoMemeCoinAddr,
        uint160 sqrtPriceX96,
        uint160 sqrtPriceB96
    ) external returns (address);

    function addLiquidityForTomoMemeCoin(
        address tomoMemeCoinAddr,
        uint256 tokenAmount
    ) external payable returns (bool);

    function removeLiquidityForEmergece(
        uint256 tokenId,
        uint128 liquidity,
        address receiptAddress
    ) external payable returns (bool);

    function getCreatTomoMemeCoinParam()
        external
        view
        returns (bool, uint256, uint256);
}
