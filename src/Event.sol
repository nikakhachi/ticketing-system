// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "openzeppelin/token/ERC1155/ERC1155.sol";
import "openzeppelin/access/Ownable2Step.sol";
import "openzeppelin/security/Pausable.sol";
import "openzeppelin/token/ERC1155/extensions/ERC1155Burnable.sol";
import "openzeppelin/token/ERC1155/extensions/ERC1155Supply.sol";
import {ERC20} from "openzeppelin/token/ERC20/ERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "chainlink/contracts/src/v0.8/interfaces/FeedRegistryInterface.sol";
import "./UC.sol";
// console
import "forge-std/console.sol";

/// @title Event Contract
/// @author Nika Khachiashvili
contract Event is
    ERC1155,
    Ownable2Step,
    Pausable,
    ERC1155Burnable,
    ERC1155Supply
{
    using SafeERC20 for ERC20;

    /// @dev Custom Errors
    error InvalidPrice();
    error MaxSupplyReached();

    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; /// @dev Used for transfer fees
    uint16 public immutable TRANSFER_FEE_PERCENTAGE; /// @dev 1 = 0.01% transfer fee

    FeedRegistryInterface public constant CHAINLINK_FEED_REGISTRY =
        FeedRegistryInterface(0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf); /// @dev Used for getting the price of the token when paying with token

    address public constant CHAINLINK_ETH_DENOMINATION_ =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE; /// @dev Used for price feed for ETH denomination

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
    /// @param _uri uri of the event
    /// @param _tickets data about the tickets, including id, price and the amount
    /// @param _transferFee transfer fee percentage
    constructor(
        string memory _uri,
        Ticket[] memory _tickets,
        uint16 _transferFee
    ) ERC1155(_uri) {
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

        TRANSFER_FEE_PERCENTAGE = _transferFee;
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

    /// @notice Function for buying tickets
    /// @param _to address where the tickets will be sent
    /// @param _token payment oken
    /// @param _ticketId id of the ticket
    /// @param _quantity quantity of tickets to buy
    function buyTicketsWithToken(
        address _to,
        address _token,
        uint256 _ticketId,
        uint256 _quantity
    ) external whenNotPaused {
        if (
            ERC1155Supply.totalSupply(_ticketId) + _quantity >
            ticketsWithMaxSupply[_ticketId]
        ) revert MaxSupplyReached();

        (, int tokenPriceInEth, , , ) = CHAINLINK_FEED_REGISTRY.latestRoundData(
            _token,
            CHAINLINK_ETH_DENOMINATION_
        );

        ERC20 token = ERC20(_token);

        token.safeTransferFrom(
            msg.sender,
            address(this),
            ((ticketsWithPrice[_ticketId] *
                _quantity *
                10 ** ERC20(_token).decimals()) / uint256(tokenPriceInEth))
        );

        _mint(_to, _ticketId, _quantity, "");
    }

    /// @notice Function for getting ticket price in provided token
    /// @param _token payment oken
    /// @param _ticketId id of the ticket
    /// @return The price of the ticket in provided token
    function ticketPriceInToken(
        address _token,
        uint256 _ticketId,
        uint256 _quantity
    ) external view returns (uint256) {
        (, int tokenPriceInEth, , , ) = CHAINLINK_FEED_REGISTRY.latestRoundData(
            _token,
            CHAINLINK_ETH_DENOMINATION_
        );

        return ((ticketsWithPrice[_ticketId] *
            _quantity *
            10 ** ERC20(_token).decimals()) / uint256(tokenPriceInEth));
    }

    /// @notice Function for buying tickets in batch
    /// @param to address where the tickets will be sent
    /// @param ids ids of the tickets
    /// @param quantities amounts of tickets to buy
    // TODO: VULNERABILITY: user can include same ids multiple times in the array and get more tickets than the maximum supply
    function buyTicketsBatch(
        address to,
        uint256[] calldata ids,
        uint256[] calldata quantities
    ) public payable whenNotPaused {
        uint256 overallPrice;
        for (uint256 i; i < ids.length; ++i) {
            uint256 ticketQuantity = quantities[i];
            uint256 ticketId = ids[i];

            overallPrice += ticketsWithPrice[ticketId] * ticketQuantity;

            if (
                ERC1155Supply.totalSupply(ticketId) + ticketQuantity >
                ticketsWithMaxSupply[ticketId]
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

    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal override(ERC1155) {
        ERC20(WETH).safeTransferFrom(
            msg.sender,
            address(this),
            (ticketsWithPrice[id] * TRANSFER_FEE_PERCENTAGE * amount) / 100
        );
        super._safeTransferFrom(from, to, id, amount, data);
    }

    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155) {
        uint256 overallValue;
        for (UC i = ZERO; i < uc(ids.length); i = i + ONE) {
            uint index = i.unwrap();
            overallValue += ticketsWithPrice[ids[index]] * amounts[index];
        }
        ERC20(WETH).safeTransferFrom(
            msg.sender,
            address(this),
            (overallValue * TRANSFER_FEE_PERCENTAGE) / 100
        );
        super._safeBatchTransferFrom(from, to, ids, amounts, data);
    }
}
