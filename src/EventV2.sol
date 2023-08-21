// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Event.sol";

contract EventV2 is Event {
    constructor(Ticket[] memory tickets) Event(tickets) {}

    function version() external pure override returns (string memory) {
        return "v2";
    }
}
