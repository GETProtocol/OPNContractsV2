# OPNContractsV2

The OPN Ticketing Ecosystem EVM smart contracts.

## Overview

This repository contains the smart contracts for the OPN Ticketing Ecosystem, which facilitates decentralized ticketing operations. The contracts are designed to handle various aspects of ticketing, including pricing, authorization, and fuel management.

## Contracts

### EconomicsFactory.sol

- **EconomicsFactory**: This contract is responsible for deploying and managing `EconomicsImplementation` contracts for each integrator within the OPN Ticketing Ecosystem. It acts as a singular entry point for accounting operations for integrators. Key functionalities include:

     - **Deployment and Initialization**: Deploys new `EconomicsImplementation` contracts using the `BeaconProxy` pattern and initializes them with necessary parameters.
     - **Integrator Management**: Manages integrator configurations, including setting dynamic rates, enabling/disabling billing, and handling relayer addresses.
     - **Fuel Management**: Manages fuel token balances for integrators, including topping up fuel and migrating tokens during upgrades.
     - **Authorization and Security**: Utilizes authorization modifiers to restrict access to certain functions and includes reentrancy guards to prevent reentrancy attacks.
     - **Upgradeability**: Supports contract upgrades using the UUPS (Universal Upgradeable Proxy Standard) pattern.

     The contract interacts with various interfaces and abstract contracts to ensure secure and efficient operations, including `IRegistry`, `IFuelCollector`, `IEconomicsImplementation`, and `IEconomicsMigrator`.

### EconomicsImplementation.sol

- **EconomicsImplementation**: This contract manages accounting operations for integrators within the OPN Ticketing Ecosystem. It is deployed by the `EconomicsFactory` contract and handles various tasks, including fuel balance management, overdraft handling, and token migration. Key functionalities include:

     - **Fuel Management**: Manages the fuel token balance, including topping up fuel and handling fuel overdrafts.
     - **Pricing Mechanism**: Implements a First-In-First-Out (FIFO) pricing mechanism for fuel tokens.
     - **Authorization and Security**: Utilizes authorization modifiers to restrict access to certain functions and ensure secure operations.
     - **Fuel Routing**: Allows approved routers to deduct fuel based on USD amounts and fee types.
     - **Overdraft Handling**: Manages overdraft conditions and allows enabling/disabling overdraft status.
     - **Emergency Withdrawals**: Provides functionality for emergency withdrawal of tokens by integrator admins.
     - **Token Migration**: Supports migration to new fuel tokens, including updating storage values and handling token transfers.

     The contract interacts with various interfaces and abstract contracts to ensure secure and efficient operations, including `IRegistry`, `IFuelCollector`, `IFuelRouter`, and `IAuth`.

     ### EventFactory.sol

- **EventFactory**: This contract is responsible for deploying `IEventImplementation` contracts within the OPN Ticketing Ecosystem. All `EventImplementation` contracts are deployed as Beacon Proxies. Key functionalities include:

     - **Deployment and Initialization**: Deploys new `EventImplementation` contracts using the `BeaconProxy` pattern and initializes them with necessary parameters.
     - **Event Management**: Manages event configurations, including setting financing structures, token royalties, and handling event-specific actions.
     - **Authorization and Security**: Utilizes authorization modifiers to restrict access to certain functions and includes reentrancy guards to prevent reentrancy attacks.
     - **Upgradeability**: Supports contract upgrades using the UUPS (Universal Upgradeable Proxy Standard) pattern.

     The contract interacts with various interfaces and abstract contracts to ensure secure and efficient operations, including `IRegistry`, `IAuth`, `IRouterRegistry`, and `IEventImplementation`.

     - **Functions**:
          - `createEvent(string memory _name, string memory _symbol, IEventImplementation.EventData memory _eventData)`: Deploys an `EventImplementation` contract using the default router of the integrator.
          - `createEvent(string memory _name, string memory _symbol, IEventImplementation.EventData memory _eventData, uint256 _routerIndex)`: Deploys an `EventImplementation` contract using a custom router.
          - `setFinancingStructOfEvent(address _eventAddress, IEventImplementation.EventFinancing memory _financingStruct)`: Manually sets the event financing structure.
          - `setDefaultTokenRoyalty(address _eventAddress, address _receiver, uint96 _feeNominator)`: Sets the default royalty for all NFTs of the event.
          - `setExceptionTokenRoyalty(address _eventAddress, uint256 _tokenId, address _receiver, uint96 _feeNominator)`: Sets an exception royalty for a specific NFT.
          - `deleteRoyaltyException(address _eventAddress, uint256 _tokenId)`: Deletes the royalty info of a specific NFT.
          - `deleteRoyaltyDefault(address _eventAddress)`: Deletes the default royalty info.
          - `returnEventAddressByIndex(uint256 _eventIndex)`: Returns the event address of a particular event index.
          - `returnEventIndexByAddress(address _address)`: Returns the event index of a particular event address.
          - `batchActions(address[] calldata _eventAddressArray, IEventImplementation.TicketAction[][] calldata _ticketActionsArray, uint8[][] calldata _actionCountsArray, IEventImplementation.BalanceUpdates[][] calldata _balanceUpdatesArray)`: Executes batch actions for multiple events.

     The contract ensures secure and efficient event management within the OPN Ticketing Ecosystem.

     ### EventImplementation.sol

- **EventImplementation**: This contract is responsible for NFT mints and transfers within the OPN Ticketing Ecosystem. Each `EventImplementation` contract is deployed per real-world event by the `EventFactory` contract. It extends the ERC721 specification to manage ticket lifecycle events such as sales, scans, check-ins, invalidations, and claims. Key functionalities include:

     - **Ticket Lifecycle Management**: Handles primary and secondary sales, scans, check-ins, invalidations, claims, and transfers of tickets.
     - **Authorization and Security**: Utilizes authorization modifiers to restrict access to certain functions and ensure secure operations.
     - **Event Data Management**: Manages event-specific data and financing structures.
     - **Royalty Management**: Sets and manages default and exception royalties for NFTs.
     - **Batch Actions**: Supports batch processing of ticket actions to optimize gas usage and streamline operations.

     The contract interacts with various interfaces and abstract contracts to ensure secure and efficient operations, including `IRegistry`, `IRouterRegistry`, `IFuelRouter`, and `IAuth`.

     - **Functions**:
          - `batchActions(TicketAction[] calldata _ticketActions, uint8[] calldata _actionCounts, BalanceUpdates[] calldata _balanceUpdates)`: Performs batch ticket actions via an integrator's relayer.
          - `batchActionsFromFactory(TicketAction[] calldata _ticketActions, uint8[] calldata _actionCounts, BalanceUpdates[] calldata _balanceUpdates, address _msgSender)`: Performs batch ticket actions via the `EventFactory` contract.
          - `setEventData(EventData calldata _eventData)`: Sets the event data for the contract.
          - `updateEventData(EventData calldata _eventData)`: Updates the event data for the contract.
          - `setTokenRoyaltyDefault(address _royaltyReceiver, uint96 _feeNumerator)`: Sets the default royalty for all NFTs of the event.
          - `setTokenRoyaltyException(uint256 _tokenId, address _receiver, uint96 _feeNominator)`: Sets an exception royalty for a specific NFT.
          - `deleteRoyaltyInfoDefault()`: Deletes the default royalty info.
          - `deleteRoyaltyException(uint256 _tokenId)`: Deletes the royalty info of a specific NFT.
          - `setFinancing(EventFinancing calldata _financing)`: Updates the event financing struct.
          - `tokenURI(uint256 _tokenId)`: Returns the token URI.
          - `returnEventData()`: Returns the event data.
          - `returnEventFinancing()`: Returns the event financing struct.
          - `transferFrom(address _from, address _to, uint256 _tokenId)`: Transfers a ticket, ensuring it is unlocked.
          - `safeTransferFrom(address _from, address _to, uint256 _tokenId)`: Safely transfers a ticket, ensuring it is unlocked.
          - `safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data)`: Safely transfers a ticket with additional data, ensuring it is unlocked.
          - `owner()`: Returns the contract owner for marketplace configuration.

     The `EventImplementation` contract is deployed and managed by the `EventFactory` contract, which handles the deployment and initialization of each event-specific contract using the Beacon Proxy pattern.

     ### FuelRouterWL.sol

