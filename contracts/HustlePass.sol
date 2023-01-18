// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import "./SHWhitelist.sol";

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

    uint256 public ownerClaimLimitA = 50;
    uint256 public ownerClaimLimitB = 100;
    uint256 private tierACount = 0;
    uint256 private tierALimit = 500;
    uint256 private tierBCount = 0;
    uint256 private tierBLimit = 1000;

    bool public ownerClaimComplete = false;

    mapping(address => bool) private addressMinted;

    address public SHWallet;

    struct mintTicket {
        address to;
        uint256 passSelection; // 1 or 2
        bytes32[] merkleProof;
        bytes signature;
    }

    SHWhitelist whtlst;

    event Mint(address indexed to, uint256 indexed id, uint256 _amount);

    constructor(
        string memory _uri,
        string memory _SIGNING_DOMAIN,
        string memory _SIGNATURE_VERSION,
        string memory _contractURI,
        address _SHWallet,
        SHWhitelist _whtlst
    ) ERC1155(_uri) EIP712(_SIGNING_DOMAIN, _SIGNATURE_VERSION) {
        contractURI = _contractURI;
        whtlst = _whtlst;
        SHWallet = _SHWallet;
        setDefaultRoyalty(_SHWallet, 800);
        _pause();
    }

    receive() external payable {
        payable(SHWallet).transfer(msg.value);
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

        if (_ticket.passSelection == 1) {
            require(
                whtlst.verifyWhitelistA(_ticket.merkleProof, _signer),
                "Not on Tier A Claim List"
            );
            require(tierACount + 1 <= tierALimit, "Pass A Sold Out");
            tierACount += 1;
        } else {
            require(
                whtlst.verifyWhitelistB(_ticket.merkleProof, _signer),
                "Not on Tier B Claim List"
            );
            require(tierBCount + 1 <= tierBLimit, "Pass B Sold Out");
            tierBCount += 1;
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
        require(!ownerClaimComplete , "Already claimed");
        ownerClaimComplete = true;

        address _shWallet = address(SHWallet);

        emit Mint(address(_shWallet), 1, ownerClaimLimitA);
        _mint(_shWallet, 1, ownerClaimLimitA, "");

        emit Mint(_shWallet, 2, ownerClaimLimitB);
        _mint(_shWallet, 2, ownerClaimLimitB, "");
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
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
