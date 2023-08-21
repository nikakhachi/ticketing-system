// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/Event.sol";
import "../src/EventFactory.sol";

import "openzeppelin/token/ERC1155/utils/ERC1155Holder.sol";

/**
 * @title EventTest Contract
 * @author Nika Khachiashvili
 * @dev Test cases for Event and EventFactory contracts
 * @dev IMPORTANT: These test cases aren't ready for production use, because not all the edge, tiny very specific cases are covered
 */
contract EventTest is Test, ERC1155Holder {
    event EventCreated(
        address indexed eventAddress,
        address indexed owner,
        uint256 indexed timestamp
    );

    Event public e;
    EventFactory public eFactory;

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

    /// @dev Setting up the testing environment
    function setUp() public {
        tickets.push(Event.Ticket(ticket1Id, ticket1Price, ticket1MaxSupply));
        tickets.push(Event.Ticket(ticket2Id, ticket2Price, ticket2MaxSupply));
        tickets.push(Event.Ticket(ticket3Id, ticket3Price, ticket3MaxSupply));

        eFactory = new EventFactory();
        e = Event(payable(eFactory.createEvent(tickets)));
    }

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
        Event _e = Event(payable(eFactory.createEvent(tickets)));

        for (uint i = 0; i < tickets.length; i++) {
            uint id = tickets[i].id;
            uint price = tickets[i].price;
            uint maxSupply = tickets[i].maxSupply;

            assertEq(_e.ticketsWithPrice(id), price);
            assertEq(_e.ticketsWithMaxSupply(id), maxSupply);
            assertEq(_e.ticketIds(i), id);
        }
    }

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

    /// @dev Testing the ending of sales by owner
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

    /// @dev Testing the ending of sales by non owner
    function testNonOwnerEndingTheSales() public {
        uint amount = 10;

        e.buyTickets{value: amount * ticket1Price}(
            address(this),
            ticket1Id,
            amount
        );

        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        vm.prank(address(1));
        e.endSales();
    }

    /// @dev Testing the continuing of sales by owner
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

    /// @dev Testing the continuing of sales by non owner
    function testNonOwnerContinuingTheSales() public {
        uint amount = 10;

        e.buyTickets{value: amount * ticket1Price}(
            address(this),
            ticket1Id,
            amount
        );

        e.endSales();

        vm.expectRevert(bytes("Ownable: caller is not the owner"));
        vm.prank(address(1));
        e.continueSales();
    }

    /// @dev Testing the ticket transfer on pause
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

    /// @dev Testing the funds transfer and withdraw
    function testRecievingAndWithdrawingEther() public {
        assertEq(address(e).balance, 0);

        (bool success, ) = address(e).call{value: 1 ether}("");
        require(success);

        assertEq(address(e).balance, 1 ether);

        e.withdrawFunds();

        assertEq(address(e).balance, 0);
    }

    receive() external payable {}
}
