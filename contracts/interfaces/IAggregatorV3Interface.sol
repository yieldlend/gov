// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAggregatorV3Interface {
    function latestAnswer() external view returns (int256);
}
