// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Event.sol";

contract EventTest is Test {
    Event public e;

    Event.Ticket[] public tickets;

    function setUp() public {
        e = new Event();

        tickets.push(Event.Ticket(1, 1 ether, 200));
        tickets.push(Event.Ticket(2, 2 ether, 100));
        tickets.push(Event.Ticket(3, 10 ether, 10));

        e.initialize(tickets);
    }

    function testInitialVariables() public {
        for (uint i = 0; i < tickets.length; i++) {
            uint id = tickets[i].id;
            uint price = tickets[i].price;
            uint maxSupply = tickets[i].maxSupply;

            assertEq(e.ticketsWithPrice(id), price);
            assertEq(e.ticketsWithMaxSupply(id), maxSupply);
            assertEq(e.ticketIds(i), id);
        }
    }
}
