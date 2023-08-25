// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Event.sol";

/// @title Event Contract
/// @author Nika Khachiashvili
contract EventV2 is Event {
    /// @dev Contract constructor
    /// @dev Is called only once on the deployment
    /// @param _uri uri of the event
    /// @param tickets data about the tickets, including id, price and the amount
    /// @param _transferFee transfer fee percentage
    constructor(
        string memory _uri,
        Ticket[] memory tickets,
        uint16 _transferFee
    ) Event(_uri, tickets, _transferFee) {}

    /// @notice Returns the version of the contract
    /// @return The version of the contract
    function version() external pure override returns (string memory) {
        return "v2";
    }
}
