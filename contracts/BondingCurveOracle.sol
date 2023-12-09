// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

//            /$$           /$$       /$$
//           |__/          | $$      | $$
//  /$$   /$$ /$$  /$$$$$$ | $$  /$$$$$$$
// | $$  | $$| $$ /$$__  $$| $$ /$$__  $$
// | $$  | $$| $$| $$$$$$$$| $$| $$  | $$
// | $$  | $$| $$| $$_____/| $$| $$  | $$
// |  $$$$$$$| $$|  $$$$$$$| $$|  $$$$$$$
//  \____  $$|__/ \_______/|__/ \_______/
//  /$$  | $$
// |  $$$$$$/
//  \______/
//
// Website: https://yieldlend.xyz
// Discord: https://discord.com/invite/RvyTxAFtuf
// Twitter: https://twitter.com/yieldlend

import {IAggregatorV3Interface} from "./interfaces/IAggregatorV3Interface.sol";
import {IBondingCurveSale} from "./interfaces/IBondingCurveSale.sol";

/// @title  A contract that fetches the current price of YIELD based on how much was raised; useful for the price
contract BondingCurveOracle is IAggregatorV3Interface {
    IAggregatorV3Interface public immutable ethUsdPrice;
    IBondingCurveSale public sale;
    uint256 public maxTokensInLP;

    constructor(address _sale, address _ethUsdPrice, uint256 _maxTokensInLP) {
        maxTokensInLP = _maxTokensInLP;
        sale = IBondingCurveSale(_sale);
        ethUsdPrice = IAggregatorV3Interface(_ethUsdPrice);
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }

    function latestAnswer() external view returns (int256) {
        uint256 percentageE18 = (sale.ethRaised() * 1e18) / sale.ethToRaise();
        uint256 tokensInLP = (maxTokensInLP * percentageE18) / 1e18;

        uint256 ethInLP = (sale.ethRaised() * 3) / 5;
        int256 ethPrice = ethUsdPrice.latestAnswer();

        uint256 price = (ethInLP * uint256(ethPrice)) / tokensInLP;
        return int256(price);
    }
}
