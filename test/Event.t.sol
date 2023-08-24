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
        e = Event(payable(eFactory.createEvent("", tickets)));
        e.acceptOwnership();
    }

    receive() external payable {}
}
