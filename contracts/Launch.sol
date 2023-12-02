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

import {ERC20Burnable, IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IUniswapV2Factory, IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";

// This is the launch contract that kick starts the protocol.

contract Launch is Ownable {
    using SafeMath for uint256;

    function prepare() external onlyOwner {
        // todo
    }

    function launch() external {
        // todo
    }

    function earlyLaunch() external onlyOwner {
        // todo
    }
}
