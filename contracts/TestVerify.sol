// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

contract TestVerify is EIP712 {

    string private constant SIGNING_DOMAIN = "HachiNftSig";
    string private constant SIGNATURE_VERSION = "1";

    struct HachiTicket {
        address to;
        uint256[]  amounts;
        bytes32[]  merkleProof;
        bytes  signature;
    }

    constructor()
    EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION){     
    }

    function verifySigner(HachiTicket calldata _ticket) public view returns (address) {
        bytes32 digest = _hash(_ticket);
        return ECDSA.recover(digest, _ticket.signature);
    }

    function _hash(HachiTicket calldata _ticket) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("HachiTicket(address to,uint256[] amounts,bytes32[] merkleProof)"),
            _ticket.to,
            keccak256(abi.encodePacked(_ticket.amounts)),
            keccak256(abi.encodePacked(_ticket.merkleProof))
        )));
    }

    function eip712Hash(HachiTicket calldata _ticket) public view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("HachiTicket(address to,uint256[] amounts,bytes32[] merkleProof)"),
            _ticket.to,
            keccak256(abi.encodePacked(_ticket.amounts)),
            keccak256(abi.encodePacked(_ticket.merkleProof))
        )));
    }

    function structHash(HachiTicket calldata _ticket) public view returns (bytes32) {
        return keccak256(abi.encode(
            keccak256("HachiTicket(address to,uint256[] amounts,bytes32[] merkleProof)"),
            _ticket.to,
            keccak256(abi.encodePacked(_ticket.amounts)),
            keccak256(abi.encodePacked(_ticket.merkleProof))
        ));
    }

    function testVerify(bytes32 _structHash, bytes calldata _signature) public view returns (address) {
        bytes32 _digest = _hashTypedDataV4(_structHash);
        return ECDSA.recover(_digest, _signature );
    }
}