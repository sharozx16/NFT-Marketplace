const { expect } = require("chai");
const {
   BN,           // Big Number support
   constants,    // Common constants, like the zero address and largest integers
   expectEvent,  // Assertions for emitted events
   expectRevert, // Assertions for transactions that should fail
 } = require('@openzeppelin/test-helpers');
const { isAddress } = require("ethers/lib/utils");

let NFTMarketplace;
let nftMarketplace;
let tokenContract = "0xdAC17F958D2ee523a2206206994597C13D831ec7"
let owner;
let addr1;
let addr2;
let addrs;
let URI = "Sample URI"

beforeEach(async function () {
    // Get the ContractFactory and Signers here.
    NFTMarketplace = await ethers.getContractFactory("NFTmarketplace"); //creatingn instance of contract
    [owner, addr1, addr2,tokenContract, ...addrs] = await ethers.getSigners();

    // To deploy our contract, we just have to call Token.deploy() and await
    // for it to be deployed(), which happens once its transaction has been
    // mined.
      nftMarketplace = await NFTMarketplace.deploy(addr1.address);
      // console.log(nftMarketplace)
  });   

  describe("Deployment", function () {
   it("should assign the owner of the contract", async function(){
       expect(await nftMarketplace.owner()).to.equal(owner.address);
   });
   it("should check the reward address", async function(){
      expect(await nftMarketplace.isAddress(tokenContract));
   });
});
describe("Transactional functions", () => {
  it("should mint NFT", () => {
      expect( await nftMarketplace.safemint(1, {
        value: Price,
      }));
  });
  it("should stake NFT", () => {
    
  });
  it("should unstake NFT", () => {

  });
  it("should run before token transfer", () => {

  });
  it("should pause the contract", () => {

  });
  it("should unpause the contract", () => {

  });
  it("should sell NFT", () => {

  });
  it("should emit  event sell NFT", () => {

  });
  it("should buy NFT", () => {

  });
  it("should emit even buy NFT", () => {

  });
    it("should bid on NFT", () => {

    });
    it("should approve bid on NFT", () => {

    });
});
 // it("should assign the reward amount to token contract", async function(){
   //   contractBalance = await nftMarketplace.balanceOf(tokenContract.address);
   //       console.log(tokenContract.address);
   //   expect(await nftMarketplace.rewardAmount().to.equal(contractBalance));
   // });
  //  describe("Transactions", function (){
  //     it("should buy the NFT", async function(){
         
  //     });
  //     it("Should assign the URI", async function () {
  //       await nftMarketplace.setURI(URI);
  //       // expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
  //     });
  //  });
   
   