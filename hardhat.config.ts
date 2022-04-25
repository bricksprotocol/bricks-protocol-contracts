import { config as dotEnvConfig } from "dotenv";
dotEnvConfig();
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import "@openzeppelin/hardhat-upgrades";
import "solidity-coverage";
import "./tasks/accounts";
import "./tasks/balance";
import "./tasks/block-number";
import { HardhatUserConfig } from "hardhat/types";

const privateKey = process.env.PRIVATE_KEY;
const secondPvtKey = process.env.PRIVATE_KEY_SECOND;
const config: HardhatUserConfig = {
  networks: {
    hardhat: {},
    kovan: {
      url: "https://kovan.infura.io/v3/fa404260aa8a46dca23989f9dd56275b",
      accounts: [`0x${privateKey!}`, `0x${secondPvtKey!}`],
      gas: "auto",
      gasPrice: "auto",
      // gas: 210000000,
      // gasPrice: 800000000000,
    },
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/fa404260aa8a46dca23989f9dd56275b",
      accounts: [`0x${privateKey!}`],
      gas: "auto",
      gasPrice: "auto",
      // gas: 210000000,
      // gasPrice: 800000000000,
    },
    matic: {
      url: "https://rpc-mumbai.maticvigil.com",
      accounts: [privateKey!, secondPvtKey!],
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.10",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.6.12",
      },
      // {
      //   version: "0.8.10",
      //   settings: {
      //     optimizer: {
      //       enabled: true,
      //       runs: 200,
      //       details: {
      //         yul: false,
      //       },
      //     },
      //   },
      // },
    ],
  },
  mocha: {
    timeout: 200000,
  },
};

module.exports = config;
