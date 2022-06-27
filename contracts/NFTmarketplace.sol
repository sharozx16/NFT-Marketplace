// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTmarketplace is
    ERC721,
    Pausable,
    Ownable,
    ERC721Burnable,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    struct nftDetails {
        address _sellerAddress;
        uint256 _tokenID;
        uint256 _price;
        address _buyerAddress;
        bool _isSold;
    }
    struct bid {
        uint256 _tokenID;
        uint256 _price;
        address _buyerAddress;
        bool isApproved;
    }
    string private URI;
    address tokenContract;
    uint256 private rewardAmount = 1000000000000000000000;
    uint256 private royalityPercent = 2;
    uint256[] unSold;

    mapping(uint256 => nftDetails) public idToDetail;
    mapping(uint256 => bid) public idtobid;

    event sellNFT(uint256 tokenId, uint256 price, address seller);
    event buyNFT(address _seller, address, uint256 _price, uint256 tokenID);

    constructor(address _reward) ERC721("MyNFT", "MyNFT") {
        tokenContract = _reward;
    }

    function _baseURI() internal view override returns (string memory) {
        return URI;
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }

    function stakeNFT(uint256[] memory _tokenIDs) public {
        uint256 arrayLength = _tokenIDs.length;
        require(_tokenIDs.length >= 3, "cannot stake more than 3 NFTs");

        for (uint256 i = 0; i < arrayLength; i++) {
            _transfer(msg.sender, address(this), _tokenIDs[i]);
        }
    }

    function unstakeNFT(uint256[] memory _tokenIDs) external nonReentrant {
        uint256 arrayLength = _tokenIDs.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            _transfer(address(this), msg.sender, _tokenIDs[i]);
        }
        uint256 amount = rewardAmount * arrayLength;
        IERC20(tokenContract).transfer(msg.sender, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function sell(uint256 _tokenID, uint256 _price) external {
        require(_exists(_tokenID), "token ID does not exist");
        require(ownerOf(_tokenID) == msg.sender, " You do not own this nft");
        idToDetail[_tokenID]._sellerAddress = msg.sender;
        idToDetail[_tokenID]._tokenID = _tokenID;
        idToDetail[_tokenID]._price = _price;
        idToDetail[_tokenID]._isSold = false;
        unSold.push(_tokenID);
        approve(address(this), _tokenID);
        emit sellNFT(_tokenID, _price, msg.sender);
    }

    function buy(uint256 _tokenID, uint256 _price) external nonReentrant {
        require(_exists(_tokenID), "token ID does not exist");
        require(ownerOf(_tokenID) != msg.sender, " You own this nft");
        require(idToDetail[_tokenID]._isSold == false, "Already Sold");
        require(idToDetail[_tokenID]._price == _price, " Insufficient Amount");

        uint256 amount;

        idToDetail[_tokenID]._buyerAddress = msg.sender;
        idToDetail[_tokenID]._isSold = true;
        safeTransferFrom(
            idToDetail[_tokenID]._sellerAddress,
            msg.sender,
            _tokenID
        );
        amount = ((_price / 100) * 2);
        _price = _price - amount;
        IERC20(tokenContract).transfer(
            idToDetail[_tokenID]._sellerAddress,
            _price
        );
        IERC20(tokenContract).transfer(owner(), amount);
        for (uint256 i = 0; i < unSold.length; i++) {
            if (unSold[i] == _tokenID) unSold.push(unSold[i]);
        }
        emit buyNFT(
            idToDetail[_tokenID]._sellerAddress,
            msg.sender,
            _price,
            _tokenID
        );
    }

    function bidNFT(uint256 _tokenID, uint256 _amount) external {
        require(_exists(_tokenID), "token ID does not exist");
        require(ownerOf(_tokenID) != msg.sender, " You own this nft");
        idtobid[_tokenID]._tokenID = _tokenID;
        idtobid[_tokenID]._price = _amount;
        idtobid[_tokenID]._buyerAddress = msg.sender;
        idtobid[_tokenID].isApproved = false;
        IERC20(tokenContract).approve(address(this), _amount);
    }

    function approveBid(uint256 _tokenID, bool _status) external nonReentrant {
        require(ownerOf(_tokenID) == msg.sender, "You do not own this NFT");

        idtobid[_tokenID].isApproved = _status;
        if (idtobid[_tokenID].isApproved == true) {
            _transfer(msg.sender, idtobid[_tokenID]._buyerAddress, _tokenID);
            IERC20(tokenContract).transferFrom(
                idtobid[_tokenID]._buyerAddress,
                msg.sender,
                idtobid[_tokenID]._price
            );
        }
    }

    function setURI(string memory _URI) external onlyOwner {
        URI = _URI;
    }
}
