// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "openzeppelin-contracts-upgradeable/contracts/token/ERC1155/ERC1155Upgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/security/PausableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC1155/extensions/ERC1155BurnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";

contract Event is
    Initializable,
    ERC1155Upgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ERC1155BurnableUpgradeable,
    ERC1155SupplyUpgradeable,
    UUPSUpgradeable
{
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

    // /// @custom:oz-upgrades-unsafe-allow constructor
    // constructor() {
    //     _disableInitializers();
    // }

    function initialize(Ticket[] calldata tickets) public initializer {
        __ERC1155_init("");
        __Ownable_init();
        __Pausable_init();
        __ERC1155Burnable_init();
        __ERC1155Supply_init();
        __UUPSUpgradeable_init();

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
            ERC1155SupplyUpgradeable.totalSupply(ticketId) + amount >
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
                ERC1155SupplyUpgradeable.totalSupply(ids[i]) + amounts[i] >
                ticketsWithMaxSupply[ids[i]]
            ) revert MaxSupplyReached();
        }
        if (msg.value != overallPrice) revert InvalidPrice();
        _mintBatch(to, ids, amounts, "");
    }

    function soldTickets(uint256 ticketId) public view returns (uint256) {
        return ERC1155SupplyUpgradeable.totalSupply(ticketId);
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
    )
        internal
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
