// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Event.t.sol";

/**
 * @title BuyingTicketsTest Contract
 * @author Nika Khachiashvili
 * @dev Test cases for buying of tickets
 */
contract BuyingTicketsTest is EventTest {
    /// @dev Fuzz Testing the buying of tickets
    function testBuyTicketsFuzz(uint _amount) public {
        vm.assume(_amount <= ticket1MaxSupply);
        e.buyTickets{value: _amount * ticket1Price}(
            address(this),
            ticket1Id,
            _amount
        );

        assertEq(e.balanceOf(address(this), ticket1Id), _amount);
        assertEq(e.soldTickets(ticket1Id), _amount);
        assertEq(e.remainingTickets(ticket1Id), ticket1MaxSupply - _amount);
    }

    /// @dev Fuzz Testing the buying of tickets for someone else
    function testBuyTicketsForElseFuzz(uint _amount) public {
        vm.assume(_amount <= ticket1MaxSupply);

        address receiver = address(1);

        e.buyTickets{value: _amount * ticket1Price}(
            receiver,
            ticket1Id,
            _amount
        );

        assertEq(e.balanceOf(receiver, ticket1Id), _amount);
        assertEq(e.soldTickets(ticket1Id), _amount);
        assertEq(e.remainingTickets(ticket1Id), ticket1MaxSupply - _amount);
    }

    /// @dev Fuzz Testing the buying of more tickets that the max supply
    function testBuyMoreTicketsThanMaxSupplyFuzz(uint amount2) public {
        vm.assume(
            amount2 > ticket1MaxSupply / 2 && amount2 < ticket1MaxSupply * 10
        );

        uint amount1 = ticket1MaxSupply / 2;

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

    /// @dev Fuzz Testing the buying of tickets with invalid price
    function testBuyTicketsWithInvalidPriceFuzz(uint priceDelta) public {
        uint amount = 22;
        vm.assume(priceDelta > 0 && priceDelta < amount * ticket1Price);

        vm.expectRevert(Event.InvalidPrice.selector);
        e.buyTickets{value: amount * ticket1Price - priceDelta}(
            address(this),
            ticket1Id,
            amount
        );

        vm.expectRevert(Event.InvalidPrice.selector);
        e.buyTickets{value: amount * ticket1Price + priceDelta}(
            address(this),
            ticket1Id,
            amount
        );
    }

    /// @dev Testing the batch buying of tickets
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
        assertEq(e.remainingTickets(ticket1Id), ticket1MaxSupply - amount1);

        assertEq(e.balanceOf(address(this), ticket3Id), amount3);
        assertEq(e.soldTickets(ticket3Id), amount3);
        assertEq(e.remainingTickets(ticket3Id), ticket3MaxSupply - amount3);
    }

    /// @dev Testing the batch buying of tickets for someone else
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
        assertEq(e.remainingTickets(ticket1Id), ticket1MaxSupply - amount1);

        assertEq(e.balanceOf(receiver, ticket3Id), amount3);
        assertEq(e.soldTickets(ticket3Id), amount3);
        assertEq(e.remainingTickets(ticket3Id), ticket3MaxSupply - amount3);
    }

    /// @dev Testing the batch buying of more tickets that the max supply
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

    /// @dev Testing the batch buying of tickets with invalid price
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
}
