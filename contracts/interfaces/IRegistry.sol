// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { IAuth } from "./IAuth.sol";
import { IEventFactory } from "./IEventFactory.sol";
import { IPriceOracle } from "./IPriceOracle.sol";
import { IRegistry } from "./IRegistry.sol";
import { IEconomicsFactory } from "./IEconomicsFactory.sol";
import { IRouterRegistry } from "./IRouterRegistry.sol";
import { ITopUp } from "./ITopUp.sol";
import { IFuelCollector } from "./IFuelCollector.sol";
import { IStakingBalanceOracle } from "./IStakingBalanceOracle.sol";

interface IRegistry {
    event UpdateAuth(address old, address updated);
    event UpdateEconomics(address old, address updated);
    event UpdateEventFactory(address old, address updated);
    event UpdatePriceOracle(address old, address updated);
    event UpdateStakingBalanceOracle(address old, address updated);
    event UpdateTopUp(address old, address updated);
    event UpdateBaseURI(string old, string updated);
    event UpdateRouterRegistry(address old, address updated);
    event UpdateEconomicsFactory(address oldEconomicsFactory, address economicsFactory);
    event UpdateEventFactoryV2(address oldEventFactoryV2, address newEventFactoryV2);
    event UpdateFuelCollector(address oldFuelCollector, address newFuelCollector);
    event UpdateProtocolFeeDestination(address feeDestination);
    event UpdateTreasuryFeeDestination(address feeDestination);
    event UpdateFuelBridgeReceiverAddress(address fuelBridgeReceiverAddress);
    event UpdateStakingContractAddress(address stakingContractAddress);

    function auth() external view returns (IAuth);

    function eventFactory() external view returns (IEventFactory);

    function economicsFactory() external view returns (IEconomicsFactory);

    function routerRegistry() external view returns (IRouterRegistry);

    function priceOracle() external view returns (IPriceOracle);

    function stakingBalanceOracle() external view returns (IStakingBalanceOracle);

    function topUp() external view returns (ITopUp);

    function fuelCollector() external view returns (IFuelCollector);

    function baseURI() external view returns (string memory);

    function protocolFeeDestination() external view returns (address);

    function treasuryFeeDestination() external view returns (address);

    function fuelBridgeReceiverAddress() external view returns (address);

    function stakingContractAddress() external view returns (address);

    function setAuth(address _auth) external;

    function setEventFactory(address _eventFactory) external;

    function setPriceOracle(address _priceOracle) external;

    function setStakingBalanceOracle(address _stakingBalanceOracle) external;

    function setTopUp(address _topUp) external;

    function setBaseURI(string memory _baseURI) external;

    function setRouterRegistry(address _routerRegistry) external;

    function setEconomicsFactory(address _economicsFactory) external;

    function setProtocolFeeDestination(address _feeDestination) external;

    function setTreasuryFeeDestination(address _feeDestination) external;

    function setStakingContractAddress(address _contractAddress) external;

    function setFuelBridgeReceiverAddress(address _fuelBridgeReceiverAddress) external;

    function setFuelCollector(address _fuelCollector) external;
}
