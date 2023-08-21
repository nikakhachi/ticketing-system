// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "./Event.sol";

/// @title EventFactory Contract
/// @author Nika Khachiashvili
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

    /// @dev Upgradeable Contract Initializer
    /// @dev Can be called only once
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    /// @notice Function for creating the event contract
    /// @param tickets data about the tickets, including id, price and the amount
    function createEvent(
        Event.Ticket[] calldata tickets
    ) external virtual returns (address) {
        Event e = new Event(tickets);
        e.transferOwnership(msg.sender);
        emit EventCreated(address(e), msg.sender, block.timestamp);
        return address(e);
    }

    /// @notice Returns the version of the contract
    /// @return The version of the contract
    function version() external pure virtual returns (string memory) {
        return "v1";
    }

    /// @dev Function for upgrading the contract
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
