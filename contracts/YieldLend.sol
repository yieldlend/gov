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

contract YieldLend is ERC20Burnable, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public uniswapV2Pair;
    address public marketingWallet;
    address public constant deadAddress = address(0xdead);

    bool public tradingActive;
    bool public swapEnabled;
    bool private _swapping;

    uint256 public maxTransaction;
    uint256 public maxWallet;
    uint256 public swapTokensAtAmount;

    uint256 public buyTotalFees;
    uint256 private _buyMarketingFee;

    uint256 public sellTotalFees;
    uint256 private _sellMarketingFee;

    uint256 private _tokensForMarketing;
    uint256 private _previousFee;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromMaxTransaction;
    mapping(address => bool) private _automatedMarketMakerPairs;

    event ExcludeFromLimits(address indexed account, bool isExcluded);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event MarketingWalletUpdated(address indexed n, address indexed o);

    constructor() ERC20("YieldLend", "YIELD") {
        uint256 supply = 100_000_000_000 ether;
        address admin = 0x3f927868aAdb217ed137e87c44c83e4A3EB7f70B;
        uniswapV2Router = IUniswapV2Router02(
            0x6BDED42c6DA8FBf0d2bA55B2fa120C5e0c8D7891
        );
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        maxTransaction = supply;
        maxWallet = supply;
        swapTokensAtAmount = (supply * 1) / 1000;

        _buyMarketingFee = 100;
        buyTotalFees = _buyMarketingFee;

        _sellMarketingFee = 500;
        sellTotalFees = _sellMarketingFee;

        _previousFee = sellTotalFees;
        marketingWallet = admin;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(deadAddress, true);
        excludeFromFees(admin, true);

        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        excludeFromMaxTransaction(deadAddress, true);
        excludeFromMaxTransaction(address(uniswapV2Router), true);
        excludeFromMaxTransaction(admin, true);

        _mint(owner(), supply);
    }

    receive() external payable {}

    function yearn() public onlyOwner {
        require(!tradingActive, "Trading already active.");

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );
        _approve(address(this), address(uniswapV2Pair), type(uint256).max);
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
        excludeFromMaxTransaction(address(uniswapV2Pair), true);

        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
    }

    function faceOfBase() public onlyOwner {
        require(!tradingActive, "Trading already active.");
        tradingActive = true;
        swapEnabled = true;
    }

    function setSwapEnabled(bool value) public onlyOwner {
        swapEnabled = value;
    }

    function setSwapTokensAtAmount(uint256 amount) public onlyOwner {
        require(
            amount >= (totalSupply() * 1) / 100000,
            "ERC20: Swap amount cannot be lower than 0.001% total supply."
        );
        require(
            amount <= (totalSupply() * 5) / 1000,
            "ERC20: Swap amount cannot be higher than 0.5% total supply."
        );
        swapTokensAtAmount = amount;
    }

    function setMaxWalletAndMaxTransaction(
        uint256 _maxTransaction,
        uint256 _maxWallet
    ) public onlyOwner {
        require(
            _maxTransaction >= ((totalSupply() * 5) / 1000),
            "ERC20: Cannot set maxTxn lower than 0.5%"
        );
        require(
            _maxWallet >= ((totalSupply() * 5) / 1000),
            "ERC20: Cannot set maxWallet lower than 0.5%"
        );
        maxTransaction = _maxTransaction;
        maxWallet = _maxWallet;
    }

    function setBuyFees(uint256 _marketingFee) public onlyOwner {
        require(_marketingFee <= 1000, "ERC20: Must keep fees at 10% or less");
        _buyMarketingFee = _marketingFee;
        buyTotalFees = _buyMarketingFee;
    }

    function setSellFees(uint256 _marketingFee) public onlyOwner {
        require(_marketingFee <= 1000, "ERC20: Must keep fees at 3% or less");
        _sellMarketingFee = _marketingFee;
        sellTotalFees = _sellMarketingFee;
        _previousFee = sellTotalFees;
    }

    function setMarketingWallet(address _marketingWallet) public onlyOwner {
        require(_marketingWallet != address(0), "ERC20: Address 0");
        address oldWallet = marketingWallet;
        marketingWallet = _marketingWallet;
        emit MarketingWalletUpdated(marketingWallet, oldWallet);
    }

    function excludeFromMaxTransaction(
        address account,
        bool value
    ) public onlyOwner {
        _isExcludedFromMaxTransaction[account] = value;
        emit ExcludeFromLimits(account, value);
    }

    function bulkExcludeFromMaxTransaction(
        address[] calldata accounts,
        bool value
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromMaxTransaction[accounts[i]] = value;
            emit ExcludeFromLimits(accounts[i], value);
        }
    }

    function excludeFromFees(address account, bool value) public onlyOwner {
        _isExcludedFromFees[account] = value;
        emit ExcludeFromFees(account, value);
    }

    function bulkExcludeFromFees(
        address[] calldata accounts,
        bool value
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = value;
            emit ExcludeFromFees(accounts[i], value);
        }
    }

    function withdrawStuckTokens(address tkn) public onlyOwner {
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

    function isExcludedFromMaxTransaction(
        address account
    ) public view returns (bool) {
        return _isExcludedFromMaxTransaction[account];
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) internal {
        _automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != deadAddress &&
            !_swapping
        ) {
            if (!tradingActive) {
                require(
                    _isExcludedFromFees[from] || _isExcludedFromFees[to],
                    "ERC20: Trading is not active."
                );
            }

            // when buy
            if (
                _automatedMarketMakerPairs[from] &&
                !_isExcludedFromMaxTransaction[to]
            ) {
                require(
                    amount <= maxTransaction,
                    "ERC20: Buy transfer amount exceeds the maxTransaction."
                );
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "ERC20: Max wallet exceeded"
                );
            }
            // when sell
            else if (
                _automatedMarketMakerPairs[to] &&
                !_isExcludedFromMaxTransaction[from]
            ) {
                require(
                    amount <= maxTransaction,
                    "ERC20: Sell transfer amount exceeds the maxTransaction."
                );
            } else if (!_isExcludedFromMaxTransaction[to]) {
                require(
                    amount + balanceOf(to) <= maxWallet,
                    "ERC20: Max wallet exceeded"
                );
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if (
            canSwap &&
            swapEnabled &&
            !_swapping &&
            !_automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            _swapping = true;
            _swapBack();
            _swapping = false;
        }

        bool takeFee = !_swapping;

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        uint256 fees = 0;

        if (takeFee) {
            // on sell
            if (_automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(10000);
                _tokensForMarketing +=
                    (fees * _sellMarketingFee) /
                    sellTotalFees;
            }
            // on buy
            else if (_automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                fees = amount.mul(buyTotalFees).div(10000);
                _tokensForMarketing += (fees * _buyMarketingFee) / buyTotalFees;
            }

            if (fees > 0) {
                super._transfer(from, address(this), fees);
            }

            amount -= fees;
        }

        super._transfer(from, to, amount);
        sellTotalFees = _previousFee;
    }

    function _swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _swapBack() internal {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = _tokensForMarketing;
        bool success;

        if (contractBalance == 0 || totalTokensToSwap == 0) {
            return;
        }

        if (contractBalance > swapTokensAtAmount * 10) {
            contractBalance = swapTokensAtAmount * 10;
        }

        _swapTokensForETH(contractBalance);
        _tokensForMarketing = 0;

        uint256 ethBalance = address(this).balance;
        (success, ) = address(marketingWallet).call{value: ethBalance}("");
    }
}
