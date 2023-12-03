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
// Telegram: https://t.me/yieldlend
// Twitter: https://twitter.com/yieldlend

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IBondingCurveSale} from "./interfaces/IBondingCurveSale.sol";

/// @title  A bonding curve sale that is accepts ether for YIELD tokens.
contract BondingCurveSale is IBondingCurveSale, Ownable {
    uint256 private constant PRECISION = 1e18;

    address public destination;
    IERC20 public token;

    uint256 public reserveToSell;
    uint256 public ethToRaise;

    uint256 public ethRaised;
    uint256 public reserveSold;

    constructor(
        address _destination,
        IERC20 _token,
        uint256 _reserveToSell,
        uint256 _ethToRaise
    ) {
        destination = _destination;
        token = _token;
        reserveToSell = _reserveToSell;
        reserveSold = 0;
        ethToRaise = _ethToRaise;
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

        // send 4/5th to LP
        payable(destination).transfer((msg.value * 4) / 5);

        // send 1/5th to marketing wallet
        payable(owner()).transfer(msg.value / 5);

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
