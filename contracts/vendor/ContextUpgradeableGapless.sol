// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.4) (utils/Context.sol)

pragma solidity ^0.8.4;
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeableGapless is Initializable {
    // solhint-disable-next-line func-name-mixedcase
    function __Context_init() internal onlyInitializing {}

    // solhint-disable-next-line func-name-mixedcase
    function __Context_init_unchained() internal onlyInitializing {}

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _contextSuffixLength() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     *
     * @dev (!!) Note that due to the change of inheritance chain of EventImplementation
     * we have had to remove the storage gap from ContextUpgradeable. ERC2981Upgradeable has
     * been added which introduces a gap of 50 and the safest place to remove this is from
     * ContextUpgradeable as this is unlikely to ever receive a local varaible. As a result
     * we must always use this version of ContextUpgradeable for the ERC721 inheritance and
     * never the one directly from OpenZeppelin.
     */
    // uint256[50] private __gap;
}
