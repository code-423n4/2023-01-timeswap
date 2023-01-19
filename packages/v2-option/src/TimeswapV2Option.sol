//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {Math} from "@timeswap-labs/v2-library/src/Math.sol";
import {Error} from "@timeswap-labs/v2-library/src/Error.sol";

import {NoDelegateCall} from "./NoDelegateCall.sol";

import {ITimeswapV2Option} from "./interfaces/ITimeswapV2Option.sol";
import {ITimeswapV2OptionDeployer} from "./interfaces/ITimeswapV2OptionDeployer.sol";
import {ITimeswapV2OptionMintCallback} from "./interfaces/callbacks/ITimeswapV2OptionMintCallback.sol";
import {ITimeswapV2OptionBurnCallback} from "./interfaces/callbacks/ITimeswapV2OptionBurnCallback.sol";
import {ITimeswapV2OptionSwapCallback} from "./interfaces/callbacks/ITimeswapV2OptionSwapCallback.sol";
import {ITimeswapV2OptionCollectCallback} from "./interfaces/callbacks/ITimeswapV2OptionCollectCallback.sol";

import {Option, OptionLibrary} from "./structs/Option.sol";
import {Process, ProcessLibrary} from "./structs/Process.sol";
import {StrikeAndMaturity} from "./structs/StrikeAndMaturity.sol";

import {TimeswapV2OptionPosition, PositionLibrary} from "./enums/Position.sol";
import {TimeswapV2OptionMint, TimeswapV2OptionBurn, TimeswapV2OptionSwap, TimeswapV2OptionCollect, TransactionLibrary} from "./enums/Transaction.sol";

import {TimeswapV2OptionMintParam, TimeswapV2OptionBurnParam, TimeswapV2OptionSwapParam, TimeswapV2OptionCollectParam, ParamLibrary} from "./structs/Param.sol";
import {TimeswapV2OptionMintCallbackParam, TimeswapV2OptionBurnCallbackParam, TimeswapV2OptionSwapCallbackParam, TimeswapV2OptionCollectCallbackParam} from "./structs/CallbackParam.sol";

