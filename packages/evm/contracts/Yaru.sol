// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IYaru } from "./interfaces/IYaru.sol";
import { IHashi, IOracleAdapter } from "./interfaces/IHashi.sol";
import { Message } from "./interfaces/IMessage.sol";
import { MessageHashCalculator } from "./utils/MessageHashCalculator.sol";
import { IJushinki } from "./interfaces/IJushinki.sol";

contract Yaru is IYaru, MessageHashCalculator, ReentrancyGuard, Ownable {
    address public immutable hashi;
    address public immutable headerVault;

    mapping(uint256 => address) private _yahos;
    mapping(bytes32 => bool) public executed;

    /// @param hashi_ Address of the Hashi contract.
    /// @param headerVault_ Address of the HeaderVault contract.
    constructor(address hashi_, address headerVault_) {
        hashi = hashi_;
        headerVault = headerVault_;
    }

    /// @dev Executes messages validated by a given set of oracle adapters
    /// @param messages Array of messages to execute.
    /// @param messageIds Array of bytes32 corresponding to the message ids.
    /// @return returnDatas Array of data returned from each executed message.
    function executeMessages(
        Message[] calldata messages,
        bytes32[] calldata messageIds,
        IOracleAdapter[] calldata oracleAdapters
    ) external nonReentrant returns (bytes[] memory) {
        if (messages.length != messageIds.length) revert UnequalArrayLengths(address(this));
        bytes[] memory returnDatas = new bytes[](messages.length);
        for (uint256 i = 0; i < messages.length; i++) {
            Message memory message = messages[i];

            bytes32 messageId = messageIds[i];
            bytes32 messageHash = calculateMessageHash(message, messageId, _yahos[message.fromChainId]);

            if (message.toChainId != block.chainid)
                revert MessageFailure(messageId, abi.encode(keccak256("InvalidToChainId")));
            if (executed[messageId]) revert MessageIdAlreadyExecuted(messageId);
            executed[messageId] = true;

            bytes32 reportedHash = IHashi(hashi).getHash(message.fromChainId, messageId, oracleAdapters);
            if (reportedHash != messageHash) revert MessageFailure(messageId, abi.encode(keccak256("HashMismatch")));

            address to = message.from == address(0) && message.to == address(0) ? headerVault : message.to;
            try IJushinki(to).onMessage(message.data, messageId, message.fromChainId, message.from) returns (
                bytes memory returnData
            ) {
                returnDatas[i] = returnData;
            } catch {
                revert MessageFailure(messageId, abi.encode(keccak256("CallFailed")));
            }

            emit MessageIdExecuted(message.fromChainId, messageId);
        }
        return returnDatas;
    }

    function initializeForChainId(uint256 chainId, address yaho) external onlyOwner {
        if (_yahos[chainId] != address(0)) revert AlreadyInitialized(chainId);
        _yahos[chainId] = yaho;
        emit Initialized(chainId, yaho);
    }
}
