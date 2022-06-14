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
      url: "https://polygon-mumbai.g.alchemy.com/v2/audnHAeVnXRoVIya04iyWWb2b5xjAdH-",
      accounts: [
        privateKey!,
        secondPvtKey!,
        "40bd6f46547ede2780afe0fd97591ee806c55025db8a5e2db0eb9f6501f626b5",
        "82c4d2bce16bbe6f8147f0e341c4be8fa4f05fe71c5605fe1fffdd51f821279c",
        "afe19e2287cc5d67726cb615a5af51f7a8d07844503c0e3c00746b7052bdf2bf",
        "4e0867e2ad957e2c6a05c10c417b4f36d4bdc3940421aeb1f31b689cc3442994",
        "6b971c13007b23f5b9981545ee232c937eefa0764d6cdb2f517d02bba8b80bd3",
        "1855ea813e8d10b7850b7076a2e151d0d94334da0f9cb2e4ec7d0723e61d4eac",
        "f172bc2055f82313f1be8cc395001d675e23e5bf5f04e81181215bb1f03ad66e",
        "a846d1a808822dde584e2d44c05e16e4a58a1fd9d2b66c827c10248e6ef0a0e3",
      ],
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
            details: {
              yul: true,
              yulDetails: {
                stackAllocation: true,
                optimizerSteps: "dhfoDgvulfnTUtnIf",
              },
            },
          },
        },
      },
      // {
      //   version: "0.6.12",
      // },
      // {
      //   version: "0.5.0",
      // },
      // },
      // {
      //   version: "0.5.2",
      // },
      // {
      //   version: "0.5.3",
      // },

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
