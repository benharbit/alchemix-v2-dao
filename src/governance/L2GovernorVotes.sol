// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (governance/extensions/GovernorVotes.sol)

pragma solidity ^0.8.0;

import { L2Governor } from "src/governance/L2Governor.sol";
import "openzeppelin-contracts/contracts/governance/utils/IVotes.sol";

/**
 * @author Modified from RollCall (https://github.com/withtally/rollcall/blob/main/src/standards/L2GovernorVotes.sol)
 *
 * @dev Extension of {Governor} for voting weight extraction from an {ERC20Votes} token, or since v4.5 an {ERC721Votes} token.
 *
 * _Available since v4.3._
 */
abstract contract L2GovernorVotes is L2Governor {
    IVotes public immutable token;

    constructor(IVotes tokenAddress) {
        token = tokenAddress;
    }

    /**
     * Read the voting weight from the token's built in snapshot mechanism (see {Governor-_getVotes}).
     */
    function _getVotes(
        address account,
        uint256 blockTimestamp,
        bytes memory /*params*/
    ) internal view virtual override returns (uint256) {
        return token.getPastVotes(account, blockTimestamp);
    }
}