- **FuelRouterWL**: This contract is a specialized fuel router for whitelabel integrators within the OPN Ticketing Ecosystem. It extends the `FuelRouter` abstract contract and is used to manage fuel (denominated in $OPN) for primary and secondary ticket sales. Key functionalities include:

     - **Integrator Configuration**: Initializes with specific integrator ID and dynamic rate configurations for primary and secondary sales.
     - **Primary and Secondary Sale Rates**: Allows setting upper and lower boundaries for primary and secondary sale rates, including minimum fee, maximum fee, and dynamic rate percentage.
     - **Fuel Routing**: Routes fuel for primary and secondary sales, ensuring that fees are correctly allocated to protocol, treasury, and stakers.
     - **Authorization and Security**: Utilizes authorization modifiers to restrict access to certain functions and ensure secure operations.

     The contract interacts with various interfaces and abstract contracts to ensure secure and efficient operations, including `IEventImplementation`, `IEconomicsFactory`, `IEconomicsImplementation`, and `IFuelRouterWL`.

     - **Functions**:
          - `setPrimaryRateProduct(uint64 _minFeeValue, uint64 _maxFeeValue, uint64 _rateDynamic)`: Sets the primary sale rate product configuration.
          - `setSecondaryRateProduct(uint64 _minFeeValue, uint64 _maxFeeValue, uint64 _rateDynamic)`: Sets the secondary sale rate product configuration.
          - `routeFuelForPrimarySale(IEventImplementation.TicketAction[] calldata _ticketActions)`: Routes fuel for primary sales.
          - `routeFuelForSecondarySale(IEventImplementation.TicketAction[] calldata _ticketActions)`: Routes fuel for secondary sales.
          - `setMintBaseRate(uint256 _baseRate)`: Sets the base rate for minting.
          - `settreasuryRate(uint256 treasuryRate_)`: Sets the treasury rate.
          - `returnPrimaryRateProduct()`: Returns the primary sale rate product configuration.
          - `returnSecondaryRateProduct()`: Returns the secondary sale rate product configuration.

     The contract ensures that integrators can manage their fuel efficiently and securely, with clear configurations for primary and secondary sales.

     ### FuelRouterDT.sol

- **FuelRouterDT**: This contract is a specialized fuel router for digital twin integrators within the OPN Ticketing Ecosystem. It extends the `FuelRouter` abstract contract and is used to manage fuel (denominated in $OPN) for primary ticket sales. Key functionalities include:

     - **Integrator Configuration**: Initializes with a specific integrator ID and dynamic rate configurations for primary sales.
     - **Primary Sale Rates**: Allows setting upper and lower boundaries for primary sale rates, including minimum fee, maximum fee, and dynamic rate percentage.
     - **Fuel Routing**: Routes fuel for primary sales, ensuring that fees are correctly allocated to protocol and treasury.
     - **Authorization and Security**: Utilizes authorization modifiers to restrict access to certain functions and ensure secure operations.

     The contract interacts with various interfaces and abstract contracts to ensure secure and efficient operations, including `IEventImplementation`, `IEconomicsFactory`, `IEconomicsImplementation`, and `IFuelRouterDT`.

     - **Functions**:
          - `setPrimaryRateProduct(uint64 _minFeeValue, uint64 _maxFeeValue, uint64 _rateDynamic)`: Sets the primary sale rate product configuration.
          - `routeFuelForPrimarySale(IEventImplementation.TicketAction[] calldata _ticketActions)`: Routes fuel for primary sales.
          - `setMintBaseRate(uint256 _baseRate)`: Sets the base rate for minting.
          - `returnPrimaryRateProduct()`: Returns the primary sale rate product configuration.

     The contract ensures that integrators can manage their fuel efficiently and securely, with clear configurations for primary sales.

     ### RouterRegistry.sol

