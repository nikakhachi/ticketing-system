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
    /// @param _uri uri of the event
    /// @param _transferFee transfer fee percentage
    /// @param _wethAddress address of the WETH token
    /// @param _chainlinkFeedRegistryAddress address of the Chainlink Feed Registry
    /// @param _tickets data about the tickets, including id, price and the amount
    /// @return Address of the created event contract
    function createEvent(
        string memory _uri,
        uint16 _transferFee,
        address _wethAddress,
        address _chainlinkFeedRegistryAddress,
        Event.Ticket[] memory _tickets
    ) external virtual returns (address) {
        Event e = new Event(
            _uri,
            _transferFee,
            _wethAddress,
            _chainlinkFeedRegistryAddress,
            _tickets
        );
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
