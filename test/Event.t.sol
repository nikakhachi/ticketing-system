// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Event.sol";

import "openzeppelin/token/ERC1155/utils/ERC1155Holder.sol";

contract EventTest is Test, ERC1155Holder {
    Event public e;

    Event.Ticket[] public tickets;

    uint256 public ticket1Id = 1;
    uint256 public ticket2Id = 2;
    uint256 public ticket3Id = 3;

    uint256 public ticket1Price = 1 ether;
    uint256 public ticket2Price = 2 ether;
    uint256 public ticket3Price = 10 ether;

    uint256 public ticket1MaxSupply = 200;
    uint256 public ticket2MaxSupply = 100;
    uint256 public ticket3MaxSupply = 10;

    /// @dev Needed to test batch functions
    uint256[] public ids;
    uint256[] public amounts;

    function setUp() public {
        e = new Event();

        tickets.push(Event.Ticket(ticket1Id, ticket1Price, ticket1MaxSupply));
        tickets.push(Event.Ticket(ticket2Id, ticket2Price, ticket2MaxSupply));
        tickets.push(Event.Ticket(ticket3Id, ticket3Price, ticket3MaxSupply));

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

    function testBuyTickets() public {
        uint amount = 22;

        e.buyTickets{value: amount * ticket1Price}(
            address(this),
            ticket1Id,
            amount
        );

        assertEq(e.balanceOf(address(this), ticket1Id), amount);
        assertEq(e.soldTickets(ticket1Id), amount);
    }

    function testBuyTicketsForElse() public {
        uint amount = 22;
        address receiver = address(1);

        e.buyTickets{value: amount * ticket1Price}(receiver, ticket1Id, amount);

        assertEq(e.balanceOf(receiver, ticket1Id), amount);
        assertEq(e.soldTickets(ticket1Id), amount);
    }

    function testBuyMoreTicketsThanMaxSupply() public {
        uint amount1 = ticket1MaxSupply / 2;
        uint amount2 = ticket1MaxSupply / 2 + 1;

        e.buyTickets{value: amount1 * ticket1Price}(
            address(this),
            ticket1Id,
            amount1
        );

        vm.expectRevert(Event.MaxSupplyReached.selector);
        e.buyTickets{value: amount2 * ticket1Price}(
            address(this),
            ticket1Id,
            amount2
        );
    }

    function testBuyTicketsWithInvalidPrice() public {
        uint amount = 22;

        vm.expectRevert(Event.InvalidPrice.selector);
        e.buyTickets{value: amount * ticket1Price - 1}(
            address(this),
            ticket1Id,
            amount
        );

        vm.expectRevert(Event.InvalidPrice.selector);
        e.buyTickets{value: amount * ticket1Price + 1}(
            address(this),
            ticket1Id,
            amount
        );
    }

    function testBuyTicketsBatch() public {
        uint amount1 = 50;
        uint amount3 = 5;

        ids.push(ticket1Id);
        ids.push(ticket3Id);

        amounts.push(amount1);
        amounts.push(amount3);

        e.buyTicketsBatch{
            value: amount1 * ticket1Price + amount3 * ticket3Price
        }(address(this), ids, amounts);

        assertEq(e.balanceOf(address(this), ticket1Id), amount1);
        assertEq(e.soldTickets(ticket1Id), amount1);

        assertEq(e.balanceOf(address(this), ticket3Id), amount3);
        assertEq(e.soldTickets(ticket3Id), amount3);
    }

    function testBuyTicketsBatchForElse() public {
        uint amount1 = 50;
        uint amount3 = 5;
        address receiver = address(1);

        ids.push(ticket1Id);
        ids.push(ticket3Id);

        amounts.push(amount1);
        amounts.push(amount3);

        e.buyTicketsBatch{
            value: amount1 * ticket1Price + amount3 * ticket3Price
        }(receiver, ids, amounts);

        assertEq(e.balanceOf(receiver, ticket1Id), amount1);
        assertEq(e.soldTickets(ticket1Id), amount1);

        assertEq(e.balanceOf(receiver, ticket3Id), amount3);
        assertEq(e.soldTickets(ticket3Id), amount3);
    }

    function testBuyMoreTicketsThanMaxSupplyInBatch() public {
        uint amount1 = 50;
        uint amount3 = ticket3MaxSupply + 1;

        ids.push(ticket1Id);
        ids.push(ticket3Id);

        amounts.push(amount1);
        amounts.push(amount3);

        vm.expectRevert(Event.MaxSupplyReached.selector);
        e.buyTicketsBatch{
            value: amount1 * ticket1Price + amount3 * ticket3Price
        }(address(this), ids, amounts);
    }

    function testBuyTicketsWithInvalidPriceInBatch() public {
        uint amount1 = 50;
        uint amount3 = 2;

        ids.push(ticket1Id);
        ids.push(ticket3Id);

        amounts.push(amount1);
        amounts.push(amount3);

        vm.expectRevert(Event.InvalidPrice.selector);
        e.buyTicketsBatch{
            value: amount1 * ticket1Price + amount3 * ticket3Price + 1
        }(address(this), ids, amounts);

        vm.expectRevert(Event.InvalidPrice.selector);
        e.buyTicketsBatch{
            value: amount1 * ticket1Price + amount3 * ticket3Price - 1
        }(address(this), ids, amounts);
    }

    function testEndingTheSales() public {
        uint amount = 10;

        e.buyTickets{value: amount * ticket1Price}(
            address(this),
            ticket1Id,
            amount
        );

        e.endSales();

        vm.expectRevert(bytes("Pausable: paused"));
        e.buyTickets{value: amount * ticket1Price}(
            address(this),
            ticket1Id,
            amount
        );
    }

    function testContinuingTheSales() public {
        uint amount = 10;

        e.buyTickets{value: amount * ticket1Price}(
            address(this),
            ticket1Id,
            amount
        );

        e.endSales();

        e.continueSales();

        e.buyTickets{value: amount * ticket1Price}(
            address(this),
            ticket1Id,
            amount
        );
    }

    function testTicketTransferWhenPaused() public {
        uint amount = 10;

        e.buyTickets{value: amount * ticket1Price}(
            address(this),
            ticket1Id,
            amount
        );

        e.endSales();

        e.safeTransferFrom(address(this), address(1), ticket1Id, amount, "");
    }
}
