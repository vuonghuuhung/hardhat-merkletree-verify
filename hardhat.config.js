require("@nomicfoundation/hardhat-toolbox");

const INFURA_API_KEY = "0820cffd00564674ae96bb78e3578f02";

const SEPOLIA_PRIVATE_KEY = "d5485c1600de8fb0cc32689e28efeba643cfb88dabc2219ba6199ff5a035dfd3";

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.5",
    settings: {
      optimizer: {
        enabled: true,
        runs: 100,
      },
    },
  },
  networks: {
    sepolia: {
      url: `https://sepolia.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [SEPOLIA_PRIVATE_KEY]
    }
  },
};
