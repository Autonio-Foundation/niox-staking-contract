// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface KeeperCompatibleInterface {
    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData);
    function performUpkeep(bytes calldata performData) external;
}