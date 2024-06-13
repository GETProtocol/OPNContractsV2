// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IEventImplementation {
    enum TicketFlags {
        SCANNED, // 0
        CHECKED_IN, // 1
        INVALIDATED, // 2
        UNLOCKED // 3
    }

    struct BalanceUpdates {
        address owner;
        uint64 quantity;
    }

    struct TokenData {
        address owner;
        uint40 basePrice;
        uint8 booleanFlags;
    }

    struct AddressData {
        // uint64 more than enough
        uint64 balance;
    }

    struct EventData {
        uint32 index;
        uint64 startTime;
        uint64 endTime;
        int32 latitude;
        int32 longitude;
        string currency;
        string name;
        string shopUrl;
        string imageUrl;
    }

    struct TicketAction {
        uint256 tokenId;
        bytes32 externalId; // sha256 hashed, emitted in event only.
        address to;
        uint64 orderTime;
        uint40 basePrice;
    }

    struct EventFinancing {
        uint64 palletIndex;
        address bondCouncil;
        bool inventoryRegistered;
        bool financingActive;
        bool primaryBlocked;
        bool secondaryBlocked;
        bool scanBlocked;
        bool claimBlocked;
    }

    event PrimarySale(
        TicketAction[] ticketActions,
        uint256 fuelTokens,
        uint256 fuelTokensProtocol,
        uint256 fuelUSD,
        uint256 fuelUSDProtocol
    );

    event SecondarySale(
        TicketAction[] ticketActions,
        uint256 fuelTokens,
        uint256 fuelTokensProtocol,
        uint256 fuelUSD,
        uint256 fuelUSDProtocol
    );

    event Scanned(TicketAction[] ticketActions, uint256 fuelTokens, uint256 fuelTokensProtocol);

    event CheckedIn(TicketAction[] ticketActions, uint256 fuelTokens, uint256 fuelTokensProtocol);

    event Invalidated(TicketAction[] ticketActions, uint256 fuelTokens, uint256 fuelTokensProtocol);

    event Claimed(TicketAction[] ticketActions);

    event Transfered(TicketAction[] ticketActions);

    event EventDataSet(EventData eventData);

    event EventDataUpdated(EventData eventData);

    event UpdateFinancing(EventFinancing financing);

    function batchActions(
        TicketAction[] calldata _ticketActions,
        uint8[] calldata _actionCounts,
        BalanceUpdates[] calldata _balanceUpdates
    ) external;

    function batchActionsFromFactory(
        TicketAction[] calldata _ticketActions,
        uint8[] memory _actionCounts,
        BalanceUpdates[] calldata _balanceUpdates,
        address _msgSender
    ) external;

    function isScanned(uint256 _tokenId) external returns (bool _status);

    function isCheckedIn(uint256 _tokenId) external returns (bool _status);

    function isInvalidated(uint256 _tokenId) external returns (bool _status);

    function isUnlocked(uint256 _tokenId) external returns (bool _status);

    function setEventData(EventData memory _eventData) external;

    function updateEventData(EventData memory _eventData) external;

    function setFinancing(EventFinancing memory _financing) external;

    function owner() external view returns (address);

    function returnEventData() external view returns (EventData memory);

    function returnEventFinancing() external view returns (EventFinancing memory);

    function setTokenRoyaltyException(uint256 _tokenId, address _receiver, uint96 _feeNominator) external;

    function setTokenRoyaltyDefault(address _royaltyReceiver, uint96 _feeDenominator) external;

    function deleteRoyaltyInfoDefault() external;

    function deleteRoyaltyException(uint256 _tokenId) external;
}
