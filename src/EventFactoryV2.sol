// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./EventFactory.sol";
import "./EventV2.sol";

/// @title EventFactory Contract
/// @author Nika Khachiashvili
contract EventFactoryV2 is EventFactory {
    /// @notice Function for creating the event contract
    /// @param _uri uri of the event
    /// @param tickets data about the tickets, including id, price and the amount
    /// @param _transferFee transfer fee percentage
    function createEvent(
        string calldata _uri,
        Event.Ticket[] calldata tickets,
        uint16 _transferFee
    ) external override returns (address) {
        Event e = new EventV2(_uri, tickets, _transferFee);
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
