// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "./Event.t.sol";

/**
 * @title TicketTransfersTest Contract
 * @author Nika Khachiashvili
 * @dev Test cases for ticket transfers
 */
contract TicketTransfersTest is EventTest {
    /// @dev Testing the ticket transfer
    function testTicketTransferFuzz(uint amount) public {
        vm.assume(amount <= ticket1MaxSupply);

        e.buyTickets{value: amount * ticket1Price}(
            address(this),
            ticket1Id,
            amount
        );

        uint transferFee = (ticket1Price *
            e.TRANSFER_FEE_PERCENTAGE() *
            amount) / 10000;

        deal(address(WETH), address(this), transferFee);

        ERC20(WETH).approve(address(e), transferFee);

        e.safeTransferFrom(address(this), address(1), ticket1Id, amount, "");

        assertEq(e.balanceOf(address(this), ticket1Id), 0);
        assertEq(e.balanceOf(address(1), ticket1Id), amount);
        assertEq(ERC20(WETH).balanceOf(address(this)), 0);
        assertEq(ERC20(WETH).balanceOf(address(e)), transferFee);
    }

    /// @dev Testing the ticket transfer
    function testBatchTicketTransferFuzz(uint amount1, uint amount2) public {
        vm.assume(amount1 <= ticket1MaxSupply);
        vm.assume(amount2 <= ticket2MaxSupply);

        ids.push(ticket1Id);
        ids.push(ticket2Id);

        amounts.push(amount1);
        amounts.push(amount2);

        e.buyTicketsBatch{
            value: amount1 * ticket1Price + amount2 * ticket2Price
        }(address(this), ids, amounts);

        uint ticket1TransferFee = (ticket1Price *
            e.TRANSFER_FEE_PERCENTAGE() *
            amount1) / 10000;

        uint ticket2TransferFee = (ticket2Price *
            e.TRANSFER_FEE_PERCENTAGE() *
            amount2) / 10000;

        uint totalFee = ticket1TransferFee + ticket2TransferFee;

        deal(address(WETH), address(this), totalFee);

        ERC20(WETH).approve(address(e), totalFee);

        e.safeBatchTransferFrom(address(this), address(1), ids, amounts, "");

        assertEq(e.balanceOf(address(this), ticket1Id), 0);
        assertEq(e.balanceOf(address(1), ticket1Id), amount1);
        assertEq(e.balanceOf(address(this), ticket2Id), 0);
        assertEq(e.balanceOf(address(1), ticket2Id), amount2);
        assertEq(ERC20(WETH).balanceOf(address(this)), 0);
        assertEq(ERC20(WETH).balanceOf(address(e)), totalFee);
    }

    /// @dev Testing the ticket transfer on pause
    function testTicketTransferWhenPausedFuzz(uint amount) public {
        vm.assume(amount <= ticket1MaxSupply);

        e.buyTickets{value: amount * ticket1Price}(
            address(this),
            ticket1Id,
            amount
        );

        e.endSales();

        uint transferFee = (ticket1Price *
            e.TRANSFER_FEE_PERCENTAGE() *
            amount) / 10000;

        deal(address(WETH), address(this), transferFee);

        ERC20(WETH).approve(address(e), transferFee);

        e.safeTransferFrom(address(this), address(1), ticket1Id, amount, "");
    }

    /// @dev Testing the ticket transfer with invalid fee
    function testTicketTransferWithInvalidFeeFuzz(uint amount) public {
        vm.assume(amount <= ticket1MaxSupply && amount > 0);

        e.buyTickets{value: amount * ticket1Price}(
            address(this),
            ticket1Id,
            amount
        );

        uint transferFee = (ticket1Price *
            e.TRANSFER_FEE_PERCENTAGE() *
            amount) / 10000;

        deal(address(WETH), address(this), transferFee);

        ERC20(WETH).approve(address(e), transferFee - 1);

        vm.expectRevert(bytes("SafeERC20: low-level call failed"));
        e.safeTransferFrom(address(this), address(1), ticket1Id, amount, "");
    }

    /// @dev Testing the ticket transfer
    function testBatchTicketTransferWithInvalidFeeFuzz(
        uint amount1,
        uint amount2
    ) public {
        vm.assume(amount1 <= ticket1MaxSupply && amount1 > 0);
        vm.assume(amount2 <= ticket2MaxSupply && amount2 > 0);

        ids.push(ticket1Id);
        ids.push(ticket2Id);

        amounts.push(amount1);
        amounts.push(amount2);

        e.buyTicketsBatch{
            value: amount1 * ticket1Price + amount2 * ticket2Price
        }(address(this), ids, amounts);

        uint ticket1TransferFee = (ticket1Price *
            e.TRANSFER_FEE_PERCENTAGE() *
            amount1) / 10000;

        uint ticket2TransferFee = (ticket2Price *
            e.TRANSFER_FEE_PERCENTAGE() *
            amount2) / 10000;

        uint totalFee = ticket1TransferFee + ticket2TransferFee;

        deal(address(WETH), address(this), totalFee);

        ERC20(WETH).approve(address(e), totalFee - 1);

        vm.expectRevert(bytes("SafeERC20: low-level call failed"));
        e.safeBatchTransferFrom(address(this), address(1), ids, amounts, "");
    }
}
