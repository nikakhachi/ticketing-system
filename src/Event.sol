// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin/token/ERC1155/ERC1155.sol";
import "openzeppelin/access/Ownable.sol";
import "openzeppelin/security/Pausable.sol";
import "openzeppelin/token/ERC1155/extensions/ERC1155Burnable.sol";
import "openzeppelin/token/ERC1155/extensions/ERC1155Supply.sol";
import "./UC.sol";

/// @title Event Contract
/// @author Nika Khachiashvili
contract Event is ERC1155, Ownable, Pausable, ERC1155Burnable, ERC1155Supply {
    /// @dev Custom Errors
    error InvalidPrice();
    error MaxSupplyReached();

    /// @dev Ticket struct with data used for creating the event
    struct Ticket {
        uint256 id;
        uint256 price;
        uint256 maxSupply;
    }

    mapping(uint256 => uint256) public ticketsWithPrice; /// @dev Mapping of ticket id to ticket price
    mapping(uint256 => uint256) public ticketsWithMaxSupply; /// @dev Mapping of ticket id to ticket max supply

    /// @dev List of available ticket ids
    uint256[] public ticketIds;

    /// @dev Contract constructor
    /// @dev Is called only once on the deployment
    /// @param _tickets data about the tickets, including id, price and the amount
    constructor(Ticket[] memory _tickets) ERC1155("") {
        uint length = _tickets.length;

        for (UC i = ZERO; i < uc(length); i = i + ONE) {
            Ticket memory ticket = _tickets[i.unwrap()];

            /// @dev Instead of 2 mappings, I've also tested using mapping => struct, but
            /// @dev it was more expensive for users, so here's the current, cheaper implementation
            ticketsWithPrice[ticket.id] = ticket.price;
            ticketsWithMaxSupply[ticket.id] = ticket.maxSupply;

            /// @dev I've tested pushing in the loop like it's here vs
            /// @dev creating a memory array and updating the state at the end
            /// @dev But current implementation is cheaper
            ticketIds.push(ticket.id);
        }
    }

    /// @notice Function for buying tickets
    /// @param to address where the tickets will be sent
    /// @param ticketId id of the ticket
    /// @param quantity quantity of tickets to buy
    function buyTickets(
        address to,
        uint256 ticketId,
        uint256 quantity
    ) public payable whenNotPaused {
        if (msg.value != ticketsWithPrice[ticketId] * quantity)
            revert InvalidPrice();
        if (
            ERC1155Supply.totalSupply(ticketId) + quantity >
            ticketsWithMaxSupply[ticketId]
        ) revert MaxSupplyReached();

        _mint(to, ticketId, quantity, "");
    }

    /// @notice Function for buying tickets in batch
    /// @param to address where the tickets will be sent
    /// @param ids ids of the tickets
    /// @param quantities amounts of tickets to buy
    // TODO: VULNERABILITY: user can include same ids multiple times in the array and get more tickets than the maximum supply
    function buyTicketsBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory quantities
    ) public payable whenNotPaused {
        uint256 overallPrice;
        for (uint256 i; i < ids.length; ++i) {
            uint256 ticketQuantity = quantities[i];

            overallPrice += ticketsWithPrice[ids[i]] * ticketQuantity;

            if (
                ERC1155Supply.totalSupply(ids[i]) + ticketQuantity >
                ticketsWithMaxSupply[ids[i]]
            ) {
                revert MaxSupplyReached();
            }
        }
        if (msg.value != overallPrice) revert InvalidPrice();
        _mintBatch(to, ids, quantities, "");
    }

    /// @notice Function for getting the remaining tickets
    /// @param ticketId id of the ticket
    /// @return The amount of remaining tickets
    function remainingTickets(uint256 ticketId) public view returns (uint256) {
        return
            ticketsWithMaxSupply[ticketId] -
            ERC1155Supply.totalSupply(ticketId);
    }

    /// @notice Function for getting the sold tickets
    /// @param ticketId id of the ticket
    /// @return The amount of sold tickets
    function soldTickets(uint256 ticketId) public view returns (uint256) {
        return ERC1155Supply.totalSupply(ticketId);
    }

    /// @notice Owner's function for ending the ticket sales
    function endSales() public onlyOwner {
        _pause();
    }

    /// @notice Owner's function for continuing the ticket sales
    function continueSales() public onlyOwner {
        _unpause();
    }

    /// @notice Returns the version of the contract
    /// @return The version of the contract
    function version() external pure virtual returns (string memory) {
        return "v1";
    }

    /// @notice Owner's Function for withdrawing the funds from the contract to their address
    function withdrawFunds() public onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success);
    }

    receive() external payable {}

    /// @dev Override required by Solidity for the OpenZeppelin
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
}
