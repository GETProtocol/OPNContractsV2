// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title EventFactory Contract V2.1
 * @author Open Ticketing Ecosystem
 * @notice Contract responsible for deploying IEventImplementation contracts
 * @dev All EventImplementation contracts are deployed as Beacon Proxies
 */

import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import { AuthModifiers } from "./abstract/AuthModifiers.sol";
import { IAuth } from "./interfaces/IAuth.sol";
import { IEventFactory, IEventImplementation } from "./interfaces/IEventFactory.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";
import { IRouterRegistry } from "./interfaces/IRouterRegistry.sol";

contract EventFactory is IEventFactory, OwnableUpgradeable, AuthModifiers, UUPSUpgradeable {
    IRegistry private registry;
    UpgradeableBeacon public beacon;

    // event index => event address
    mapping(uint256 => address) public eventAddressByIndex;

    uint256 public eventCount;

    mapping(address => uint256) public eventIndexByAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Initialization function for proxy contract
     *
     * @dev A deployed EventImplementation contract is used as a beacon
     * @param _registry the Registry contract address
     * @param _implementation The EventImplementation contract address
     */
    // solhint-disable-next-line func-name-mixedcase
    function __EventFactoryV2_init(address _registry, address _implementation) public initializer {
        __Ownable_init();
        __AuthModifiers_init(_registry);
        __EventFactory_init_unchained(_registry, _implementation);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __EventFactory_init_unchained(address _registry, address _implementation) internal initializer {
        registry = IRegistry(_registry);

        beacon = new UpgradeableBeacon(_implementation);
        beacon.transferOwnership(msg.sender);
    }

    /**
     * @notice Deploys an EventImplementation contract (using the default router of the integrator)
     * @param _name ERC721 `name`
     * @param _symbol ERC721 `symbol`
     * @param _eventData EventData struct
     */
    function createEvent(
        string memory _name,
        string memory _symbol,
        IEventImplementation.EventData memory _eventData
    ) public onlyRelayer returns (address _eventAddress) {
        bytes memory _eventCalldata = abi.encodeWithSignature(
            "__EventImplementationV2_init(string,string,address)",
            _name,
            _symbol,
            address(registry)
        );

        _eventAddress = address(
            new BeaconProxy{ salt: bytes32(uint256(_eventData.index)) }(address(beacon), _eventCalldata)
        );

        IEventImplementation(_eventAddress).setEventData(_eventData);
        registry.auth().grantEventRole(_eventAddress);
        eventAddressByIndex[_eventData.index] = _eventAddress;
        eventIndexByAddress[_eventAddress] = _eventData.index;

        IRouterRegistry _routerRegistry = registry.routerRegistry();

        address _routerAddress = _routerRegistry.registerEventToDefaultRouter(_eventAddress, msg.sender);

        emit EventCreated(_eventData.index, _eventAddress);
        emit RouterInUse(_eventAddress, _routerAddress);

        unchecked {
            eventCount++;
        }
    }

    /**
     * @notice Deploys an EventImplementation contract (using a custom router)
     * @dev this is the function that would be called if
     * @param _name ERC721 `name`
     * @param _symbol ERC721 `symbol`
     * @param _eventData EventData struct
     * @param _routerIndex exception index of the router
     */
    function createEvent(
        string memory _name,
        string memory _symbol,
        IEventImplementation.EventData memory _eventData,
        uint256 _routerIndex
    ) public onlyRelayer returns (address _eventAddress) {
        bytes memory _eventCalldata = abi.encodeWithSignature(
            "__EventImplementationV2_init(string,string,address)",
            _name,
            _symbol,
            address(registry)
        );

        _eventAddress = address(
            new BeaconProxy{ salt: bytes32(uint256(_eventData.index)) }(address(beacon), _eventCalldata)
        );

        IEventImplementation(_eventAddress).setEventData(_eventData);
        registry.auth().grantEventRole(_eventAddress);
        eventAddressByIndex[_eventData.index] = _eventAddress;
        eventIndexByAddress[_eventAddress] = _eventData.index;

        IRouterRegistry _routerRegistry = registry.routerRegistry();

        address _routerAddress = _routerRegistry.registerEventToCustomRouter(_eventAddress, _routerIndex);

        emit EventCreated(_eventData.index, _eventAddress);
        emit RouterInUse(_eventAddress, _routerAddress);

        unchecked {
            eventCount++;
        }
    }

    /**
     * @notice manually set the event financing struct
     * @param _eventAddress address of the event
     * @param _financingStruct configuration of the financing struct
     */
    function setFinancingStructOfEvent(
        address _eventAddress,
        IEventImplementation.EventFinancing memory _financingStruct
    ) public onlyProtocolDAO {
        IEventImplementation(_eventAddress).setFinancing(_financingStruct);
    }

    /**
     * @notice set the royalty of all the nfts of the event (for secondary sales on marketplaces)
     * @param _eventAddress address of the event
     * @param _receiver recipient of the collected royalty
     * @param _feeNominator amount of the royalty of the secondary ale
     */
    function setDefaultTokenRoyalty(address _eventAddress, address _receiver, uint96 _feeNominator) public onlyRelayer {
        IEventImplementation(_eventAddress).setTokenRoyaltyDefault(_receiver, _feeNominator);
    }

    /**
     *
     * @param _eventAddress address of the event
     * @param _tokenId nftIndex of the ticket/token§
     * @param _receiver recipient address for the royalty
     * @param _feeNominator amount of royalty?
     */
    function setExceptionTokenRoyalty(
        address _eventAddress,
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNominator
    ) public onlyRelayer {
        IEventImplementation(_eventAddress).setTokenRoyaltyException(_tokenId, _receiver, _feeNominator);
    }

    /**
     * @notice deletes the royalty info of a specific nftIndex
     * @param _eventAddress address of the event
     * @param _tokenId nftIndex of the token to clear
     */
    function deleteRoyaltyException(address _eventAddress, uint256 _tokenId) public onlyRelayer {
        IEventImplementation(_eventAddress).deleteRoyaltyException(_tokenId);
    }

    /**
     * @notice deletes the default royalty info
     * @param _eventAddress address of the event
     */
    function deleteRoyaltyDefault(address _eventAddress) public onlyRelayer {
        IEventImplementation(_eventAddress).deleteRoyaltyInfoDefault();
    }

    /**
     * @notice returns the Event address of a particular event index
     * @param _eventIndex Index of event
     */
    function returnEventAddressByIndex(uint256 _eventIndex) external view returns (address) {
        return eventAddressByIndex[_eventIndex];
    }

    /**
     * @notice returns the Event index of a particular event address
     * @param _address Index of event
     */
    function returnEventIndexByAddress(address _address) external view returns (uint256) {
        return eventIndexByAddress[_address];
    }

    function batchActions(
        address[] calldata _eventAddressArray,
        IEventImplementation.TicketAction[][] calldata _ticketActionsArray,
        uint8[][] calldata _actionCountsArray,
        IEventImplementation.BalanceUpdates[][] calldata _balanceUpdatesArray
    ) external onlyRelayer {
        for (uint256 i; i < _eventAddressArray.length; i++) {
            IEventImplementation(_eventAddressArray[i]).batchActionsFromFactory(
                _ticketActionsArray[i],
                _actionCountsArray[i],
                _balanceUpdatesArray[i],
                msg.sender
            );
        }
    }

    /**
     * @notice An internal function to authorize a contract upgrade
     * @dev The function is a requirement for OpenZeppelin's UUPS upgradeable contracts
     *
     * @dev can only be called by the contract owner
     */
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
