// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./EventFactory.sol";
import "./EventV2.sol";

contract EventFactoryV2 is EventFactory {
    function createEvent(
        Event.Ticket[] calldata tickets
    ) external override returns (address) {
        Event e = new EventV2(tickets);
        e.transferOwnership(msg.sender);
        emit EventCreated(address(e), msg.sender, block.timestamp);
        return address(e);
    }

    function version() external pure override returns (string memory) {
        return "v2";
    }
}
