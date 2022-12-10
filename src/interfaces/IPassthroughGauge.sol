// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IPassthroughGauge {
    function passthroughRewards(uint256 _amount) external;
}
