// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

library HachiLibrary {
    struct HachiTicket {
        address to;
        uint256[]  amounts;
        bytes32[]  merkleProof;
        bytes  signature;
    }
}