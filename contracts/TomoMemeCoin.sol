// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {ERC20} from "./ERC20.sol";
import {ITomoMemeCoinFactory} from "./interfaces/ITomoMemeCoinFactory.sol";
import {ITomoMemeCoinManager} from "./interfaces/ITomoMemeCoinManager.sol";
import {INonfungiblePositionManager} from "./interfaces/INonfungiblePositionManager.sol";
import {DataTypes} from "./libraries/DataTypes.sol";
import {LibCaculatePair} from "./libraries/LibCaculatePair.sol";

contract TomoMemeCoin is ERC20 {
    error InvaildParam();
    error ReachMaxPerMint();
    error SoldOut();
    error ExceedPresaleDeadline();
    error PresaleNotFinshed();
    error SendETHFailed();
    error TradingNotEnable();

    address public tomoMemeCoinManager;
    uint256 public mintPrice;
    uint256 public maxPerWallet;
    uint256 public preSaleDeadLine;
    uint256 public preSaleAmountLeft;
    address public creator;
    bool public enableTrading;

    mapping(address => uint) private mintAccount;

    function initialized(
        DataTypes.CreateTomoMemeCoinParameters memory vars
    ) internal {
        creator = vars.creator;
        mintPrice = vars.price;
        maxPerWallet = vars.maxPerWallet;
        preSaleDeadLine = vars.preSaleDeadLine;
        init(vars.name, vars.symbol);

        if (vars.reserved > 0) {
            _mint(creator, vars.reserved);
        }
        _mint(tomoMemeCoinManager, vars.totalSupply - vars.reserved);
        preSaleAmountLeft = vars.totalSupply / 2 - vars.reserved;
    }

    constructor() payable {
        tomoMemeCoinManager = ITomoMemeCoinFactory(msg.sender)
            ._tomoMemeCoinManager();

        DataTypes.CreateTomoMemeCoinParameters
            memory vars = ITomoMemeCoinFactory(msg.sender).parameters();

        initialized(vars);

        (, address v3NonfungiblePositionManagerAddress) = ITomoMemeCoinManager(
            tomoMemeCoinManager
        ).getSwapRouter();

        _approve(
            tomoMemeCoinManager,
            v3NonfungiblePositionManagerAddress,
            type(uint256).max
        );
    }

    function mint(uint256 mintAmount_) public payable virtual returns (bool) {
        if (preSaleAmountLeft == 0) {
            revert SoldOut();
        }
        if (block.timestamp > preSaleDeadLine) {
            revert ExceedPresaleDeadline();
        }

        if (mintAmount_ > preSaleAmountLeft) {
            mintAmount_ = preSaleAmountLeft;
        }

        uint256 price = (mintPrice * mintAmount_) / 10 ** decimals();
        if (mintAmount_ == 0 || msg.value < price) {
            revert InvaildParam();
        }
        if (mintAccount[msg.sender] + mintAmount_ > maxPerWallet) {
            revert ReachMaxPerMint();
        }
        mintAccount[msg.sender] += mintAmount_;

        preSaleAmountLeft -= mintAmount_;

        _transfer(tomoMemeCoinManager, msg.sender, mintAmount_);

        //refund if pay more
        if (msg.value > price) {
            (bool success, ) = payable(msg.sender).call{
                value: msg.value - price
            }("");
            if (!success) {
                revert SendETHFailed();
            }
        }

        //add liquidity to uniswap pool
        if (preSaleAmountLeft == 0) {
            //after sold out, open trading
            enableTrading = true;
            //add liquidity using eth and left token
            ITomoMemeCoinManager(tomoMemeCoinManager)
                .addLiquidityForTomoMemeCoin{value: address(this).balance}(
                address(this),
                balanceOf(tomoMemeCoinManager)
            );
        }

        return true;
    }

    function refundIfPresaleFailed(
        uint256 refundErc20Amount
    ) public virtual returns (bool) {
        if (preSaleAmountLeft > 0 && block.timestamp > preSaleDeadLine) {
            if (refundErc20Amount == 0) {
                revert InvaildParam();
            }
            uint256 refundValue = refundErc20Amount * mintPrice;
            _transfer(msg.sender, address(0), refundErc20Amount);
            (bool success, ) = payable(msg.sender).call{value: refundValue}("");
            if (!success) {
                revert SendETHFailed();
            }
        } else {
            revert PresaleNotFinshed();
        }
        return true;
    }

    /**************Only Call By Factory Function **********/
    function transfer(
        address to,
        uint256 value
    ) public virtual override returns (bool) {
        if (!enableTrading) {
            revert TradingNotEnable();
        }
        return super.transfer(to, value);
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public virtual override returns (bool) {
        if (!enableTrading) {
            revert TradingNotEnable();
        }
        return super.transferFrom(from, to, value);
    }
}
