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
const config: HardhatUserConfig = {
  networks: {
    hardhat: {},
    kovan: {
      url: "https://eth-kovan.alchemyapi.io/v2/ya8sHgErEz7TqKiH1fyQH7_kd9GCwNFu",
      accounts: [privateKey!],
      gas: "auto",
      gasPrice: "auto",
      // gas: 210000000,
      // gasPrice: 800000000000,
    },
    rinkeby: {
      url: "https://eth-kovan.alchemyapi.io/v2/UKMdZt923dSk_Gt1U9ymx-1rtsmL7kC_",
      accounts: [privateKey!],
      // gas: 210000000,
      // gasPrice: 800000000000,
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.4",
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
      {
        version: "^0.8.7",
      },
      {
        version: "^0.4.0",
      },
    ],
  },
  mocha: {
    timeout: 200000,
  },
};

module.exports = config;
