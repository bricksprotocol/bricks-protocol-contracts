// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { run, ethers, upgrades } from "hardhat";
import { config } from "../config";
import Web3 from "web3";
import wethAbi from "../abis/weth.json";
import usdcAbi from "../abis/usdc.json";
import adaiAbi from "../abis/adai.json";
import { makeTransferProxyAdminOwnership } from "@openzeppelin/hardhat-upgrades/dist/admin";
const ETHERSCAN_TX_URL = "https://kovan.etherscan.io/tx/";
let ENTRY_FEES: any = Web3.utils.toWei("5", "ether");
let INITIAL_INVESTED_AMOUNT: any = Web3.utils.toWei("50", "ether");
const token = config.mumbaiTest.daiToken;
const aToken = config.mumbaiTest.adaiToken;
async function main() {
  const proxyAddress = "0x464dD89258BDd1D0d87866751B0BAF4504a3E019";
  const BoxV2 = await ethers.getContractFactory("CreateTournamentFactoryv2");
  console.log("upgrade to CreateTournamentFactoryv2...");
  const factoryV2 = await upgrades.upgradeProxy(proxyAddress, BoxV2);
  console.log(
    factoryV2.address,
    " CreateTournamentFactoryv2 address(should be the same)"
  );
  console.log("LendingAddress", await factoryV2.lendingPoolAddress());
  const tx = await factoryV2.upgradeLendingAddress(
    "0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0"
  );
  await tx.wait();
  console.log("LendingAddress", await factoryV2.lendingPoolAddress());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
