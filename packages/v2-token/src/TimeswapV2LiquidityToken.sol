// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

import {ITimeswapV2Pool} from "@timeswap-labs/v2-pool/src/interfaces/ITimeswapV2Pool.sol";

import {PoolFactoryLibrary} from "@timeswap-labs/v2-pool/src/libraries/PoolFactory.sol";
import {ReentrancyGuard} from "@timeswap-labs/v2-pool/src/libraries/ReentrancyGuard.sol";

import {ITimeswapV2LiquidityToken} from "./interfaces/ITimeswapV2LiquidityToken.sol";

import {ITimeswapV2LiquidityTokenMintCallback} from "./interfaces/callbacks/ITimeswapV2LiquidityTokenMintCallback.sol";
import {ITimeswapV2LiquidityTokenBurnCallback} from "./interfaces/callbacks/ITimeswapV2LiquidityTokenBurnCallback.sol";
import {ITimeswapV2LiquidityTokenCollectCallback} from "./interfaces/callbacks/ITimeswapV2LiquidityTokenCollectCallback.sol";

import {ERC1155Enumerable} from "./base/ERC1155Enumerable.sol";

import {TimeswapV2LiquidityTokenPosition, PositionLibrary} from "./structs/Position.sol";
import {FeesPosition, FeesPositionLibrary} from "./structs/FeesPosition.sol";
import {TimeswapV2LiquidityTokenMintParam, TimeswapV2LiquidityTokenBurnParam, TimeswapV2LiquidityTokenCollectParam, ParamLibrary} from "./structs/Param.sol";
import {TimeswapV2LiquidityTokenMintCallbackParam, TimeswapV2LiquidityTokenBurnCallbackParam, TimeswapV2LiquidityTokenCollectCallbackParam} from "./structs/CallbackParam.sol";
import {Error} from "@timeswap-labs/v2-library/src/Error.sol";

