// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin/token/ERC1155/ERC1155.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/security/Pausable.sol";
import "openzeppelin/token/ERC1155/extensions/ERC1155Burnable.sol";
import "openzeppelin/token/ERC1155/extensions/ERC1155Supply.sol";

contract Event is ERC1155, Ownable, Pausable, ERC1155Burnable, ERC1155Supply {
    error InvalidPrice();
    error MaxSupplyReached();

    struct Ticket {
        uint256 id;
        uint256 price;
        uint256 maxSupply;
    }

    mapping(uint256 => uint256) public ticketsWithPrice;
    mapping(uint256 => uint256) public ticketsWithMaxSupply;
    uint256[] public ticketIds;

    constructor(Ticket[] memory tickets) ERC1155("") {
        uint256[] memory _ticketIds = new uint256[](tickets.length);

        for (uint256 i; i < tickets.length; i++) {
            Ticket memory ticket = tickets[i];
            ticketsWithPrice[ticket.id] = ticket.price;
            ticketsWithMaxSupply[ticket.id] = ticket.maxSupply;
            _ticketIds[i] = ticket.id;
        }

        ticketIds = _ticketIds;
    }

    function buyTickets(
        address to,
        uint256 ticketId,
        uint256 amount
    ) public payable whenNotPaused {
        if (msg.value != ticketsWithPrice[ticketId] * amount)
            revert InvalidPrice();
        if (
            ERC1155Supply.totalSupply(ticketId) + amount >
            ticketsWithMaxSupply[ticketId]
        ) revert MaxSupplyReached();

        _mint(to, ticketId, amount, "");
    }

    function buyTicketsBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts
    ) public payable whenNotPaused {
        uint256 overallPrice;
        for (uint256 i; i < ids.length; i++) {
            overallPrice += ticketsWithPrice[ids[i]] * amounts[i];
            if (
                ERC1155Supply.totalSupply(ids[i]) + amounts[i] >
                ticketsWithMaxSupply[ids[i]]
            ) revert MaxSupplyReached();
        }
        if (msg.value != overallPrice) revert InvalidPrice();
        _mintBatch(to, ids, amounts, "");
    }

    function soldTickets(uint256 ticketId) public view returns (uint256) {
        return ERC1155Supply.totalSupply(ticketId);
    }

    function endSales() public onlyOwner {
        _pause();
    }

    function continueSales() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function version() external pure virtual returns (string memory) {
        return "v1";
    }
}
