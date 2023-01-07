// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/finance/PaymentSplitter.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SHWallet is PaymentSplitter, Ownable {
    constructor(address[] memory _address, uint256[] memory _shares)
        payable
        PaymentSplitter(_address, _shares)
    {}

    function release() public {
        release(payable(msg.sender));
    }

    function viewBalanceOwed() public view returns (uint256) {
        require(shares(msg.sender) > 0);
        uint256 _shares = shares(msg.sender);
        uint256 _totalShares = totalShares();
        uint256 _totalReceived = address(this).balance + totalReleased();
        uint256 _released = released(msg.sender);

        return (_totalReceived * _shares) / _totalShares - _released;
    }
}
