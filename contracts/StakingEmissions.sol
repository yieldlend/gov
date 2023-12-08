// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IFeeDistributor} from "./interfaces/IFeeDistributor.sol";
import {IYieldLocker} from "./interfaces/IYieldLocker.sol";
import {Epoch} from "./Epoch.sol";

contract StakingEmissions is Initializable, Pausable, Epoch, Ownable {
    IFeeDistributor public feeDistributor;
    IERC20 public token;
    uint256 public amtPerEpoch;

    function initialize(
        IFeeDistributor _feeDistributor,
        IERC20 _token,
        uint256 _amtPerEpoch
    ) external initializer {
        token = _token;
        feeDistributor = _feeDistributor;
        amtPerEpoch = _amtPerEpoch;

        _pause();
    }

    function start() external onlyOwner {
        initEpoch(86400 * 7, block.timestamp);
        _unpause();
        renounceOwnership();
    }

    function distribute() external {
        _distribute();
    }

    function _distribute() internal checkEpoch whenPaused {
        token.transfer(address(feeDistributor), amtPerEpoch);
        feeDistributor.checkpointTotalSupply();
        feeDistributor.checkpointToken();
    }
}
