// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Event.t.sol";

/**
 * @title DeploymentTest Contract
 * @author Nika Khachiashvili
 * @dev Test cases for buying of tickets
 */
contract DeploymentTest is EventTest {
    /// @dev Testing the initial variables
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

    /// @dev Testing the initial variables second time directly from created event from Factory
    function testCreateEventFromFactory() public {
        vm.expectEmit(false, true, true, false);
        emit EventCreated(address(0), address(this), block.timestamp);
        Event _e = Event(payable(eFactory.createEvent("", tickets, 100)));
        _e.acceptOwnership();

        for (uint i = 0; i < tickets.length; i++) {
            uint id = tickets[i].id;
            uint price = tickets[i].price;
            uint maxSupply = tickets[i].maxSupply;

            assertEq(_e.ticketsWithPrice(id), price);
            assertEq(_e.ticketsWithMaxSupply(id), maxSupply);
            assertEq(_e.ticketIds(i), id);
        }

        assertEq(e.TRANSFER_FEE_PERCENTAGE(), 100);
    }
}
