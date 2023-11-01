const hre = require("hardhat");

async function main() {
  const Crowdfunding = await hre.ethers.getContractFactory("Crowdfunding"); // Update "Crowdfunding" with the correct contract name

  // Deploy the Crowdfunding contract
  const crowdfunding = await Crowdfunding.deploy({ gasLimit: 1500000 }); // Set a specific gas limit

  await crowdfunding.deployed();
  console.log("Crowdfunding contract deployed to:", crowdfunding.address)

}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
});
