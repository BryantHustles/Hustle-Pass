// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./HACHILibrary.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract HachiVerifySigner is EIP712 {
    string private constant SIGNING_DOMAIN = "HachiNftSig";
    string private constant SIGNATURE_VERSION = "1";

    constructor()
        EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {
    }
        function verifySigner(HachiLibrary.HachiTicket calldata _ticket) internal view returns (address) {
        bytes32 digest = _hash(_ticket);
        return ECDSA.recover(digest, _ticket.signature);
    }

    function _hash(HachiLibrary.HachiTicket calldata _ticket) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("HachiTicket(address to,uint256[] amounts,bytes32[] merkleProof)"),
            _ticket.to,
            keccak256(abi.encodePacked(_ticket.amounts)),
            keccak256(abi.encodePacked(_ticket.merkleProof))
        )));
    }
}