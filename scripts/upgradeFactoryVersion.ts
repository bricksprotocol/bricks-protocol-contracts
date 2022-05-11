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
  const proxyAddress = "0xBCd9EE9b73d3CD71DAB461d257d7004E5fcBa796";
  const tournamentProxyAddress = "0x8E9a3F49bB9F5Bc500895554eEC31135eA280Cb1";
  const tournamentProxyAddress1 = "0xC21248856F1d1bE99714C9fc8E560968c827701f";
  const beaconAddress = "0x58fCC459004FCeA57EE34b41e0B0264548Bf419f";
  const FactoryV2 = await ethers.getContractFactory(
    "CreateTournamentFactoryv2"
  );
  console.log("upgrade to CreateTournamentFactoryv2...");
  const factoryV2 = await upgrades.upgradeProxy(proxyAddress, FactoryV2);
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

  // const TournamentV1 = await ethers.getContractFactory("Tournament");
  // const tournamentProxyContract = await TournamentV1.attach(
  //   tournamentProxyAddress
  // );

  const Tournamentv2 = await ethers.getContractFactory("Tournamentv2");

  const newTournamentDeployed = await Tournamentv2.deploy();

  await newTournamentDeployed.deployed();

  const TournamentBeacon = await ethers.getContractFactory("TournamentBeacon");
  const beaconContract = await TournamentBeacon.attach(beaconAddress);
  const updateTxn = await beaconContract.update(newTournamentDeployed.address);
  await updateTxn.wait();

  const TournamentV2 = await ethers.getContractFactory("Tournamentv2");
  const tournamentV2ProxyContract = await TournamentV2.attach(
    tournamentProxyAddress
  );
  console.log(
    "URI tournament ",
    await tournamentV2ProxyContract.tournamentURI()
  );

  const txn = await tournamentV2ProxyContract.upgradeUri("new URI");
  await txn.wait();

  console.log(
    " New URI tournament ",
    await tournamentV2ProxyContract.tournamentURI()
  );

  const tournamentV2ProxyContract1 = await TournamentV2.attach(
    tournamentProxyAddress1
  );
  console.log(
    "URI tournament ",
    await tournamentV2ProxyContract1.tournamentURI()
  );

  const txn1 = await tournamentV2ProxyContract1.upgradeUri("new game URI");
  await txn1.wait();

  console.log(
    " New URI tournament ",
    await tournamentV2ProxyContract1.tournamentURI()
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
