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

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockAggregator is Ownable {
    int256 public latestAnswer;

    constructor(int256 _answer) {
        latestAnswer = _answer;
    }

    function setAnswer(int256 _answer) external onlyOwner {
        latestAnswer = _answer;
    }

    function decimals() external pure returns (uint8) {
        return 8;
    }
}
