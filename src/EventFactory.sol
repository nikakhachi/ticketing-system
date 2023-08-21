// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./Event.sol";

contract EventFactory is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    event EventCreated(
        address indexed eventAddress,
        address indexed owner,
        uint256 indexed timestamp
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function createEvent(
        Event.Ticket[] calldata tickets
    ) external returns (address) {
        Event e = new Event(tickets);
        e.transferOwnership(msg.sender);
        emit EventCreated(address(e), msg.sender, block.timestamp);
        return address(e);
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
