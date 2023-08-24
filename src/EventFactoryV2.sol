// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./EventFactory.sol";
import "./EventV2.sol";

/// @title EventFactory Contract
/// @author Nika Khachiashvili
contract EventFactoryV2 is EventFactory {
    /// @notice Function for creating the event contract
    /// @param tickets data about the tickets, including id, price and the amount
    function createEvent(
        string memory _uri,
        Event.Ticket[] calldata tickets
    ) external override returns (address) {
        Event e = new EventV2(_uri, tickets);
        e.transferOwnership(msg.sender);
        emit EventCreated(address(e), msg.sender, block.timestamp);
        return address(e);
    }

    /// @notice Returns the version of the contract
    /// @return The version of the contract
    function version() external pure override returns (string memory) {
        return "v2";
    }
}
