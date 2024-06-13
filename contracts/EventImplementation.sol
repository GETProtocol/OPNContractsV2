// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @title EventImplementation Contract
 * @author Open Ticketing Ecosystem
 * @notice Contract responsible for NFT mints and transfers
 * @dev One EventImplementation contract is deployed per real world event.
 *
 * @dev This contract Extends the ERC721 specification
 */

import { EventERC721Upgradeable, StringsUpgradeable } from "./abstract/EventERC721Upgradeable.sol";
import { AuthModifiers } from "./abstract/AuthModifiers.sol";
import { IEventImplementation } from "./interfaces/IEventImplementation.sol";
import { IRouterRegistry } from "./interfaces/IRouterRegistry.sol";
import { IFuelRouter } from "./interfaces/IFuelRouter.sol";
import { IRegistry } from "./interfaces/IRegistry.sol";

contract EventImplementation is IEventImplementation, EventERC721Upgradeable, AuthModifiers {
    using StringsUpgradeable for uint256;

    IRegistry private registry;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /**
     * @dev Initialization function for beacon proxy contracts
     * @param _name_ ERC721 name field
     * @param _symbol_ ERC721 symbol field
     * @param _registry Registry contract address
     */
    // solhint-disable-next-line func-name-mixedcase
    function __EventImplementationV2_init(
        string calldata _name_, // to avoid variable shadowing
        string calldata _symbol_, // to avoid variable shadowing
        address _registry
    ) external initializer {
        __ERC721_init(_name_, _symbol_);
        __AuthModifiers_init(_registry);
        __EventImplementation_init_unchained(_registry);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __EventImplementation_init_unchained(address _registry) internal initializer {
        registry = IRegistry(_registry);
    }

    EventData public eventData;
    EventFinancing public eventFinancing;

    /**
     * @notice Performs all ticket interractions via an integrator's relayer
     * @dev Performs ticket actions based on the array of action counts
     *
     * @dev Each value in the actionCounts array corresponds to the number of a specific ticket action to be performed
     *
     * @dev Can only be called by an integrator's relayer
     * @param _ticketActions array of TicketAction structs for which a ticket action is performed
     * @param _actionCounts integer array corresponding to specific ticket action to be performed on the ticketActions
     * @param _balanceUpdates array of BalanceUpdates struct used to update an owner's balance upon ticket mint
     */
    function batchActions(
        TicketAction[] calldata _ticketActions,
        uint8[] calldata _actionCounts,
        BalanceUpdates[] calldata _balanceUpdates
    ) external onlyRelayer {
        _batchActions(_ticketActions, _actionCounts, _balanceUpdates, msg.sender);
    }

    /**
     * @notice Performs all ticket interractions via EventFactory contract
     * @dev Performs ticket actions based on the array of action counts
     *
     * @dev Each value in the actionCounts array corresponds to the number of a specific ticket action to be performed
     *
     * @dev Can only be called by an EventFactory contract
     * @param _ticketActions array of TicketAction structs for which a ticket action is performed
     * @param _actionCounts integer array corresponding to specific ticket action to be performed on the ticketActions
     * @param _balanceUpdates array of BalanceUpdates struct used to update an owner's balance upon ticket mint
     */
    function batchActionsFromFactory(
        TicketAction[] calldata _ticketActions,
        uint8[] calldata _actionCounts,
        BalanceUpdates[] calldata _balanceUpdates,
        address _msgSender
    ) external onlyEventFactory {
        _batchActions(_ticketActions, _actionCounts, _balanceUpdates, _msgSender);
    }

    // solhint-disable-next-line code-complexity
    function _batchActions(
        TicketAction[] calldata _ticketActions,
        uint8[] calldata _actionCounts,
        BalanceUpdates[] calldata _balanceUpdates,
        address _msgSender
    ) internal {
        // Consider storing the router address in the events state/storage (not immutable) to save gas
        IRouterRegistry _routerRegistry = IRouterRegistry(registry.routerRegistry());

        IFuelRouter _router = IFuelRouter(_routerRegistry.returnEventToRouter(address(this), _msgSender));

        uint256 _start = 0;

        for (uint256 _actionType = 0; _actionType < _actionCounts.length; ++_actionType) {
            uint256 _end = _start + _actionCounts[_actionType];

            if (_actionCounts[_actionType] != 0) {
                if (_actionType == 0) {
                    require(!eventFinancing.primaryBlocked, "EventFinancing: Inventory Restricted");
                    _primarySale(_ticketActions[_start:_end], _balanceUpdates, _router);
                } else if (_actionType == 1) {
                    _secondarySale(_ticketActions[_start:_end], _router);
                } else if (_actionType == 2) {
                    require(!eventFinancing.scanBlocked, "EventFinancing: Inventory Restricted");
                    _scan(_ticketActions[_start:_end]);
                } else if (_actionType == 3) {
                    _checkIn(_ticketActions[_start:_end]);
                } else if (_actionType == 4) {
                    _invalidate(_ticketActions[_start:_end]);
                } else if (_actionType == 5) {
                    _claim(_ticketActions[_start:_end]);
                } else if (_actionType == 6) {
                    _transfer(_ticketActions[_start:_end]);
                }
                _start = _end;
            }
        }
    }

    /**
     * @notice Returns a boolean from a bit-field
     * @param _packedBools integer used as bit field
     * @param _boolNumber bit position
     */
    function _getBoolean(uint8 _packedBools, uint8 _boolNumber) internal pure returns (bool) {
        uint8 _flag = (_packedBools >> _boolNumber) & uint8(1);
        return (_flag == 1 ? true : false);
    }

    /**
     * @notice Sets a bit in a bit-field
     * @param _packedBools integer used as bit field
     * @param _boolNumber bit position
     * @param _value boolean value to set in bit position
     */
    function _setBoolean(uint8 _packedBools, uint8 _boolNumber, bool _value) internal pure returns (uint8) {
        unchecked {
            return _value ? _packedBools | (uint8(1) << _boolNumber) : _packedBools & ~(uint8(1) << _boolNumber);
        }
    }

    /**
     * @notice Returns a ticket's scanned status
     * @dev A ticket can be scanned multiple times as long as it's not invalidated
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @return _status scan status
     */
    function isScanned(uint256 _tokenId) public view returns (bool _status) {
        return _isScanned(_tokenId);
    }

    function _isScanned(uint256 _tokenId) internal view returns (bool _status) {
        return _getBoolean(tokenData[_tokenId].booleanFlags, uint8(TicketFlags.SCANNED));
    }

    /**
     * @notice Returns a ticket's checked-in status
     * @dev A ticket can only be checked in once
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @return _status check-in status
     */
    function isCheckedIn(uint256 _tokenId) public view returns (bool _status) {
        return _isCheckedIn(_tokenId);
    }

    function _isCheckedIn(uint256 _tokenId) internal view returns (bool _status) {
        return _getBoolean(tokenData[_tokenId].booleanFlags, uint8(TicketFlags.CHECKED_IN));
    }

    /**
     * @notice Returns a ticket's invalidation status
     * @dev After invalidation further ticket interraction becomes impossible
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @return _status invalidation status
     */
    function isInvalidated(uint256 _tokenId) public view returns (bool _status) {
        return _isInvalidated(_tokenId);
    }

    function _isInvalidated(uint256 _tokenId) internal view returns (bool _status) {
        return _getBoolean(tokenData[_tokenId].booleanFlags, uint8(TicketFlags.INVALIDATED));
    }

    /**
     * @notice Returns a ticket's status of unlocked
     * @dev Unlocking happens after check-in, at which point the ticket is available for transfer
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @return _status unlock status
     */
    function isUnlocked(uint256 _tokenId) public view returns (bool _status) {
        bool _isPastEndTime = (eventData.endTime + 24 hours) <= block.timestamp;
        bool _isZeroEndTime = eventData.endTime == 0;
        return
            _getBoolean(tokenData[_tokenId].booleanFlags, uint8(TicketFlags.UNLOCKED)) ||
            (_isPastEndTime && !_isZeroEndTime);
    }

    /**
     * @notice Sets `isScanned` to true or false
     * @dev This edits the ticket specific bit-field (tokenData.booleanFlags) by calling _setBoolean
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @param _status scan status
     */
    function _setScannedFlag(uint256 _tokenId, bool _status) internal {
        tokenData[_tokenId].booleanFlags = _setBoolean(
            tokenData[_tokenId].booleanFlags,
            uint8(TicketFlags.SCANNED),
            _status
        );
    }

    /**
     * @notice Sets `isCheckedIn` to true or false
     * @dev This edits the ticket specific bit-field (tokenData.booleanFlags) by calling _setBoolean
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @param _status check-in status
     */
    function _setCheckedInFlag(uint256 _tokenId, bool _status) internal {
        tokenData[_tokenId].booleanFlags = _setBoolean(
            tokenData[_tokenId].booleanFlags,
            uint8(TicketFlags.CHECKED_IN),
            _status
        );
    }

    /**
     * @notice Sets `isInvalidated` to true or false
     * @dev This edits the ticket specific bit-field (tokenData.booleanFlags) by calling _setBoolean
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @param _status invalidation status
     */
    function _setInvalidatedFlag(uint256 _tokenId, bool _status) internal {
        tokenData[_tokenId].booleanFlags = _setBoolean(
            tokenData[_tokenId].booleanFlags,
            uint8(TicketFlags.INVALIDATED),
            _status
        );
    }

    /**
     * @notice Sets `isUnlocked` to true or false
     * @dev This edits the ticket specific bit-field (tokenData.booleanFlags) by calling _setBoolean
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @param _status unlocked status
     */
    function _setUnlockedFlag(uint256 _tokenId, bool _status) internal {
        tokenData[_tokenId].booleanFlags = _setBoolean(
            tokenData[_tokenId].booleanFlags,
            uint8(TicketFlags.UNLOCKED),
            _status
        );
    }

    /// @dev Ticket Lifecycle Methods

    /**
     * @notice Performs a primary ticket sale from ticketActions
     * @dev Internal method called by `batchActions`
     * @param _ticketActions array of TicketAction structs for which a primary sale occurs
     * @param _balanceUpdates array of BalanceUpdates struct used to update an owner's balance
     */
    function _primarySale(
        TicketAction[] calldata _ticketActions,
        BalanceUpdates[] calldata _balanceUpdates,
        IFuelRouter _router
    ) internal {
        for (uint256 i = 0; i < _balanceUpdates.length; ++i) {
            unchecked {
                _addressData[_balanceUpdates[i].owner].balance += _balanceUpdates[i].quantity;
            }
        }

        for (uint256 i = 0; i < _ticketActions.length; ++i) {
            _mint(_ticketActions[i]);
        }

        (uint256 _totalFuel, uint256 _protocolFuel, uint256 _totalFuelUSD, uint256 _protocolFuelUSD) = _router
            .routeFuelForPrimarySale(_ticketActions);

        emit PrimarySale(_ticketActions, _totalFuel, _protocolFuel, _totalFuelUSD, _protocolFuelUSD);
    }

    /**
     * @notice Performs a secondary ticket sale from ticketActions
     * @dev Internal method called by `batchActions`
     * @param _ticketActions array of TicketAction structs for which a secondary sale occurs
     */
    function _secondarySale(TicketAction[] calldata _ticketActions, IFuelRouter _router) internal {
        for (uint256 i = 0; i < _ticketActions.length; ++i) {
            uint256 _tokenId = _ticketActions[i].tokenId;
            require(!isInvalidated(_tokenId), "EventImplementation: Error on resale");
            require(!isUnlocked(_tokenId), "EventImplementation: Error on resale");
            _transfer(ownerOf(_tokenId), _ticketActions[i].to, _tokenId);
        }

        (uint256 _totalFuel, uint256 _protocolFuel, uint256 _totalFuelUSD, uint256 _protocolFuelUSD) = _router
            .routeFuelForSecondarySale(_ticketActions);

        // note: it would be possible to also emit the USD value of the deducted
        // fuel (denominated in the value of the fuel in the economics FIFO valuation)
        emit SecondarySale(_ticketActions, _totalFuel, _protocolFuel, _totalFuelUSD, _protocolFuelUSD);
    }

    /**
     * @notice Performs scans on tickets from ticketActions
     * @dev Internal method called by `batchActions`
     * @param _ticketActions array of TicketAction structs for which scans occur
     */
    function _scan(TicketAction[] calldata _ticketActions) internal {
        for (uint256 i = 0; i < _ticketActions.length; ++i) {
            uint256 _tokenId = _ticketActions[i].tokenId;
            require(!_isInvalidated(_tokenId), "EventImplementation: Error on ticket scan");
            _setScannedFlag(_tokenId, true);
        }

        emit Scanned(_ticketActions, 0, 0);
    }

    /**
     * @notice Performs check-ins on tickets from ticketActions
     * @dev Internal method called by `batchActions`
     * @param _ticketActions array of TicketAction structs for which check-ins occur
     */
    function _checkIn(TicketAction[] calldata _ticketActions) internal {
        for (uint256 i = 0; i < _ticketActions.length; ++i) {
            uint256 _tokenId = _ticketActions[i].tokenId;
            require(!isInvalidated(_tokenId), "EventImplementation: Error on check-in");
            require(!isCheckedIn(_tokenId), "EventImplementation: Error on check-in");
            _setCheckedInFlag(_tokenId, true);
            _setUnlockedFlag(_tokenId, true);
        }

        emit CheckedIn(_ticketActions, 0, 0);
    }

    /**
     * @notice Performs invalidations on tickets from ticketActions
     * @dev Internal method called by `batchActions`
     * @param _ticketActions array of TicketAction structs for which invalidadtions occur
     */
    function _invalidate(TicketAction[] calldata _ticketActions) internal {
        for (uint256 i = 0; i < _ticketActions.length; ++i) {
            uint256 _tokenId = _ticketActions[i].tokenId;
            require(!isInvalidated(_tokenId), "EventImplementation: Error on ticket invalidation");
            _setInvalidatedFlag(_tokenId, true);
            _burn(_tokenId);
        }

        emit Invalidated(_ticketActions, 0, 0);
    }

    /**
     * @notice Performs claims on tickets from ticketActions
     * @dev Internal method called by `batchActions`
     * @param _ticketActions array of TicketAction structs for which claims occur
     */
    function _claim(TicketAction[] calldata _ticketActions) internal {
        for (uint256 i = 0; i < _ticketActions.length; ++i) {
            uint256 _tokenId = _ticketActions[i].tokenId;
            require(!isInvalidated(_tokenId), "EventImplementation: Error on NFT claim");
            _transfer(ownerOf(_tokenId), _ticketActions[i].to, _tokenId);
        }
        emit Claimed(_ticketActions);
    }

    /**
     * @notice Performs transfers on tickets from custodial to non-custodial accounts
     * @dev Internal method called by `batchActions`
     * @param _ticketActions array of TicketAction structs for which transfers occur
     */
    function _transfer(TicketAction[] calldata _ticketActions) internal {
        for (uint256 i = 0; i < _ticketActions.length; i++) {
            uint256 _tokenId = _ticketActions[i].tokenId;
            require(!isInvalidated(_tokenId), "EventImplementation: Error on NFT transfer");
            _transfer(ownerOf(_tokenId), _ticketActions[i].to, _tokenId);
        }
        emit Transfered(_ticketActions);
    }

    /// @dev Event Lifecycle Methods
    /**
     * @notice Sets the event data for an EventImplementation contract
     * @dev can only be called by the EventFactory contract typically at contract creation
     * @param _eventData EventData struct
     */
    function setEventData(EventData calldata _eventData) external onlyEventFactory {
        eventData = _eventData;
        emit EventDataSet(_eventData);
    }

    /**
     * @notice Updates the event data for an EventImplementation contract
     * @dev can only be called by an integrator's relayer
     * @param _eventData EventData struct
     */
    function updateEventData(EventData calldata _eventData) external onlyRelayer {
        eventData = _eventData;
        emit EventDataUpdated(_eventData);
    }

    function setTokenRoyaltyDefault(address _royaltyReceiver, uint96 _feeNumerator) external onlyEventFactory {
        _setDefaultRoyalty(_royaltyReceiver, _feeNumerator);
    }

    function setTokenRoyaltyException(
        uint256 _tokenId,
        address _receiver,
        uint96 _feeNominator
    ) external onlyEventFactory {
        _setTokenRoyalty(_tokenId, _receiver, _feeNominator);
    }

    function deleteRoyaltyInfoDefault() external onlyEventFactory {
        _deleteDefaultRoyalty();
    }

    function deleteRoyaltyException(uint256 _tokenId) external onlyEventFactory {
        _resetTokenRoyalty(_tokenId);
    }

    /**
     * @notice Updates the EventFinancing struct
     * @dev can only be called by the EventFactory contract
     * @param _financing EventFinancing struct
     */
    function setFinancing(EventFinancing calldata _financing) external onlyEventFactory {
        eventFinancing = _financing;
        emit UpdateFinancing(_financing);
    }

    /// @dev ERC-721 Overrides

    /**
     * @notice Returns the token URI
     * @dev The token URI is resolved from the _baseURI, event index and tokenId
     * @param _tokenId ticket identifier and ERC721 tokenId
     * @return _tokenURI token URI
     */
    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory _uri = _baseURI();
        return
            bytes(_uri).length > 0
                ? string(abi.encodePacked(_uri, uint256(eventData.index).toString(), "/", _tokenId.toString()))
                : "";
    }

    /**
     * @notice Returns base URI
     * @dev The baseURI at any time is universal across all EventImplementation contracts
     * @return _baseURI token URI
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return registry.baseURI();
    }

    /**
     * @notice returns event data
     */
    function returnEventData() external view returns (EventData memory) {
        return eventData;
    }

    /**
     * @notice returns event financing struct
     */
    function returnEventFinancing() external view returns (EventFinancing memory) {
        return eventFinancing;
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) public virtual override {
        require(isUnlocked(_tokenId), "EventImplementation: ticket must be unlocked");
        return super.transferFrom(_from, _to, _tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) public virtual override {
        require(isUnlocked(_tokenId), "EventImplementation: ticket must be unlocked");
        return super.safeTransferFrom(_from, _to, _tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual override {
        require(isUnlocked(_tokenId), "EventImplementation: ticket must be unlocked");
        return super.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    /**
     * @notice Returns contract owner
     * @dev Not a full Ownable implementation, used to return a static owner for marketplace config only
     * @return _owner owner address
     */
    function owner() public view virtual returns (address) {
        return address(0x3aFdff6fCDD01E7DA59c615D3958C5fEc0e889Fd);
    }
}
