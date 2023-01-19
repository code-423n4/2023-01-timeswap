//SPDX-License-Identifier: Unlicense
pragma solidity =0.8.8;

library Ownership {
    /// @dev Reverts when the caller is not the owner.
    /// @param caller The caller of the function that is not the owner.
    /// @param owner The actual owner.
    error NotTheOwner(address caller, address owner);

    /// @dev reverts when the caller is already the owner.
    /// @param owner The owner.
    error AlreadyTheOwner(address owner);

    /// @dev revert when the caller is not the pending owner.
    /// @param caller The caller of the function that is not the pending owner.
    /// @param pendingOwner The actual pending owner.
    error NotThePendingOwner(address caller, address pendingOwner);

    /// @dev checks if the caller is the owner.
    /// @notice Reverts when the msg.sender is not the owner.
    /// @param owner The owner address.
    function checkIfOwner(address owner) internal view {
        if (msg.sender != owner) revert NotTheOwner(msg.sender, owner);
    }

    /// @dev checks if the caller is already the owner.
    /// @notice Reverts when the chosen pending owner is already the owner.
    /// @param chosenPendingOwner The chosen pending owner.
    /// @param owner The current actual owner.
    function checkIfAlreadyOwner(address chosenPendingOwner, address owner) internal pure {
        if (chosenPendingOwner == owner) revert AlreadyTheOwner(owner);
    }

    /// @dev checks if the caller is the pending owner.
    /// @notice Reverts when the caller is not the pending owner.
    /// @param caller The address of the caller.
    /// @param pendingOwner The current pending owner.
    function checkIfPendingOwner(address caller, address pendingOwner) internal pure {
        if (caller != pendingOwner) revert NotThePendingOwner(caller, pendingOwner);
    }
}
