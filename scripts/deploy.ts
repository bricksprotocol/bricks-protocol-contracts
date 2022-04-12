// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { run, ethers } from "hardhat";
import { config } from "../config";
import Web3 from "web3";
import wethAbi from "../abis/weth.json";
const ETHERSCAN_TX_URL = "https://kovan.etherscan.io/tx/";
const ENTRY_FEES = Web3.utils.toWei("0.0001", "ether");
const INITIAL_INVESTED_AMOUNT = Web3.utils.toWei("0.001", "ether");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  await run("compile");

  const lendingPoolProviderAddress = config.kovan.lendingPoolAddressesProvider;
  // We get the contract to deploy
  const createTournamentFactory = await ethers.getContractFactory(
    "CreateTournamentFactory"
  );

  const rpc = await new ethers.providers.JsonRpcProvider(
    process.env.RPC_ENDPOINT
  );
  const privateKey = process.env.PRIVATE_KEY as any;
  const wallet = new ethers.Wallet(privateKey, rpc);

  const wethToken = new ethers.Contract(
    config.kovan.wethToken,
    wethAbi,
    wallet
  );

  const tournamentFactory = await createTournamentFactory.deploy();

  await tournamentFactory.deployed();

  console.log("Tournament Factory deployed to:", tournamentFactory.address);

  await tournamentFactory.setLendingPoolAddressProvider(
    lendingPoolProviderAddress
  );

  console.log(
    "Lending Address",
    await tournamentFactory.getLendingPoolAddressProvider()
  );

  await tournamentFactory.createTournamentPool(
    "URI",
    1660012433,
    1661012433,
    ENTRY_FEES,
    config.kovan.wethToken,
    INITIAL_INVESTED_AMOUNT
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
