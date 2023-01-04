// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./SHWhitelist.sol";
import "./SHWallet.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

//HachiNFT
contract HUSTLEPASS is
    ERC1155,
    EIP712,
    ERC2981,
    Ownable,
    Pausable,
    ReentrancyGuard
{
    //string private constant SIGNING_DOMAIN = "Example Signing Domain";
    //string private constant SIGNATURE_VERSION = "1";
    string public contractURI;
    string public name = "The Side Hustler Pass";
    string public symbol = "TSHP";

    bool public publicMint;

    uint256 public mintLimit = 500;
    uint256 private tokenIndex = 0;
    uint256 private SHPassACount = 0;
    uint256 private SHPassBCount = 0;

    mapping(uint256 => uint256) private control;
    mapping(address => bool) private addressMinted;

    struct HachiTicket {
        address to;
        uint256[] amounts;
        bytes32[] merkleProof;
        bytes signature;
    }

    SHWhitelist whtlst;
    SHWallet wllt;

    event Mint(address indexed to, uint256[] indexed id, uint256 _value);

    constructor(
        string memory _ipfs,
        string memory _SIGNING_DOMAIN,
        string memory _SIGNATURE_VERSION,
        string memory _contractURI,
        SHWhitelist _whtlst,
        SHWallet _wllt
    ) 
        ERC1155(_ipfs) 
        EIP712(_SIGNING_DOMAIN, _SIGNATURE_VERSION) {
        contractURI = _contractURI;
        whtlst = _whtlst;
        wllt = _wllt;
        setDefaultRoyalty(address(_wllt), 500);
        _pause();
    }

    receive() external payable {
        payable(wllt).transfer(msg.value);
    }

    function uri(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {

        return (
            string(
                abi.encodePacked(
                    super.uri(_tokenId),
                    Strings.toString(_tokenId)
                )
            )
        );
    }

    function setURI(string memory _newuri) public onlyOwner {
        ERC1155._setURI(_newuri);
    }

    function setContractURI(string memory _contractURI) public onlyOwner {
        contractURI = _contractURI;
    }

    function mintPass(HachiTicket calldata _ticket)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        address _signer = verifySigner(_ticket);
        require(msg.sender == _signer, "Verification Failed");
        uint256 _length = _ticket.amounts.length;
        require(_length > 0, "Invalid Amounts Input");
        uint256[] memory _tokenId = _ticket.amounts;

        require(tokenIndex + _length <= mintLimit, "Sold Out");
        if (!publicMint) {
            require(
                whtlst.verifyWhitelist(_ticket.merkleProof, _signer),
                "Not Whitelisted"
            );
        }
        require(
            addressMinted[_signer] == false,
            "Address Already Minted"
        );
        for (uint256 i = 0; i < _length; i++) {
            require(_ticket.amounts[i] == 1, "Invalid amounts array");
            tokenIndex++;
            _tokenId[i] = tokenIndex;
        }

        emit Mint(_ticket.to, _tokenId, msg.value);
        addressMinted[_signer] = true;

        _mintBatch(_ticket.to, _tokenId, _ticket.amounts, "");

        payable(wllt).transfer(msg.value);
    }

    function verifySigner(HachiTicket calldata _ticket)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hash(_ticket);
        return ECDSA.recover(digest, _ticket.signature);
    }

    function _hash(HachiTicket calldata _ticket)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "HachiTicket(address to,uint256[] amounts,bytes32[] merkleProof)"
                        ),
                        _ticket.to,
                        keccak256(abi.encodePacked(_ticket.amounts)),
                        keccak256(abi.encodePacked(_ticket.merkleProof))
                    )
                )
            );
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function updateMintLimit(uint256 _limit) public onlyOwner {
        mintLimit = _limit;
    }

    function updatePublicMint(bool _publicMint) public onlyOwner {
        require(_publicMint != publicMint, "input eqaul to state");
        publicMint = _publicMint;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
