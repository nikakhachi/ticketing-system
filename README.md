# Ticketing System with Factory

This project implements an upgradeable (UUPS Proxy pattern) Event Factory smart contract, which is responsible for creating Event smart contracts for ERC1155 ticket sales.

The development tool used is the Foundry where the contracts and the tests are written, and then there's hardhat integrated which is used for writing the deployment and upgrade scripts.

## Table of Contents

- [Features](#features)
- [Testing](#testing)
- [Deploying](#deploying)

## Features

### EventFactory

- **_createEvent_** - Users can create the Event smart contract by calling this function and passing in the data about the tickets. This data should include the different types of tickets that there will be with their id, cost, and the maximum supply. The ownership of this smart contract is then transferred to the caller of the transaction and the EventCreated event is fired.

- **_version_** - Returns the version of the Factory contract as it's upgradeable.

### Event

- **_buyTickets_** - By calling this function, users can buy ticket(s) for that specific event. The exact ether value should be sent with this transaction for it to succeed, if it is sent more, the transaction will revert. If the maximum amount of ticket amount has been reached, users won't be able to call this function. The owner of the event contract can also pause the ticket sales which will make it impossible for users to call this function.

- **_buyTicketsBatch_** - If users want to buy different types of tickets, they should call this function, if even one of the ticket number limits is reached, the whole transaction will revert. It's also important that the user should be sent the exact amount of ether for all the tickets combined for this transaction to succeed.

- **_remainingTickets_** - Returns the remaining amount of a specific ticket.

- **_soldTickets_** - Returns the sold amount of a specific ticket.

- **_endSales_** - Owners function to stop ticket sales. IMPORTANT: If the sales are stopped, users are still able to transfer tickets to other addresses.

- **_continueSales_** - Owners function to continue ticket sales.

- **_version_** - Returns the version of the contract.

- **_withdrawFunds_** - Transfers all the contract funds to the owner.

## Testing

Tests are written to cover as many scenarios as possible, but still, it's not enough for production. This should never happen in production-ready code!

To run the tests, you will have to do the following

1. Clone this repository to your local machine.
2. Run `forge install`.
3. Run `forge build`.
4. Run `forge test`.

OR, you can just run `forge test`, which will automatically install dependencies and compile the contracts.

## Deploying

To deploy the contract, you will have to do the following

1. Clone this repository to your local machine.
2. Run `forge install && npm install`.
3. Create the `.env` file based on the `.env.example`.
4. Modify network options in `hardhat.config.ts`.
5. Deploy the smart contract with ` npx hardhat run script/deploy.ts --network {network name}`

If you would like to deploy it locally, make sure to run `npx hardhat node` before the 3rd step, and deploy the smart contract with `localhost` as the "network name"
