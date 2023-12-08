// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IBondingCurveSale {
    event Minted(
        address indexed who,
        uint256 referralCode,
        uint256 tokens,
        uint256 eth
    );

    event ReferralRewardClaimed(uint256 referralCode, address to, uint256 eth);

    function token() external returns (IERC20);

    function destination() external returns (address);

    function reserveToSell() external returns (uint256);

    function ethToRaise() external returns (uint256);

    function ethRaised() external returns (uint256);

    function reserveSold() external returns (uint256);

    /// Returns how much tokens should be given out considering ETH raised
    /// @param ethRaised The amount of ETH raised
    /// @return The amount of tokens that should be sold
    function bondingCurveETH(uint256 ethRaised) external view returns (uint256);

    function mint() external payable;

    function mintWithReferral(uint256 code) external payable;

    function claimReferralRewards() external;

    function referralCode(address who) external view returns (uint256);

    function setDestination(address _destination) external;

    function withdrawStuckTokens(address tkn) external;
}
