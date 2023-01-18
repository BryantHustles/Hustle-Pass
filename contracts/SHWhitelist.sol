// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SHWhitelist is Ownable {
    bytes32 public merkleRootA;
    bytes32 public merkleRootB;


    constructor(bytes32 _merkleRootA, bytes32 _merkleRootB) {
        merkleRootA = _merkleRootA;
        merkleRootB = _merkleRootB;
    }

    function setMerkleRootA(bytes32 _merkleRootA) public onlyOwner {
        merkleRootA = _merkleRootA;
    }

    function setMerkleRootB(bytes32 _merkleRootB) public onlyOwner {
        merkleRootB = _merkleRootB;
    }

    function verifyWhitelistA(bytes32[] memory _merkleProof, address _signer)
        public
        view
        returns (bool)
    {
        bytes32 _leaf = keccak256(abi.encodePacked(_signer));
        return MerkleProof.verify(_merkleProof, merkleRootA, _leaf);
    }

    function verifyWhitelistB(bytes32[] memory _merkleProof, address _signer)
        public
        view
        returns (bool)
    {
        bytes32 _leaf = keccak256(abi.encodePacked(_signer));
        return MerkleProof.verify(_merkleProof, merkleRootB, _leaf);
    }
}
