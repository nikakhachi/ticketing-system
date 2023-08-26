// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./EventFactory.sol";
import "./EventV2.sol";

/// @title EventFactory Contract
/// @author Nika Khachiashvili
contract EventFactoryV2 is EventFactory {
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
    ) external override returns (address) {
        Event e = new EventV2(
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
    function version() external pure override returns (string memory) {
        return "v2";
    }
}
