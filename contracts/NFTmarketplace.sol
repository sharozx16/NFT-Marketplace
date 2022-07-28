// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";
contract NFT is ERC721, Pausable, Ownable, ERC721Burnable, ReentrancyGuard {
    
    using SafeMath for uint256;

    struct Stake {
        uint256[]  tokenId;
        uint256[]  timestamp;
    }

    struct nftDetails{
        address _sellerAddress;
        uint256 _price;
        address _buyerAddress;
        bool _isSold;
        address _prevOwner;
    }

    struct bid{
        uint256 _tokenID;
        uint256 _price;
        address _buyerAddress;
        bool isApproved;
    }

    error TransferFailed();
    string private URI;
    IERC20 public tokenContract;
    uint256 private rewardAmount = 10000000000000000000; // 10 tokens
    uint private rewardTimeSeconds =  60;
    uint256 private royalityPercent = 2;
    uint256 public protocolFees = 3;
    uint256[] unSold;
    bool public contractStatus = true;
    
    uint[] stakedNFTs;

    mapping(uint => nftDetails) public idToDetail;
    mapping(uint256 => bid) public idtobid;
    mapping(uint => string) _tokenURIs;
    mapping(address => Stake) stakeDetails;
    
    event sellNFT(uint256 tokenId, uint256 price, address seller);
    event buyNFT(address _seller,address _buyer, uint256 _price, uint256 tokenID);
    
    constructor(address _reward) ERC721("ASTRALNAUTX", "ASTRALX") {
        tokenContract = IERC20(_reward);
    }
    function _baseURI() internal view override returns (string memory) {
        return URI;
    }
    function tokenURI(uint256 _tokenId) public view override returns(string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
        return bytes(_tokenURIs[_tokenId]).length > 0 ?
            string(abi.encodePacked(_tokenURIs[_tokenId])) : "";
    }
    function _setTokenURI(uint _tokenId, string memory _tokenURI) internal {
        _tokenURIs[_tokenId] = _tokenURI;
    }
    function safeMint(string memory _tokenURI, uint _tokenId, uint _price) public {
        require(contractStatus, "Currently contract is not active");
        tokenContract.approve(address(this),tokenContract.balanceOf(msg.sender));
        require(tokenContract.balanceOf(msg.sender) >= _price, "You don't have enough tokens to mint");
        tokenContract.transferFrom(msg.sender,address(this), _price);
        _safeMint(msg.sender, _tokenId);
        _setTokenURI(_tokenId, _tokenURI);
    }

    function airdropMint(address[] memory _addresses, string[] memory _tokenURI, uint[] memory _tokenIds) external onlyOwner {
        require(contractStatus, "Currently contract is not active");
        require(_addresses.length == _tokenURI.length);
        require(_addresses.length == _tokenIds.length);
        uint arrayLength = _addresses.length;
        for(uint i = 0; i < arrayLength; i++){
            _safeMint(_addresses[i], _tokenIds[i]);
            _setTokenURI(_tokenIds[i], _tokenURI[i]);
        }
    }
    
    function stakeNFT(uint[] memory _tokenIDs) public {
        require(contractStatus, "Currently contract is not active");
        uint stakeTime= block.timestamp;
        uint arrayLength = _tokenIDs.length;
        for(uint i = 0; i < arrayLength; i++){
        _transfer(msg.sender, address(this), _tokenIDs[i]);
        stakedNFTs.push(_tokenIDs[i]);
        stakeDetails[msg.sender].tokenId.push(_tokenIDs[i]);
        stakeDetails[msg.sender].timestamp.push(stakeTime);
        }
    }

    function remove(uint _index) private {
        stakedNFTs[_index] = stakedNFTs[stakedNFTs.length - 1];
        stakedNFTs.pop();
    }


    function unstakeNFT(uint[] memory _tokenIDs) external nonReentrant() returns (uint) {
        require(contractStatus, "Currently contract is not active");
        uint currentTime = block.timestamp;
        uint totalRewardTime = 0;
        uint totalRewardTokens = 0;
        uint arrayLength = _tokenIDs.length;
        for(uint i = 0; i < arrayLength; i++){
            uint stakeTime = stakeDetails[msg.sender].timestamp[i];
            uint differenceTime = currentTime.sub(stakeTime);
            differenceTime = differenceTime.div(rewardTimeSeconds);
            totalRewardTime = totalRewardTime.add(differenceTime);
            _transfer(address(this), msg.sender, _tokenIDs[i]);
            
            uint index = 0;
            uint stakedNFTsLength = stakedNFTs.length;
             for(uint j = 0; j < stakedNFTsLength; j++){
                 if(_tokenIDs[i] == stakedNFTs[j]){
                     index = j;
                 }
             }
            remove(index);
        }

        totalRewardTokens = rewardAmount.mul(totalRewardTime);
        console.log(totalRewardTokens);
         bool success = tokenContract.transferFrom(address(this),msg.sender, totalRewardTokens);
        if (!success) {
            revert TransferFailed();
        }
        return totalRewardTokens;
    }   

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function totalStakedNFTs() public view returns (uint[] memory) {
        return stakedNFTs;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function sellNft(uint256 tokenId, uint256 price) external {
            require(contractStatus, "Currently contract is not active");
            require(price > 0, "Zero amount cannot be allow");
            require(ownerOf(tokenId) == _msgSender(), "NA");
            idToDetail[tokenId]._sellerAddress = msg.sender;
            idToDetail[tokenId]._price = price;
            idToDetail[tokenId]._isSold = false;
            idToDetail[tokenId]._buyerAddress = address(0);
        emit sellNFT(tokenId, price, msg.sender);
    }

    function cancelSellNft(uint _tokenId) external {
        require(contractStatus, "Currently contract is not active");
        require(ownerOf(_tokenId) == _msgSender(), "NA");
        idToDetail[_tokenId]._sellerAddress = address(0);
        idToDetail[_tokenId]._price = 0;
        idToDetail[_tokenId]._isSold = true;
        idToDetail[_tokenId]._buyerAddress = address(0);
    }

    function buyNft(uint256 tokenId, uint256 _price) external nonReentrant{
            require(contractStatus, "Currently contract is not active");
            require(_exists(tokenId),"Invalid NFT ID");
            require(idToDetail[tokenId]._sellerAddress != address(0), "Seller address is Null Address");
            require(idToDetail[tokenId]._isSold == false,"NFT is already sold or cancel by owner");
            require(ownerOf(tokenId) != _msgSender(), "You are the owner");
            require(idToDetail[tokenId]._price == _price,"Insufficient Amount");
            address owner = ownerOf(tokenId);
            uint256 fees = ((_price/100) * protocolFees);
            uint256 _royality = ((_price/100) * royalityPercent);
            _price = _price - fees;
            _price = _price - _royality;
            _transfer(ownerOf(tokenId), _msgSender(), tokenId);
             bool success = tokenContract.transferFrom(msg.sender,idToDetail[tokenId]._sellerAddress, _price);
        if (!success) {
            revert TransferFailed();
        }
        bool successs = tokenContract.transferFrom(msg.sender,idToDetail[tokenId]._sellerAddress, _royality);
        if (!successs) {
            revert TransferFailed();
        }
         bool successss = tokenContract.transferFrom(msg.sender,address(this), fees);
        if (!successss) {
            revert TransferFailed();
        }
        idToDetail[tokenId]._isSold = true;
        idToDetail[tokenId]._buyerAddress = msg.sender;
        idToDetail[tokenId]._prevOwner = owner;
        emit buyNFT(owner, msg.sender, _price, tokenId);
    }

    function bidNFT(uint256 _tokenID, uint256 _amount) external {
        require(contractStatus, "Currently contract is not active");
        require(_exists(_tokenID),"token ID does not exist");
        require(ownerOf(_tokenID) != msg.sender," You own this nft");
            idtobid[_tokenID]._tokenID = _tokenID;
            idtobid[_tokenID]._price = _amount;
            idtobid[_tokenID]._buyerAddress = msg.sender;
            idtobid[_tokenID].isApproved = false;
            IERC20(tokenContract).approve(address(this), _amount);
    }

    function cancelBidNFT(uint _tokenId) external {
        require(contractStatus, "Currently contract is not active");
        require(_exists(_tokenId),"token ID does not exist");
        require(ownerOf(_tokenId) != msg.sender," You own this nft");
        require(idtobid[_tokenId]._buyerAddress == msg.sender);
        idtobid[_tokenId]._tokenID = 0;
        idtobid[_tokenId]._price = 0;
        idtobid[_tokenId]._buyerAddress = address(0);
        idtobid[_tokenId].isApproved = false;
    }

    function approveBid(uint256 _tokenID, bool _status)external nonReentrant() {
        require(contractStatus, "Currently contract is not active");
        require(ownerOf(_tokenID)== msg.sender,"You do not own this NFT");
        require(idtobid[_tokenID]._buyerAddress != address(0),"buyer address is null address");
        idtobid[_tokenID].isApproved = _status;
        if(idtobid[_tokenID].isApproved == true){
            _transfer(msg.sender, idtobid[_tokenID]._buyerAddress, _tokenID);
            uint256 fees = ((idtobid[_tokenID]._price/100) * protocolFees);
            idtobid[_tokenID]._price -= fees;
            IERC20(tokenContract).transferFrom(idtobid[_tokenID]._buyerAddress, msg.sender, idtobid[_tokenID]._price);
            IERC20(tokenContract).transferFrom(idtobid[_tokenID]._buyerAddress, address(this), fees);
        }
    }


    function withdrawToken() external onlyOwner nonReentrant{
        bool success = tokenContract.transferFrom(address(this),owner(), tokenContract.balanceOf(address(this)));
        if (!success) {
            revert TransferFailed();
        }  
    }


    function setFees(uint256 _fees) external onlyOwner{
        protocolFees = _fees;
    }
    function setURI(string memory _URI) external onlyOwner{
            URI = _URI;
    }
    function setcontractStatus(bool _status) external onlyOwner {
        contractStatus = _status;
    }
    function setRewardAmount(uint _rewardAmount) external onlyOwner {
        rewardAmount = _rewardAmount;
    }
    function setRewardTimeSeconds(uint _rewardTimeSeconds) external onlyOwner {
        rewardTimeSeconds = _rewardTimeSeconds;
    }