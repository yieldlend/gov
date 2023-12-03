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

/// @title  A bonding curve sale that is accepts ether for YIELD tokens.
contract BondingCurveSale is Ownable {
    event Minted(uint256 amount, uint256 totalCost);

    uint256 private constant PRECISION = 1e18;

    address public destination;
    IERC20 public token;

    uint256 public reserveToSell;
    uint256 public ethToRaise;

    constructor(IERC20 _token, uint256 _reserveToSell, uint256 _ethToRaise) {
        destination = msg.sender;
        token = _token;
        reserveToSell = _reserveToSell;
        ethToRaise = _ethToRaise;
    }

    /// Returns how much tokens should be given out considering ETH raised
    /// @param ethRaised The amount of ETH raised
    /// @return The amount of tokens that should be sold
    function bondingCurveETH(uint256 ethRaised) public view returns (uint256) {
        uint256 percentage = PRECISION - (ethRaised * PRECISION) / ethToRaise;
        return reserveToSell * (PRECISION - (percentage * percentage));
    }

    function priceToMint(uint256 numTokens) public view returns (uint256) {
        return curveIntegral(minted + (numTokens)) - (poolBalance);
    }

    /// @dev                Mint new tokens with ether
    /// @param numTokens    The number of tokens you want to mint
    function mint(uint256 numTokens) public payable {
        uint256 priceForTokens = priceToMint(numTokens);
        require(msg.value >= priceForTokens);

        token.transfer(msg.sender, numTokens);
        minted += numTokens;
        poolBalance = poolBalance + (priceForTokens);

        // refund balance to the users
        if (msg.value > priceForTokens) {
            payable(msg.sender).transfer(msg.value - priceForTokens);
        }

        payable(destination).transfer(priceForTokens);

        emit Minted(numTokens, priceForTokens);
    }

    function setDestination(address _destination) external onlyOwner {
        destination = _destination;
    }

    function refundETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function refundERC20(address _token) external onlyOwner {
        IERC20(_token).transfer(
            msg.sender,
            IERC20(_token).balanceOf(address(this))
        );
    }
}
