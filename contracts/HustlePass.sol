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

    uint256 public mintLimit = 100;
    uint256 public ownerClaimLimit = 25;
    uint256 public ownerClaimed = 0;
    uint256 private SHPassACount = 0;
    uint256 private SHPassBCount = 0;

    mapping(address => bool) private addressMinted;

    struct mintTicket {
        address to;
        uint256 passSelection; // 1 or 2
        bytes32[] merkleProof;
        bytes signature;
    }

    SHWhitelist whtlst;
    SHWallet wllt;

    event Mint(address indexed to, uint256 indexed id, uint256 _amount);

    constructor(
        string memory _uri,
        string memory _SIGNING_DOMAIN,
        string memory _SIGNATURE_VERSION,
        string memory _contractURI,
        SHWhitelist _whtlst,
        SHWallet _wllt
    ) ERC1155(_uri) EIP712(_SIGNING_DOMAIN, _SIGNATURE_VERSION) {
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

    function mintPass(mintTicket calldata _ticket)
        public
        whenNotPaused
        nonReentrant
    {
        address _signer = verifySigner(_ticket);
        require(msg.sender == _signer, "Verification Failed");
        require(
            _ticket.passSelection == 1 || _ticket.passSelection == 2,
            "Invalid Pass Selection (1 or 2 only)."
        );
        require(addressMinted[_signer] == false, "Address Already Minted");

        if (!publicMint) {
            require(
                whtlst.verifyWhitelist(_ticket.merkleProof, _signer),
                "Not Whitelisted"
            );
        }

        if (_ticket.passSelection == 1) {
            require(SHPassACount + 1 <= mintLimit, "Pass A Sold Out");
            SHPassACount += 1;
        } else {
            require(SHPassBCount + 1 <= mintLimit, "Pass B Sold Out");
            SHPassBCount += 1;
        }

        emit Mint(_ticket.to, _ticket.passSelection, 1);

        addressMinted[_signer] = true;

        _mint(_ticket.to, _ticket.passSelection, 1, "");
    }

    function verifySigner(mintTicket calldata _ticket)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hash(_ticket);
        return ECDSA.recover(digest, _ticket.signature);
    }

    function _hash(mintTicket calldata _ticket)
        internal
        view
        returns (bytes32)
    {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "mintTicket(address to,uint256 passSelection,bytes32[] merkleProof)"
                        ),
                        _ticket.to,
                        _ticket.passSelection,
                        keccak256(abi.encodePacked(_ticket.merkleProof))
                    )
                )
            );
    }

    function ownerClaim() public onlyOwner {
        require(addressMinted[msg.sender] == false, "Address Already Claimed");
        require(ownerClaimed < ownerClaimLimit, "None to Claim");

        addressMinted[msg.sender] = true;
        ownerClaimed += ownerClaimLimit;

        emit Mint(msg.sender, 1, ownerClaimLimit);
        _mint(msg.sender, 1, ownerClaimLimit, "");

        emit Mint(msg.sender, 2, ownerClaimLimit);
        _mint(msg.sender, 2, ownerClaimLimit, "");
    }

    function airdrop(
        address _from,
        address[] calldata _recipients,
        uint256[] calldata _passSelection,
        uint256[] calldata _amounts
    ) public onlyOwner {
        require(
            _recipients.length == _amounts.length &&
                _recipients.length == _passSelection.length,
            "Array lengths don't match"
        );
        for (uint256 i = 0; i < _recipients.length; i++) {
            safeTransferFrom(
                _from,
                _recipients[i],
                _passSelection[i],
                _amounts[i],
                ""
            );
        }
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
