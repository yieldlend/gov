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
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IAggregatorV3Interface} from "./interfaces/IAggregatorV3Interface.sol";
import {IBondingCurveSale} from "./interfaces/IBondingCurveSale.sol";

/// @title  A bonding curve sale that is accepts ether for YIELD tokens.
contract BondingCurveSale is
    IBondingCurveSale,
    Ownable,
    ReentrancyGuard,
    IAggregatorV3Interface
{
    uint256 private constant PRECISION = 1e18;

    /// @inheritdoc IBondingCurveSale
    address public destination;

    IAggregatorV3Interface public immutable ethUsdPrice;

    /// @inheritdoc IBondingCurveSale
    IERC20 public immutable token;

    /// @inheritdoc IBondingCurveSale
    uint256 public immutable ethToRaise;

    /// @inheritdoc IBondingCurveSale
    uint256 public immutable reserveInLP;

    /// @inheritdoc IBondingCurveSale
    uint256 public immutable reserveToSell;

    mapping(uint256 => uint256) public referralEarnings;

    mapping(address => uint256) public ethContributed;

    /// @inheritdoc IBondingCurveSale
    uint256 public ethRaised;

    /// @inheritdoc IBondingCurveSale
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
            1e26;

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
        _mint(msg.sender, (0));
    }

    /// @inheritdoc IBondingCurveSale
    function mintWithReferral(uint256 code) external payable {
        _mint(msg.sender, code);
    }

    /// @inheritdoc IBondingCurveSale
    function setDestination(address _destination) external onlyOwner {
        destination = _destination;
    }

    /// @inheritdoc IBondingCurveSale
    function referralCode(address who) external pure returns (uint256) {
        return _referralCode(who);
    }

    /// @inheritdoc IBondingCurveSale
    function claimReferralRewards() external nonReentrant {
        uint256 code = _referralCode(msg.sender);
        uint256 earnings = referralEarnings[code];
        require(earnings > 0, "no earnings");
        referralEarnings[code] = 0;
        payable(msg.sender).transfer(earnings);
        emit ReferralRewardClaimed(code, msg.sender, earnings);
    }

    /// @inheritdoc IBondingCurveSale
    function withdrawStuckTokens(address tkn) external onlyOwner {
        bool success;
        if (tkn == address(0))
            (success, ) = address(msg.sender).call{
                value: address(this).balance
            }("");
        else {
            require(IERC20(tkn).balanceOf(address(this)) > 0, "no tokens");
            uint256 amount = IERC20(tkn).balanceOf(address(this));
            IERC20(tkn).transfer(msg.sender, amount);
        }
    }

    function _mint(address who, uint256 code) internal nonReentrant {
        // calculate tokens sold baesd on the ETH raised
        ethRaised += msg.value;
        uint256 newTokensSold = bondingCurveETH(ethRaised);
        uint256 reserveSoldToBuyer = newTokensSold - reserveSold;
        reserveSold = newTokensSold;

        // track eth contributed for discord roles
        ethContributed[who] += msg.value;

        // send 3/5th to LP
        destination.call{value: (msg.value * 3) / 5}("");

        // send 2/5th to the admin (and referral if it exists)
        if (code == 0) {
            // send 2/5th to admin
            owner().call{value: (msg.value * 2) / 5}("");
        } else {
            // send 1.5/5th to admin and keep 0.5/5th to the referrer
            owner().call{value: (msg.value * 3) / 10}("");
            referralEarnings[code] += (msg.value) / 10;
        }

        // give the user the tokens that were sold
        token.transfer(who, reserveSoldToBuyer);

        emit Minted(who, code, reserveSoldToBuyer, msg.value);
    }

    function _referralCode(address who) internal pure returns (uint256) {
        // calculate tokens sold baesd on the ETH raised
        uint256 code = uint256(uint160(who));
        return (code) & 0xffffffffffff;
    }
}
