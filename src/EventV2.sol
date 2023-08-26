// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./Event.sol";

/// @title Event Contract
/// @author Nika Khachiashvili
contract EventV2 is Event {
    /// @dev Contract constructor
    /// @dev Is called only once on the deployment
    /// @param _uri uri of the event
    /// @param _transferFee transfer fee percentage
    /// @param _wethAddress address of the WETH token
    /// @param _chainlinkFeedRegistryAddress address of the Chainlink Feed Registry
    /// @param _tickets data about the tickets, including id, price and the amount
    constructor(
        string memory _uri,
        uint16 _transferFee,
        address _wethAddress,
        address _chainlinkFeedRegistryAddress,
        Ticket[] memory _tickets
    )
        Event(
            _uri,
            _transferFee,
            _wethAddress,
            _chainlinkFeedRegistryAddress,
            _tickets
        )
    {}

    /// @notice Returns the version of the contract
    /// @return The version of the contract
    function version() external pure override returns (string memory) {
        return "v2";
    }
}