- **RouterRegistry**: This contract serves as a registry for integrator routers within the OPN Ticketing Ecosystem. It manages the registration and configuration of routers that handle fuel transactions for events. Key functionalities include:

     - **Router Management**: Registers new routers, replaces existing routers, and maintains a mapping of router addresses to their information.
     - **Default Router Configuration**: Sets and retrieves the default router for each integrator.
     - **Event to Router Mapping**: Maps events to their respective routers, ensuring that each event is associated with the correct router for fuel transactions.
     - **Authorization and Security**: Utilizes authorization modifiers to restrict access to certain functions and ensure secure operations.

     The contract interacts with various interfaces and abstract contracts to ensure secure and efficient operations, including `IRegistry`, `IEconomicsFactory`, `IEventImplementation`, and `IFuelRouter`.

     - **Functions**:
          - `setDefaultRouter(uint256 _integratorIndex, address _routerAddress)`: Sets the default router for a specific integrator.
          - `isRouterRegistered(address _routerAddress)`: Checks if a router is registered.
          - `registerNewRouter(address _routerAddress, RouterInfo memory _newRouterInfo)`: Registers a new router with the provided information.
          - `replaceRouter(uint256 _routerIndex, address _routerAddress, RouterInfo memory _newRouterInfo)`: Replaces an existing router with a new one.
          - `registerEventToDefaultRouter(address _eventAddress, address _relayerAddress)`: Registers an event to the default router of the integrator.
          - `registerEventToCustomRouter(address _eventAddress, uint256 _routerIndex)`: Registers an event to a custom router specified by its index.
          - `returnEventToRouter(address _eventAddress, address _relayerAddress)`: Returns the router address associated with a specific event.

     The contract ensures that integrators can manage their routers efficiently and securely, with clear configurations for event-to-router mappings.

     ### TopUp.sol

- **TopUp**: This contract is responsible for managing integrator fuel top-ups within the OPN Ticketing Ecosystem. It supports both custodial and non-custodial top-ups. Key functionalities include:

     - **Custodial Top-Up**: Allows integrators to top up their fuel using a custodial method where fiat USD is swapped for USDC, which is then swapped for $OPN.
     - **Non-Custodial Top-Up**: Allows integrators to directly top up their fuel with $OPN.
     - **Token Swapping**: Utilizes the Uniswap V3 SwapRouter for token swaps and supports 0x Protocol for ERC20 token swaps.
     - **Authorization and Security**: Utilizes authorization modifiers to restrict access to certain functions and includes pausable functionality to halt operations if needed.

     The contract interacts with various interfaces and abstract contracts to ensure secure and efficient operations, including `IRegistry`, `IPriceOracle`, `ISwapRouter`, and `ITopUp`.

     - **Functions**:
          - `topUpCustodial(uint32 _integratorIndex, uint256 _amountIn, uint256 _amountOutMin, bytes32 _externalId)`: Performs a custodial top-up by swapping USDC for $OPN.
          - `topUpCustodial0x(uint32 _integratorIndex, bytes32 _externalId, address _spender, address payable _swapTarget, bytes calldata _swapCallData)`: Performs a custodial top-up using the 0x Protocol for token swaps.
          - `topUpNonCustodial(uint32 _integratorIndex, uint256 _amountFuel)`: Performs a non-custodial top-up directly with $OPN.
          - `pause()`: Pauses the contract.
          - `unpause()`: Unpauses the contract.
          - `setBaseToken(address _baseToken)`: Sets the address of the base token used in custodial top-ups.
          - `setWeth(address _weth)`: Sets the address for WETH used in custodial top-ups.
          - `setRouter(address _router)`: Sets the address for the SwapRouter contract.
          - `setApprovals()`: Gives maximum allowance for $OPN on the Economics contract.

     The contract ensures that integrators can manage their fuel top-ups efficiently and securely, with support for both custodial and non-custodial methods.

     ### Registry.sol

