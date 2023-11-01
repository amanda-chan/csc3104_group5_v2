require("@nomiclabs/hardhat-ethers");
require("@nomiclabs/hardhat-waffle");

module.exports = {
  solidity: "0.8.19",
  networks: {
    // Add a network configuration to connect to your Geth instance
    gethNetwork: {
      url: "http://localhost:8545", // Connect to the local Geth instance
    },
  },
};
