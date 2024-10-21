// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.20;

library Merkle {
    uint256 internal constant SLOTS_PER_HISTORICAL_ROOT = 8192;
    // BeaconState -> BlockRoots
    uint256 internal constant BLOCK_ROOTS_GINDEX = 37;
    // BeaconBlock -> BeaconState
    uint256 internal constant STATE_ROOT_GINDEX = 11;
    // BeaconBlock -> BeaconBody -> ExecutionPayload -> ReceiptsRoot
    uint256 internal constant RECEIPT_ROOT_GINDEX = 6435;

    function restoreMerkleRoot(
        bytes32[] memory branch,
        bytes32 leaf,
        uint256 index,
        uint256 depth
    ) internal pure returns (bytes32 root) {
        require(index < 2 ** branch.length, "invalid leaf index");

        bytes32 combineHash = leaf;
        uint256 curIndex = index;
        for (uint256 i = 0; i < depth; ) {
            if (curIndex % 2 == 0) combineHash = sha256(bytes.concat(combineHash, branch[i]));
            else combineHash = sha256(bytes.concat(branch[i], combineHash));

            curIndex /= 2;

            unchecked {
                i++;
            }
        }

        root = combineHash;
    }

    function verifyReceiptsRoot(
        bytes32[] memory receiptsRootBranch,
        bytes32 receiptsRoot,
        uint64 lcSlot,
        uint64 txSlot,
        bytes32 headerRoot
    ) internal pure returns (bool) {
        uint256 gindex;
        if (txSlot == lcSlot) {
            gindex = RECEIPT_ROOT_GINDEX;
        } else if (lcSlot - txSlot <= SLOTS_PER_HISTORICAL_ROOT) {
            uint256[] memory blockRootsGindex = new uint256[](2);
            blockRootsGindex[0] = BLOCK_ROOTS_GINDEX;
            blockRootsGindex[1] = calculateArrayGindex(txSlot % SLOTS_PER_HISTORICAL_ROOT);
            uint256[] memory receiptGindexes = new uint256[](3);
            receiptGindexes[0] = STATE_ROOT_GINDEX;
            receiptGindexes[1] = concatGindices(blockRootsGindex);
            receiptGindexes[2] = RECEIPT_ROOT_GINDEX;

            // BeaconBlock -> BeaconState -> HistoricalRoots -> BeaconBlock -> BeaconBody -> ExecutionPayload -> ReceiptsRoot
            gindex = concatGindices(receiptGindexes);
        } else if (lcSlot - txSlot > SLOTS_PER_HISTORICAL_ROOT) {
            revert("txSlot lags by >8192 blocks. Not supported.");
        } else {
            revert("txSlot can't be greater than lightclient slot");
        }

        (uint256 index, uint256 depth) = calculateIndex(gindex);
        bytes32 computedRoot = restoreMerkleRoot(receiptsRootBranch, receiptsRoot, index, depth);
        return computedRoot == headerRoot;
    }

    function concatGindices(uint256[] memory gindices) public pure returns (uint256) {
        uint256 result = 1; // Start with binary "1"
        for (uint i = 0; i < gindices.length; i++) {
            uint256 gindex = gindices[i];
            uint256 gindexWithoutLeadingOne = gindex & ((1 << (bitLength(gindex) - 1)) - 1);
            result = (result << (bitLength(gindex) - 1)) | gindexWithoutLeadingOne;
        }
        return result;
    }

    function bitLength(uint256 number) internal pure returns (uint256) {
        if (number == 0) {
            return 0;
        }
        uint256 length = 0;
        while (number > 0) {
            length++;
            number >>= 1;
        }
        return length;
    }

    function calculateArrayGindex(uint256 elementIndex) internal pure returns (uint256) {
        uint256 gindex = 1;
        uint256 depth = 0;
        while ((1 << depth) < SLOTS_PER_HISTORICAL_ROOT) {
            depth++;
        }

        for (uint256 d = 0; d < depth; d++) {
            gindex = (gindex << 1) | ((elementIndex >> (depth - d - 1)) & 1);
        }
        return gindex;
    }

    function calculateIndex(uint256 gindex) internal pure returns (uint256 index, uint256 depth) {
        depth = floorLog2(gindex);
        index = gindex % (2 ** depth);
    }

    function floorLog2(uint256 x) internal pure returns (uint256) {
        require(x > 0, "Input must be greater than zero");
        uint256 result = 0;

        while (x > 1) {
            x >>= 1;
            result++;
        }

        return result;
    }
}