- **Registry**: This contract serves as a central registry for protocol-wide global variables within the OPN Ticketing Ecosystem. It manages the addresses of various key contracts and global settings. Key functionalities include:

     - **Contract Address Management**: Stores and updates addresses for key contracts such as `Auth`, `PriceOracle`, `TopUp`, `RouterRegistry`, `EconomicsFactory`, `EventFactory`, `FuelCollector`, and `StakingBalanceOracle`.
     - **Global Settings**: Manages global settings such as the base URI, protocol fee destination, treasury fee destination, staking contract address, and fuel bridge receiver address.
     - **Authorization and Security**: Utilizes authorization modifiers to restrict access to certain functions and includes upgradeability support using the UUPS (Universal Upgradeable Proxy Standard) pattern.

     The contract interacts with various interfaces and abstract contracts to ensure secure and efficient operations, including `IAuth`, `IPriceOracle`, `ITopUp`, `IRouterRegistry`, `IEconomicsFactory`, `IEventFactory`, `IFuelCollector`, and `IStakingBalanceOracle`.

     - **Functions**:
          - `setAuth(address _auth)`: Sets the Auth contract address.
          - `setPriceOracle(address _priceOracle)`: Sets the PriceOracle contract address.
          - `setStakingBalanceOracle(address _stakingBalanceOracle)`: Sets the StakingBalanceOracle contract address.
          - `setRouterRegistry(address _routerRegistry)`: Sets the RouterRegistry contract address.
          - `setEconomicsFactory(address _economicsFactory)`: Sets the EconomicsFactory contract address.
          - `setEventFactory(address _eventFactoryV2)`: Sets the EventFactory contract address.
          - `setTopUp(address _topUp)`: Sets the TopUp contract address.
          - `setFuelCollector(address _fuelCollector)`: Sets the FuelCollector contract address.
          - `setBaseURI(string memory _baseURI)`: Sets the base URI used to derive a token's URI on an EventImplementation contract.
          - `setProtocolFeeDestination(address _feeDestination)`: Sets the protocol fee destination address.
          - `setTreasuryFeeDestination(address _feeDestination)`: Sets the treasury fee destination address.
          - `setStakingContractAddress(address _contractAddress)`: Sets the staking contract address.
          - `setFuelBridgeReceiverAddress(address _fuelBridgeReceiverAddress)`: Sets the fuel bridge receiver address.

     The contract ensures that the protocol's global variables and key contract addresses are managed efficiently and securely.

     ## Fifo pricing of fuel topups with PricingFIFO.sol

- **PricingFIFO**: This abstract contract provides the logic for managing fuel top-ups and usage within the OPN Ticketing Ecosystem using a First-In-First-Out (FIFO) pricing mechanism. It is designed to handle the complexities of fuel token accounting, ensuring that fuel tokens are used in the order they are topped up.

     - **Fuel Management**: Manages all integrator top-ups in a FIFO queue, ensuring that older fuel is used before newer fuel.
     - **Overdraft Handling**: Supports handling of overdraft situations where integrators can continue operations even when their fuel balance is negative, with appropriate mechanisms to repay the overdraft upon subsequent top-ups.
     - **Tick Management**: Utilizes a tick system where each top-up creates a new tick, and fuel usage is tracked per tick.

     The contract is crucial for maintaining a transparent and fair usage system for fuel tokens, ensuring that integrators are charged correctly based on their fuel top-up history.

### Integration with EconomicsImplementation and TopUp

The `PricingFIFO` contract plays a central role in the `EconomicsImplementation` contract, which is responsible for all accounting operations per integrator within the ecosystem. It ensures that fuel tokens are accounted for and used in a FIFO manner, which is critical for accurate financial reporting and management.

When integrators use the `TopUp` contract to add fuel, `PricingFIFO` ensures that these top-ups are processed and priced correctly. Each top-up is added as a new tick in the FIFO queue, and the pricing information from each top-up is used to manage fuel usage effectively. This integration ensures that the fuel added through `TopUp` is utilized in the order it was received and priced according to the specific top-up conditions at the time of the transaction.

This systematic approach helps maintain consistency and fairness in fuel usage across the ecosystem, providing a robust framework for managing the economics of fuel token distribution and usage.
