// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
import {DataTypes} from "../libraries/DataTypes.sol";

interface ITomoMemeCoinFactory {
    function parameters()
        external
        view
        returns (DataTypes.CreateTomoMemeCoinParameters memory);

    function _memeCoinContract(
        address creator,
        string calldata name
    ) external view returns (address);

    function _tomoMemeCoinManager() external view returns (address);
}