/// @title An implementation for TS-V2 liquidity token system
/// @author Timeswap Labs
contract TimeswapV2LiquidityToken is ITimeswapV2LiquidityToken, ERC1155Enumerable {
    using ReentrancyGuard for uint96;

    using PositionLibrary for TimeswapV2LiquidityTokenPosition;
    using FeesPositionLibrary for FeesPosition;

    address public immutable optionFactory;
    address public immutable poolFactory;

    constructor(address chosenOptionFactory, address chosenPoolFactory) ERC1155("Timeswap V2 uint160 address") {
        optionFactory = chosenOptionFactory;
        poolFactory = chosenPoolFactory;
    }

    mapping(bytes32 => uint96) private reentrancyGuards;

    mapping(uint256 => TimeswapV2LiquidityTokenPosition) private _timeswapV2LiquidityTokenPositions;

    mapping(bytes32 => uint256) private _timeswapV2LiquidityTokenPositionIds;

    mapping(uint256 => mapping(address => FeesPosition)) private _feesPositions;

    function changeInteractedIfNecessary(bytes32 key) private {
        if (reentrancyGuards[key] == ReentrancyGuard.NOT_INTERACTED) reentrancyGuards[key] = ReentrancyGuard.NOT_ENTERED;
    }

    /// @dev internal function to start the reentrancy guard
    function raiseGuard(bytes32 key) private {
        reentrancyGuards[key].check();
        reentrancyGuards[key] = ReentrancyGuard.ENTERED;
    }

    /// @dev internal function to end the reentrancy guard
    function lowerGuard(bytes32 key) private {
        reentrancyGuards[key] = ReentrancyGuard.NOT_ENTERED;
    }

    /// @inheritdoc ITimeswapV2LiquidityToken
    function positionOf(address owner, TimeswapV2LiquidityTokenPosition calldata timeswapV2LiquidityTokenPosition) external view returns (uint256 amount) {
        amount = balanceOf(owner, _timeswapV2LiquidityTokenPositionIds[timeswapV2LiquidityTokenPosition.toKey()]);
    }

    /// @inheritdoc ITimeswapV2LiquidityToken
    function transferTokenPositionFrom(address from, address to, TimeswapV2LiquidityTokenPosition calldata timeswapV2LiquidityTokenPosition, uint160 liquidityAmount) external {
        safeTransferFrom(from, to, _timeswapV2LiquidityTokenPositionIds[timeswapV2LiquidityTokenPosition.toKey()], liquidityAmount, bytes(""));
    }

    /// @inheritdoc ITimeswapV2LiquidityToken
    function transferFeesFrom(address from, address to, TimeswapV2LiquidityTokenPosition calldata position, uint256 long0Fees, uint256 long1Fees, uint256 shortFees) external override {
        if (from == address(0)) Error.zeroAddress();
        if (to == address(0)) Error.zeroAddress();

        if (!isApprovedForAll(from, msg.sender)) revert NotApprovedToTransferFees();

        uint256 id = _timeswapV2LiquidityTokenPositionIds[position.toKey()];

        if (long0Fees != 0 || long1Fees != 0 || shortFees != 0) _addTokenEnumeration(from, to, id, 0);

        // add/mint the fees for the new user
        _feesPositions[id][to].mint(long0Fees, long1Fees, shortFees);

        _updateFeesPositions(from, to, id);

        // remove/burn the fees
        _feesPositions[id][from].burn(long0Fees, long1Fees, shortFees);

        if (long0Fees != 0 || long1Fees != 0 || shortFees != 0) _removeTokenEnumeration(from, to, id, 0);

        emit TransferFees(from, to, position, long0Fees, long1Fees, shortFees);
    }

    /// @inheritdoc ITimeswapV2LiquidityToken
    function mint(TimeswapV2LiquidityTokenMintParam calldata param) external returns (bytes memory data) {
        ParamLibrary.check(param);

        TimeswapV2LiquidityTokenPosition memory timeswapV2LiquidityTokenPosition = TimeswapV2LiquidityTokenPosition({
            token0: param.token0,
            token1: param.token1,
            strike: param.strike,
            maturity: param.maturity
        });

        bytes32 key = timeswapV2LiquidityTokenPosition.toKey();
        uint256 id = _timeswapV2LiquidityTokenPositionIds[key];

        // if the position does not exist, create it
        if (id == 0) {
            id = totalSupply() + 1;
            _timeswapV2LiquidityTokenPositions[id] = timeswapV2LiquidityTokenPosition;
            _timeswapV2LiquidityTokenPositionIds[key] = id;
        }

        changeInteractedIfNecessary(key);
        raiseGuard(key);

        (, address poolPair) = PoolFactoryLibrary.getWithCheck(optionFactory, poolFactory, param.token0, param.token1);

        // calculate the amount of liquidity tokens to mint
        uint160 liquidityBalanceTarget = ITimeswapV2Pool(poolPair).liquidityOf(param.strike, param.maturity, address(this)) + param.liquidityAmount;

        // mint the liquidity tokens to the recipient
        _mint(param.to, id, param.liquidityAmount, bytes(""));

        // ask the msg.sender to transfer the liquidity to this contract
        data = ITimeswapV2LiquidityTokenMintCallback(msg.sender).timeswapV2LiquidityTokenMintCallback(
            TimeswapV2LiquidityTokenMintCallbackParam({
                token0: param.token0,
                token1: param.token1,
                strike: param.strike,
                maturity: param.maturity,
                liquidityAmount: param.liquidityAmount,
                data: param.data
            })
        );

        // check if the enough liquidity amount target is received
        Error.checkEnough(ITimeswapV2Pool(poolPair).liquidityOf(param.strike, param.maturity, address(this)), liquidityBalanceTarget);

        // stop the reentrancy guard
        lowerGuard(key);
    }

    /// @inheritdoc ITimeswapV2LiquidityToken
    function burn(TimeswapV2LiquidityTokenBurnParam calldata param) external returns (bytes memory data) {
        ParamLibrary.check(param);

        bytes32 key = TimeswapV2LiquidityTokenPosition({token0: param.token0, token1: param.token1, strike: param.strike, maturity: param.maturity}).toKey();

        raiseGuard(key);

        (, address poolPair) = PoolFactoryLibrary.getWithCheck(optionFactory, poolFactory, param.token0, param.token1);

        // transfer the equivalent liquidity amount to the recipient from pool
        ITimeswapV2Pool(poolPair).transferLiquidity(param.strike, param.maturity, param.to, param.liquidityAmount);

        if (param.data.length != 0)
            data = ITimeswapV2LiquidityTokenBurnCallback(msg.sender).timeswapV2LiquidityTokenBurnCallback(
                TimeswapV2LiquidityTokenBurnCallbackParam({
                    token0: param.token0,
                    token1: param.token1,
                    strike: param.strike,
                    maturity: param.maturity,
                    liquidityAmount: param.liquidityAmount,
                    data: param.data
                })
            );

        // burn the liquidity tokens from the msg.sender
        _burn(msg.sender, _timeswapV2LiquidityTokenPositionIds[key], param.liquidityAmount);

        // stop the guard for reentrancy
        lowerGuard(key);
    }

    /// @inheritdoc ITimeswapV2LiquidityToken
    function collect(TimeswapV2LiquidityTokenCollectParam calldata param) external returns (uint256 long0Fees, uint256 long1Fees, uint256 shortFees, bytes memory data) {
        ParamLibrary.check(param);

        bytes32 key = TimeswapV2LiquidityTokenPosition({token0: param.token0, token1: param.token1, strike: param.strike, maturity: param.maturity}).toKey();

        // start the reentrancy guard
        raiseGuard(key);

        (, address poolPair) = PoolFactoryLibrary.getWithCheck(optionFactory, poolFactory, param.token0, param.token1);

        // transfer the fees amount to the recipient
        ITimeswapV2Pool(poolPair).transferFees(param.strike, param.maturity, param.to, long0Fees, long1Fees, shortFees);

        uint256 id = _timeswapV2LiquidityTokenPositionIds[key];

        _updateFeesPositions(msg.sender, address(0), id);

        (long0Fees, long1Fees, shortFees) = _feesPositions[id][msg.sender].getFees(param.long0FeesDesired, param.long1FeesDesired, param.shortFeesDesired);

        if (param.data.length != 0)
            data = ITimeswapV2LiquidityTokenCollectCallback(msg.sender).timeswapV2LiquidityTokenCollectCallback(
                TimeswapV2LiquidityTokenCollectCallbackParam({
                    token0: param.token0,
                    token1: param.token1,
                    strike: param.strike,
                    maturity: param.maturity,
                    long0Fees: long0Fees,
                    long1Fees: long1Fees,
                    shortFees: shortFees,
                    data: param.data
                })
            );

        // burn the desired fees from the fees position
        _feesPositions[id][msg.sender].burn(long0Fees, long1Fees, shortFees);

        if (long0Fees != 0 || long1Fees != 0 || shortFees != 0) _removeTokenEnumeration(msg.sender, address(0), id, 0);

        // stop the reentrancy guard
        lowerGuard(key);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i; i < ids.length; ) {
            if (amounts[i] != 0) _updateFeesPositions(from, to, ids[i]);

            unchecked {
                ++i;
            }
        }
    }

    function _updateFeesPositions(address from, address to, uint256 id) private {
        if (from != to) {
            TimeswapV2LiquidityTokenPosition memory timeswapV2LiquidityTokenPosition = _timeswapV2LiquidityTokenPositions[id];

            uint256 long0FeeGrowth;
            uint256 long1FeeGrowth;
            uint256 shortFeeGrowth;
            {
                (, address poolPair) = PoolFactoryLibrary.getWithCheck(optionFactory, poolFactory, timeswapV2LiquidityTokenPosition.token0, timeswapV2LiquidityTokenPosition.token1);

                (long0FeeGrowth, long1FeeGrowth, shortFeeGrowth) = ITimeswapV2Pool(poolPair).feeGrowth(timeswapV2LiquidityTokenPosition.strike, timeswapV2LiquidityTokenPosition.maturity);
            }

            if (from != address(0)) _feesPositions[id][from].update(uint160(balanceOf(from, id)), long0FeeGrowth, long1FeeGrowth, shortFeeGrowth);

            if (to != address(0)) _feesPositions[id][to].update(uint160(balanceOf(to, id)), long0FeeGrowth, long1FeeGrowth, shortFeeGrowth);
        }
    }

    function _additionalConditionAddTokenToOwnerEnumeration(address to, uint256 id) internal view override returns (bool) {
        return _additionalConditionForOwnerTokenEnumeration(to, id);
    }

    function _additionalConditionRemoveTokenFromOwnerEnumeration(address from, uint256 id) internal view override returns (bool) {
        return _additionalConditionForOwnerTokenEnumeration(from, id);
    }

    function _additionalConditionForOwnerTokenEnumeration(address owner, uint256 id) private view returns (bool) {
        TimeswapV2LiquidityTokenPosition memory timeswapV2LiquidityTokenPosition = _timeswapV2LiquidityTokenPositions[id];

        uint256 long0FeeGrowth;
        uint256 long1FeeGrowth;
        uint256 shortFeeGrowth;
        {
            (, address poolPair) = PoolFactoryLibrary.getWithCheck(optionFactory, poolFactory, timeswapV2LiquidityTokenPosition.token0, timeswapV2LiquidityTokenPosition.token1);

            (long0FeeGrowth, long1FeeGrowth, shortFeeGrowth) = ITimeswapV2Pool(poolPair).feeGrowth(timeswapV2LiquidityTokenPosition.strike, timeswapV2LiquidityTokenPosition.maturity);
        }

        FeesPosition memory feesPosition = _feesPositions[id][owner];

        (uint256 long0Fees, uint256 long1Fees, uint256 shortFees) = feesPosition.feesEarnedOf(uint160(balanceOf(owner, id)), long0FeeGrowth, long1FeeGrowth, shortFeeGrowth);

        return long0Fees == 0 && long1Fees == 0 && shortFees == 0;
    }
}
