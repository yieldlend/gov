// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IAggregatorV3Interface} from "../interfaces/IAggregatorV3Interface.sol";

contract MockAggregator is IAggregatorV3Interface {
    int256 public price;

    constructor(int256 _price) {
        price = _price;
    }

    function latestAnswer() external view returns (int256) {
        return price;
    }
}
