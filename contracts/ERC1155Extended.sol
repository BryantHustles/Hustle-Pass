// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./HACHIWhitelist.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ERC1155Extended is ERC1155, Ownable, Pausable, ReentrancyGuard {

    constructor(string memory _intialUri)
        ERC1155(_intialUri) {
        }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // The following functions are overrides required by Solidity.

    // function supportsInterface(bytes4 interfaceId)
    //     public
    //     view
    //     virtual
    //     override(ERC1155)
    //     returns (bool)
    // {
    //     return super.supportsInterface(interfaceId);
    // }
}