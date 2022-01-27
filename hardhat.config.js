require("@nomiclabs/hardhat-waffle");
const fs = require('fs');
const account1 = fs
.readFileSync(".secret1")
.toString()
.trim() || "01234567890123456789";
const account2 = fs
.readFileSync(".secret2")
.toString()
.trim() || "01234567890123456789";

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
 module.exports = {
  defaultNetwork: "mainnet",
  networks: {
    okexchaintest: {
      url: "https://exchaintestrpc.okex.org",
      chainId: 65,
      accounts: [account1, account2]
    },

    ganache: {
      url: "HTTP://127.0.0.1:7545",
      chainId: 1337,
      accounts: [account1, account2]
    },
    testnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: [account1, account2]
    },
    mainnet: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: [account1, account2]
    }
  },
  solidity: {
  version: "0.8.6",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200
    }
   }
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts"
  },
  mocha: {
    timeout: 0
  }
};
