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
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IUniswapV2Factory, IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";

interface IERC20Burnable is IERC20 {
    // todo
}

contract StreamedVesting {
    using SafeMath for uint256;

    IERC20 public underlying;
    IERC20Burnable public vestedToken;

    function createVest(uint256 amount) external {
        // todo
    }

    function stakeTo4Year(uint256 amount) external {
        // todo
    }

    function claimVest(uint256 id) external {
        // todo
    }

    function claimVestEarlyWithPenalty(uint256 id) external {
        // todo
    }

    function convertVestTo4YearWithBonus(uint256 id) external {
        // todo
    }

    function vestStatus(
        uint256 id
    )
        external
        view
        returns (
            uint256 totalVest,
            uint256 claimed,
            uint256 claimable,
            uint256 claimableWithPenalty
        )
    {
        // todo
    }

    function vestIds(address who) external view returns (uint256[] memory ids) {
        // todo
    }
}
