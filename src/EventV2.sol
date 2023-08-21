// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Event.sol";

/// @title Event Contract
/// @author Nika Khachiashvili
contract EventV2 is Event {
    /// @dev Contract constructor
    /// @dev Is called only once on the deployment
    /// @param tickets data about the tickets, including id, price and the amount
    constructor(Ticket[] memory tickets) Event(tickets) {}

    /// @notice Returns the version of the contract
    /// @return The version of the contract
    function version() external pure override returns (string memory) {
        return "v2";
    }
}
