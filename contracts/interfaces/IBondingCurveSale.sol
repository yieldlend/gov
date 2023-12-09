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

    /// @notice The vested token that will be distributed
    function token() external view returns (IERC20);

    /// @notice Where to send the ETH raised
    function destination() external view returns (address);

    /// @notice How much tokens need to be sold
    function reserveToSell() external view returns (uint256);

    /// @notice How much tokens will be in LP
    function reserveInLP() external view returns (uint256);

    /// @notice How much ETH needs to be raised
    function ethToRaise() external view returns (uint256);

    /// @notice How much ETH has been raised
    function ethRaised() external view returns (uint256);

    /// @notice How much tokens have been sold
    function reserveSold() external view returns (uint256);

    /// @notice Returns how much tokens should be given out considering ETH raised
    /// @param ethRaised The amount of ETH raised
    /// @return The amount of tokens that should be sold
    function bondingCurveETH(uint256 ethRaised) external view returns (uint256);

    /// @notice Participate in the bonding curve sale with ETH
    function mint() external payable;

    /// @notice Participate in the bonding curve sale with ETH and a referral code
    function mintWithReferral(uint256 code) external payable;

    /// @notice Claims the referral rewards for a user that has earned referral rewards
    function claimReferralRewards() external;

    function referralCode(address who) external view returns (uint256);

    function setDestination(address _destination) external;

    function withdrawStuckTokens(address tkn) external;
}
