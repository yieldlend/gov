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

import {ERC20Burnable, IERC20, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

import {IUniswapV2Factory, IUniswapV2Router02} from "./interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Pair} from "./interfaces/IUniswapV2Pair.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IYieldLend} from "./interfaces/IYieldLend.sol";

contract YieldLend is IYieldLend, ERC20Burnable, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable uniswapV2Router;
    IWETH public immutable weth;

    address public uniswapV2Pair;
    address public marketingWallet;
    address public constant deadAddress = address(0xdead);

    bool public tradingActive;
    bool public swapEnabled;
    bool private _swapping;

    uint256 public swapTokensAtAmount;

    uint256 public sellTotalFees;
    uint256 private _sellMarketingFee;
    uint256 private _sellBurnFee;
    uint256 private _sellLiquidityFee;

    uint256 private _tokensForMarketing;
    uint256 private _tokensForBurn;
    uint256 private _tokensForLiquidity;
    uint256 private _previousFee;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _automatedMarketMakerPairs;

    constructor() ERC20("YieldLend", "YIELD") {
        uint256 supply = 100_000_000_000 ether;
        address admin = 0x3f927868aAdb217ed137e87c44c83e4A3EB7f70B;
        uniswapV2Router = IUniswapV2Router02(
            0x6BDED42c6DA8FBf0d2bA55B2fa120C5e0c8D7891
        );

        weth = IWETH(0x4200000000000000000000000000000000000006);
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        swapTokensAtAmount = (supply * 1) / 1000;

        _sellMarketingFee = 300; // 3% marketing
        _sellBurnFee = 100; // 1% burn
        _sellLiquidityFee = 100; // 1% liquidity
        sellTotalFees = _sellMarketingFee + _sellBurnFee + _sellLiquidityFee;

        _previousFee = sellTotalFees;
        marketingWallet = admin;

        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0), true);
        excludeFromFees(deadAddress, true);
        excludeFromFees(admin, true);

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
        _approve(address(this), address(uniswapV2Router), type(uint256).max);

        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );

        _setAutomatedMarketMakerPair(address(uniswapV2Pair), true);
    }

    function yearnAgain() public onlyOwner {
        require(!tradingActive, "Trading already active.");
        _addLiquidity(balanceOf(address(this)), address(this).balance);
    }

    function yearnAgainAgain() public onlyOwner {
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

    function setSellFees(
        uint256 _marketingFee,
        uint256 _burnFee,
        uint256 _liquidityFee
    ) public onlyOwner {
        require(
            _marketingFee + _burnFee + _liquidityFee <= 1000,
            "ERC20: Must keep fees at 10% or less"
        );
        _sellMarketingFee = _marketingFee;
        _sellBurnFee = _burnFee;
        _sellLiquidityFee = _liquidityFee;
        sellTotalFees = _sellMarketingFee + _sellBurnFee + _sellLiquidityFee;
        _previousFee = sellTotalFees;
    }

    function setMarketingWallet(address _marketingWallet) public onlyOwner {
        require(_marketingWallet != address(0), "ERC20: Address 0");
        address oldWallet = marketingWallet;
        marketingWallet = _marketingWallet;
        emit MarketingWalletUpdated(marketingWallet, oldWallet);
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

        if (_isExcludedFromFees[from] || _isExcludedFromFees[to])
            takeFee = false;

        uint256 fees = 0;

        if (takeFee) {
            // on sell
            if (_automatedMarketMakerPairs[to] && sellTotalFees > 0) {
                fees = amount.mul(sellTotalFees).div(10000);
                _tokensForLiquidity +=
                    (fees * _sellLiquidityFee) /
                    sellTotalFees;
                _tokensForMarketing +=
                    (fees * _sellMarketingFee) /
                    sellTotalFees;
                _tokensForBurn += (fees * _sellBurnFee) / sellTotalFees;
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

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    /**
     * Swapback function which converts the taxes into LP, marketing funds and burns
     */
    function _swapBack() internal {
        uint256 contractBalance = balanceOf(address(this));

        // burn tokens
        _transfer(address(this), deadAddress, _tokensForBurn);
        _tokensForBurn = 0;

        uint256 tokensToSwap = _tokensForLiquidity + _tokensForMarketing;
        bool success;

        if (contractBalance == 0 || tokensToSwap == 0) return;
        if (contractBalance > swapTokensAtAmount * 10) {
            contractBalance = swapTokensAtAmount * 10;
        }

        uint256 lpBalance = (contractBalance * _tokensForLiquidity) /
            tokensToSwap /
            2;

        uint256 swapForETH = contractBalance.sub(lpBalance);
        uint256 initialETHBalance = address(this).balance;

        _swapTokensForETH(swapForETH);

        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(_tokensForMarketing).div(
            tokensToSwap
        );

        uint256 ethForLP = ethBalance - ethForMarketing;

        _tokensForLiquidity = 0;
        _tokensForMarketing = 0;

        if (lpBalance > 0 && ethForLP > 0) {
            _addLiquidity(lpBalance, ethForLP);
            emit SwapAndLiquify(swapForETH, ethForLP, _tokensForLiquidity);
        }

        (success, ) = address(marketingWallet).call{
            value: address(this).balance
        }("");
    }

    /**
     * Special function to manually add liquidity to the pair in case someone
     * tries to brick the pair by sending small amounts of ETH to the pair before
     * initial liq is added
     */
    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        // send eth and tokens to the pair
        weth.deposit{value: ethAmount}();
        assert(weth.transfer(uniswapV2Pair, weth.balanceOf(address(this))));
        _transfer(address(this), uniswapV2Pair, tokenAmount);

        // sync liquidity and burn
        IUniswapV2Pair(uniswapV2Pair).mint(deadAddress);
    }
}
