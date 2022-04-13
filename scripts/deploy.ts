// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { run, ethers } from "hardhat";
import { config } from "../config";
import Web3 from "web3";
import wethAbi from "../abis/weth.json";
import { makeTransferProxyAdminOwnership } from "@openzeppelin/hardhat-upgrades/dist/admin";
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

  const [owner, secondOwner] = await ethers.getSigners();
  console.log("Owner", owner.address);

  const lendingPoolProviderAddress = config.kovan.lendingPoolAddressesProvider;
  // We get the contract to deploy
  const createTournamentFactory = await ethers.getContractFactory(
    "CreateTournamentFactory"
  );

  const provider = await new ethers.providers.JsonRpcProvider(
    process.env.RPC_ENDPOINT
  );
  const privateKey = process.env.PRIVATE_KEY as any;
  const wallet = new ethers.Wallet(privateKey, provider);

  const wethToken = new ethers.Contract(config.kovan.wethToken, wethAbi, owner);

  const tournamentFactory = await createTournamentFactory
    .connect(owner)
    .deploy();

  await tournamentFactory.connect(owner).deployed();

  console.log("Tournament Factory deployed to:", tournamentFactory.address);

  await wethToken.approve(
    tournamentFactory.address,
    ethers.utils.parseEther("0.001")
  );

  // console.log(
  //   await wethToken.allowance(owner.address, tournamentFactory.address)
  // );
  await tournamentFactory
    .connect(owner)
    .setLendingPoolAddressProvider(lendingPoolProviderAddress);

  console.log(
    "Lending Address",
    await tournamentFactory.getLendingPoolAddressProvider()
  );
  const options = { value: ethers.utils.parseEther("0.001") };
  await tournamentFactory
    .connect(owner)
    .createTournamentPool(
      "URI",
      1660012433,
      1661012433,
      ENTRY_FEES,
      config.kovan.wethToken,
      INITIAL_INVESTED_AMOUNT,
      options
    );

  // console.log("created");
  // // const firstAddressInitialBalance = await wethToken.balanceOf(owner.address);
  // // const secondAddressInitialBalance = await wethToken.balanceOf(
  // //   secondOwner.address
  // // );

  const tournamentAddress = await tournamentFactory
    .connect(owner)
    .getTournamentDetails(0);
  console.log("Adress", tournamentAddress);
  const tournament = await (
    await ethers.getContractFactory("Tournament")
  ).attach(await tournamentFactory.tournamentsArray(0));

  // const txn = await tournament.joinTournament();
  // await txn.wait();

  // const secondTxn = await tournament.connect(secondOwner).joinTournament();
  // await secondTxn.wait();

  // new Promise((resolve) => {
  //   setTimeout(resolve, 120 * 1000);
  // });

  // const withdrawTxn = await tournament.withdrawFunds(100);
  // await withdrawTxn.wait();
  // const secondWithdrawTxn = await tournament
  //   .connect(secondOwner.address)
  //   .withdrawFunds(60);
  // await secondWithdrawTxn.wait();

  // console.log(
  //   "First address amount withdrawn ",
  //   (await wethToken.balanceOf(owner.address)) - firstAddressInitialBalance
  // );

  // console.log(
  //   "Second address amount withdrawn ",
  //   (await wethToken.balanceOf(secondOwner.address)) -
  //     secondAddressInitialBalance
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
