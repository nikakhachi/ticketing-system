// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Event.t.sol";

/**
 * @title OwnerActionsTest Contract
 * @author Nika Khachiashvili
 * @dev Test cases for buying of tickets
 */
contract OwnerActionsTest is EventTest {
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
}
