// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

import { Message } from "./IMessage.sol";

interface IMessageDispatcher {
    event MessageDispatched(
        bytes32 indexed messageId,
        address indexed from,
        uint256 indexed toChainId,
        address to,
        bytes data
    );

    function dispatchMessage(uint256 toChainId, address to, bytes calldata data) external returns (bytes32);
}
