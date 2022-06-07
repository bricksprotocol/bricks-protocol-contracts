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
  const proxyAddress = "0xB49225C9A62Dfd05e5E8AaFD5BE25DA58581a965";
  //const tournamentProxyAddress = "0x09E3823795C50cE47153409d0EeA0f33317b943D";
  // const tournamentProxyAddress1 = "0x26D2260dc3072F7EE4c29819255BFE08a07D16dc";
  const beaconAddress = "0x1396E609d276eF06cC262D05103EA92854F637c0";
  // const beaconAddress = "0x956Bfaa1441FE6f711f4224A7a84A7A93C44A612";
  const FactoryV2 = await ethers.getContractFactory("CreateTournamentFactory");
  console.log("upgrade to CreateTournamentFactoryv2...");
  const factoryV2 = await upgrades.upgradeProxy(proxyAddress, FactoryV2);
  console.log(
    factoryV2.address,
    " CreateTournamentFactoryv2 address(should be the same)"
  );
  factoryV2.setProtocolFees(10);
  // console.log("LendingAddress", await factoryV2.lendingPoolAddress());
  // const tx = await factoryV2.upgradeLendingAddress(
  //   "0x9fe46736679d2d9a65f0992f2272de9f3c7fa6e0"
  // );
  // await tx.wait();
  // console.log("LendingAddress", await factoryV2.lendingPoolAddress());

  // const TournamentV1 = await ethers.getContractFactory("Tournament");
  // const tournamentProxyContract = await TournamentV1.attach(
  //   tournamentProxyAddress
  // );

  const Tournamentv2 = await ethers.getContractFactory("Tournament");

  const newTournamentDeployed = await Tournamentv2.deploy();

  await newTournamentDeployed.deployed();

  const TournamentBeacon = await ethers.getContractFactory("TournamentBeacon");
  const beaconContract = await TournamentBeacon.attach(beaconAddress);
  const updateTxn = await beaconContract.update(newTournamentDeployed.address);
  await updateTxn.wait();

  // const TournamentV2 = await ethers.getContractFactory("Tournamentv2");
  // const tournamentV2ProxyContract = await TournamentV2.attach(
  //   tournamentProxyAddress
  // );
  // console.log(
  //   "URI tournament ",
  //   await tournamentV2ProxyContract.tournamentURI()
  // );

  // const txn = await tournamentV2ProxyContract.upgradeUri("new URI");
  // await txn.wait();

  // console.log(
  //   " New URI tournament ",
  //   await tournamentV2ProxyContract.tournamentURI()
  // );

  // const tournamentV2ProxyContract1 = await TournamentV2.attach(
  //   tournamentProxyAddress1
  // );
  // console.log(
  //   "URI tournament ",
  //   await tournamentV2ProxyContract1.tournamentURI()
  // );

  // const txn1 = await tournamentV2ProxyContract1.upgradeUri("new game URI");
  // await txn1.wait();

  // console.log(
  //   " New URI tournament ",
  //   await tournamentV2ProxyContract1.tournamentURI()
  // );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
