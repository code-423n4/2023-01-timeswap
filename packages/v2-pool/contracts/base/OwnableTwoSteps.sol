//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

import {Error} from '@timeswap-labs/v2-library/contracts/Error.sol';
import {Ownership} from '@timeswap-labs/v2-library/contracts/Ownership.sol';

import {IOwnableTwoSteps} from '../interfaces/IOwnableTwoSteps.sol';

/// @dev contract for ownable implementation with a safety two step owner transfership.
contract OwnableTwoSteps is IOwnableTwoSteps {
  using Ownership for address;

  /// @dev The current owner of the contract.
  address public override owner;
  /// @dev The pending owner of the contract. Is zero when none is pending.
  address public override pendingOwner;

  constructor(address chosenOwner) {
    owner = chosenOwner;
  }

  /// @inheritdoc IOwnableTwoSteps
  function setPendingOwner(address chosenPendingOwner) external override {
    Ownership.checkIfOwner(owner);

    if (chosenPendingOwner == address(0)) Error.zeroAddress();
    chosenPendingOwner.checkIfAlreadyOwner(owner);

    pendingOwner = chosenPendingOwner;

    emit SetOwner(pendingOwner);
  }

  /// @inheritdoc IOwnableTwoSteps
  function acceptOwner() external override {
    msg.sender.checkIfPendingOwner(pendingOwner);

    owner = msg.sender;
    delete pendingOwner;

    emit AcceptOwner(msg.sender);
  }
}
