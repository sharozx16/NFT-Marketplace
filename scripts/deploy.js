const { ethers } = require("hardhat");
require("dotenv").config({ path: ".env" });
require("@nomiclabs/hardhat-etherscan");

async function main() {
  /*
  A ContractFactory in ethers.js is an abstraction used to deploy new smart contracts,
  so verifyContract here is a factory for instances of our Verify contract.
  */
  const NFTmarketplace = await ethers.getContractFactory("NFTmarketplace");

  // deploy the contract
  const NFTmarketplaceContract = await NFTmarketplace.deploy("0xDf032Bc4B9dC2782Bb09352007D4C57B75160B15");

  await NFTmarketplaceContract.deployed();

  // print the address of the deployed contract
  console.log("Verify Contract Address:", NFTmarketplaceContract.address);

  console.log("Sleeping.....");
  // Wait for etherscan to notice that the contract has been deployed
  await sleep(10000);

  // Verify the contract after deploying
  await hre.run("verify:verify", {
    address: NFTmarketplaceContract.address,
    constructorArguments: [],
  });
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

// Call the main function and catch if there is any error
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });