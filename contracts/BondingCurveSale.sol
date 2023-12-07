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

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAggregatorV3Interface} from "./interfaces/IAggregatorV3Interface.sol";
import {IBondingCurveSale} from "./interfaces/IBondingCurveSale.sol";

import "hardhat/console.sol";

/// @title  A bonding curve sale that is accepts ether for YIELD tokens.
contract BondingCurveSale is
    IBondingCurveSale,
    Ownable,
    IAggregatorV3Interface
{
    uint256 private constant PRECISION = 1e18;

    address public destination;
    IAggregatorV3Interface public immutable ethUsdPrice;
    IERC20 public immutable token;
    uint256 public immutable ethToRaise;
    uint256 public immutable reserveInLP;
    uint256 public immutable reserveToSell;

    // variables to track
    uint256 public ethRaised;
    uint256 public reserveSold;

    constructor(
        address _destination,
        address _ethUsdPrice,
        IERC20 _token,
        uint256 _ethToRaise,
        uint256 _reserveInLP,
        uint256 _reserveToSell
    ) {
        destination = _destination;
        ethToRaise = _ethToRaise;
        ethUsdPrice = IAggregatorV3Interface(_ethUsdPrice);
        reserveInLP = _reserveInLP;
        reserveSold = 0;
        reserveToSell = _reserveToSell;
        token = _token;
    }

    function latestAnswer() external view returns (int256) {
        uint256 ethInLP = (ethRaised * 3) / 5;
        int256 ethPrice = ethUsdPrice.latestAnswer();

        // totalSupply * ((ethInLp * ethPrice) / reserveInLP)
        uint256 result = (((token.totalSupply() * ethInLP)) *
            uint256(ethPrice)) /
            reserveInLP /
            1e30;

        return int256(result);
    }

    /// @inheritdoc IBondingCurveSale
    function bondingCurveETH(uint256 _ethRaised) public view returns (uint256) {
        uint256 percentage = ((_ethRaised * PRECISION) / ethToRaise);
        uint256 reversed = PRECISION - percentage;
        return
            (reserveToSell *
                (PRECISION - ((reversed * reversed) / PRECISION))) / PRECISION;
    }

    /// @inheritdoc IBondingCurveSale
    function mint() external payable {
        // calculate tokens sold baesd on the ETH raised
        ethRaised += msg.value;
        uint256 newTokensSold = bondingCurveETH(ethRaised);
        uint256 reserveSoldToBuyer = newTokensSold - reserveSold;
        reserveSold = newTokensSold;

        // send 3/5th to LP
        payable(destination).transfer((msg.value * 3) / 5);

        // send 2/5th to marketing wallet
        payable(owner()).transfer((msg.value * 2) / 5);

        // give the user the tokens that were sold
        token.transfer(msg.sender, reserveSoldToBuyer);

        emit Minted(msg.sender, reserveSoldToBuyer, msg.value);
    }

    /// @inheritdoc IBondingCurveSale
    function setDestination(address _destination) external onlyOwner {
        destination = _destination;
    }

    /// @inheritdoc IBondingCurveSale
    function withdrawStuckTokens(address tkn) external onlyOwner {
        bool success;
        if (tkn == address(0))
            (success, ) = address(msg.sender).call{
                value: address(this).balance
            }("");
        else {
            require(IERC20(tkn).balanceOf(address(this)) > 0, "No tokens");
            uint256 amount = IERC20(tkn).balanceOf(address(this));
            IERC20(tkn).transfer(msg.sender, amount);
        }
    }
}