/// @title Timeswap V2 Options for a given pair
/// @author Timeswap Labs
/// @notice Holds the option of all strikes and maturies.
contract TimeswapV2Option is ITimeswapV2Option, NoDelegateCall {
    using OptionLibrary for Option;
    using ProcessLibrary for Process[];
    using Math for uint256;
    using SafeERC20 for IERC20;

    /* ===== MODEL ===== */

    /// @inheritdoc ITimeswapV2Option
    address public immutable override optionFactory;
    /// @inheritdoc ITimeswapV2Option
    address public immutable override token0;
    /// @inheritdoc ITimeswapV2Option
    address public immutable override token1;

    /// @dev mapping of all option state for all strikes and maturies.
    mapping(uint256 => mapping(uint256 => Option)) private options;
    /// @dev Always start and end as an empty array for every transaction.
    /// Process the token requirement for every option interaction call.
    Process[] private processing;

    mapping(uint256 => mapping(uint256 => bool)) private hasInteracted;
    StrikeAndMaturity[] private listOfOptions;

    function addOptionEnumerationIfNecessary(uint256 strike, uint256 maturity) private {
        if (!hasInteracted[strike][maturity]) {
            hasInteracted[strike][maturity] = true;
            listOfOptions.push(StrikeAndMaturity({strike: strike, maturity: maturity}));
        }
    }

    /* ===== INIT ===== */

    constructor() NoDelegateCall() {
        (optionFactory, token0, token1) = ITimeswapV2OptionDeployer(msg.sender).parameter();
    }

    // Can be overidden for testing purposes.
    function blockTimestamp() internal view virtual returns (uint96) {
        return uint96(block.timestamp); // truncation is desired
    }

    /* ===== VIEW ===== */

    function getByIndex(uint256 id) external view override returns (StrikeAndMaturity memory) {
        return listOfOptions[id];
    }

    function numberOfOptions() external view override returns (uint256) {
        return listOfOptions.length;
    }

    /// @inheritdoc ITimeswapV2Option
    function totalPosition(uint256 strike, uint256 maturity, TimeswapV2OptionPosition position) external view override returns (uint256) {
        return options[strike][maturity].totalPosition(strike, position);
    }

    /// @inheritdoc ITimeswapV2Option
    function positionOf(uint256 strike, uint256 maturity, address owner, TimeswapV2OptionPosition position) external view override returns (uint256) {
        return options[strike][maturity].positionOf(owner, position);
    }

    /* ===== UPDATE ===== */

    /// @inheritdoc ITimeswapV2Option
    function transferPosition(uint256 strike, uint256 maturity, address to, TimeswapV2OptionPosition position, uint256 amount) external override {
        if (!hasInteracted[strike][maturity]) Error.inactiveOptionChoice(strike, maturity);
        if (to == address(0)) Error.zeroAddress();
        if (amount == 0) Error.zeroInput();
        PositionLibrary.check(position);

        options[strike][maturity].transferPosition(to, position, amount);

        emit TransferPosition(strike, maturity, msg.sender, to, position, amount);
    }

    /// @inheritdoc ITimeswapV2Option
    function mint(
        TimeswapV2OptionMintParam calldata param
    ) external override noDelegateCall returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, uint256 shortAmount, bytes memory data) {
        ParamLibrary.check(param, blockTimestamp());
        addOptionEnumerationIfNecessary(param.strike, param.maturity);

        Option storage option = options[param.strike][param.maturity];

        // does main mint logic calculation
        (token0AndLong0Amount, token1AndLong1Amount, shortAmount) = option.mint(param.strike, param.long0To, param.long1To, param.shortTo, param.transaction, param.amount0, param.amount1);

        // update token0 and token1 balance target for any previous concurrent option transactions.
        processing.updateProcess(token0AndLong0Amount, token1AndLong1Amount, true, true);

        // add a new process
        // stores the token0 and token1 balance target required from the msg.sender to achieve.
        Process storage currentProcess = (processing.push() = Process(
            param.strike,
            param.maturity,
            IERC20(token0).balanceOf(address(this)) + token0AndLong0Amount,
            IERC20(token1).balanceOf(address(this)) + token1AndLong1Amount
        ));

        // ask the msg.sender to transfer token0 and/or token1 to this contract.
        data = ITimeswapV2OptionMintCallback(msg.sender).timeswapV2OptionMintCallback(
            TimeswapV2OptionMintCallbackParam({
                strike: param.strike,
                maturity: param.maturity,
                token0AndLong0Amount: token0AndLong0Amount,
                token1AndLong1Amount: token1AndLong1Amount,
                shortAmount: shortAmount,
                data: param.data
            })
        );

        // check if the token0 balance target is achieved.
        if (token0AndLong0Amount != 0) Error.checkEnough(IERC20(token0).balanceOf(address(this)), currentProcess.balance0Target);

        // check if the token1 balance target is achieved.
        if (token1AndLong1Amount != 0) Error.checkEnough(IERC20(token1).balanceOf(address(this)), currentProcess.balance1Target);

        // finish the process.
        processing.pop();

        emit Mint(param.strike, param.maturity, msg.sender, param.long0To, param.long1To, param.shortTo, token0AndLong0Amount, token1AndLong1Amount, shortAmount);
    }

    /// @inheritdoc ITimeswapV2Option
    function burn(
        TimeswapV2OptionBurnParam calldata param
    ) external override noDelegateCall returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, uint256 shortAmount, bytes memory data) {
        if (!hasInteracted[param.strike][param.maturity]) Error.inactiveOptionChoice(param.strike, param.maturity);
        ParamLibrary.check(param, blockTimestamp());

        Option storage option = options[param.strike][param.maturity];

        // does main burn logic calculation
        (token0AndLong0Amount, token1AndLong1Amount, shortAmount) = option.burn(param.strike, param.transaction, param.amount0, param.amount1);

        // update token0 and token1 balance target for any previous concurrent option transactions.
        processing.updateProcess(token0AndLong0Amount, token1AndLong1Amount, false, false);

        // transfer token0 amount to recipient.
        if (token0AndLong0Amount != 0) IERC20(token0).safeTransfer(param.token0To, token0AndLong0Amount);

        // transfer token1 amount to recipient.
        if (token1AndLong1Amount != 0) IERC20(token1).safeTransfer(param.token1To, token1AndLong1Amount);

        // skip callback if there is no data.
        if (param.data.length != 0)
            data = ITimeswapV2OptionBurnCallback(msg.sender).timeswapV2OptionBurnCallback(
                TimeswapV2OptionBurnCallbackParam({
                    strike: param.strike,
                    maturity: param.maturity,
                    token0AndLong0Amount: token0AndLong0Amount,
                    token1AndLong1Amount: token1AndLong1Amount,
                    shortAmount: shortAmount,
                    data: param.data
                })
            );

        option.long0[msg.sender] -= token0AndLong0Amount;
        option.long1[msg.sender] -= token1AndLong1Amount;
        option.short[msg.sender] -= shortAmount;

        emit Burn(param.strike, param.maturity, msg.sender, param.token0To, param.token1To, token0AndLong0Amount, token1AndLong1Amount, shortAmount);
    }

    /// @inheritdoc ITimeswapV2Option
    function swap(TimeswapV2OptionSwapParam calldata param) external override noDelegateCall returns (uint256 token0AndLong0Amount, uint256 token1AndLong1Amount, bytes memory data) {
        if (!hasInteracted[param.strike][param.maturity]) Error.inactiveOptionChoice(param.strike, param.maturity);
        ParamLibrary.check(param, blockTimestamp());

        Option storage option = options[param.strike][param.maturity];

        // does main swap logic calculation
        (token0AndLong0Amount, token1AndLong1Amount) = option.swap(param.strike, param.longTo, param.isLong0ToLong1, param.transaction, param.amount);

        // update token0 and token1 balance target for any previous concurrent option transactions.
        processing.updateProcess(token0AndLong0Amount, token1AndLong1Amount, !param.isLong0ToLong1, param.isLong0ToLong1);

        // add a new process
        // stores the token0 and token1 balance target required from the msg.sender to achieve.
        Process storage currentProcess = (processing.push() = Process(
            param.strike,
            param.maturity,
            param.isLong0ToLong1 ? IERC20(token0).balanceOf(address(this)) - token0AndLong0Amount : IERC20(token0).balanceOf(address(this)) + token0AndLong0Amount,
            param.isLong0ToLong1 ? IERC20(token1).balanceOf(address(this)) + token1AndLong1Amount : IERC20(token1).balanceOf(address(this)) - token1AndLong1Amount
        ));

        // transfer token to recipient.
        IERC20(param.isLong0ToLong1 ? token0 : token1).safeTransfer(param.tokenTo, param.isLong0ToLong1 ? token0AndLong0Amount : token1AndLong1Amount);

        // ask the msg.sender to transfer token0 or token1 to this contract.
        data = ITimeswapV2OptionSwapCallback(msg.sender).timeswapV2OptionSwapCallback(
            TimeswapV2OptionSwapCallbackParam({
                strike: param.strike,
                maturity: param.maturity,
                isLong0ToLong1: param.isLong0ToLong1,
                token0AndLong0Amount: token0AndLong0Amount,
                token1AndLong1Amount: token1AndLong1Amount,
                data: param.data
            })
        );

        // check if the token0 or token1 balance target is achieved.
        Error.checkEnough(IERC20(param.isLong0ToLong1 ? token1 : token0).balanceOf(address(this)), param.isLong0ToLong1 ? currentProcess.balance1Target : currentProcess.balance0Target);

        if (param.isLong0ToLong1) option.long0[msg.sender] -= token0AndLong0Amount;
        else option.long1[msg.sender] -= token1AndLong1Amount;

        // finish the process.
        processing.pop();

        emit Swap(param.strike, param.maturity, msg.sender, param.tokenTo, param.longTo, param.isLong0ToLong1, token0AndLong0Amount, token1AndLong1Amount);
    }

    function collect(TimeswapV2OptionCollectParam calldata param) external override noDelegateCall returns (uint256 token0Amount, uint256 token1Amount, uint256 shortAmount, bytes memory data) {
        if (!hasInteracted[param.strike][param.maturity]) Error.inactiveOptionChoice(param.strike, param.maturity);
        ParamLibrary.check(param, blockTimestamp());

        Option storage option = options[param.strike][param.maturity];

        // does main collect logic calculation
        (token0Amount, token1Amount, shortAmount) = option.collect(param.strike, param.transaction, param.amount);

        // update token0 and token1 balance target for any previous concurrent option transactions.
        processing.updateProcess(token0Amount, token1Amount, false, false);

        // transfer token0 amount to recipient.
        if (token0Amount != 0) IERC20(token0).safeTransfer(param.token0To, token0Amount);

        // transfer token1 amount to recipient.
        if (token1Amount != 0) IERC20(token1).safeTransfer(param.token1To, token1Amount);

        // skip callback if there is no data.
        if (param.data.length != 0)
            data = ITimeswapV2OptionCollectCallback(msg.sender).timeswapV2OptionCollectCallback(
                TimeswapV2OptionCollectCallbackParam({
                    strike: param.strike,
                    maturity: param.maturity,
                    token0Amount: token0Amount,
                    token1Amount: token1Amount,
                    shortAmount: shortAmount,
                    data: param.data
                })
            );

        option.short[msg.sender] -= shortAmount;

        emit Collect(param.strike, param.maturity, msg.sender, param.token0To, param.token1To, token0Amount, token1Amount, shortAmount);
    }
}
