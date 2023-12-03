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
    event Burned(uint256 amount, uint256 reward);

    uint256 private constant PRECISION = 10000000000;

    address public destination;
    IERC20 public token;
    uint256 public poolBalance;
    uint256 public minted;
    uint8 public exponent;

    /// @dev constructor    Initializes the bonding curve
    constructor(IERC20 _token, uint8 _exponent) {
        destination = msg.sender;
        exponent = _exponent;
        token = _token;
    }

    /// @dev        Calculate the integral from 0 to t
    /// @param t    The number to integrate to
    function curveIntegral(uint256 t) internal view returns (uint256) {
        uint256 nexp = exponent + 1;
        // Calculate integral of t^exponent
        return ((PRECISION / (nexp)) * (t ** nexp)) / (PRECISION);
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
