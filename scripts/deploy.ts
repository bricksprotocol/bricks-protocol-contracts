// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { run, ethers } from "hardhat";
import { config } from "../config";
import Web3 from "web3";
import wethAbi from "../abis/weth.json";
import usdcAbi from "../abis/usdc.json";
import adaiAbi from "../abis/adai.json";
import { makeTransferProxyAdminOwnership } from "@openzeppelin/hardhat-upgrades/dist/admin";
const ETHERSCAN_TX_URL = "https://kovan.etherscan.io/tx/";
let ENTRY_FEES: any = Web3.utils.toWei("5", "ether");
let INITIAL_INVESTED_AMOUNT: any = Web3.utils.toWei("50", "ether");
const token = config.mumbaiTest.usdtToken;
const aToken = config.mumbaiTest.ausdtToken;
async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  await run("compile");

  const [owner, secondOwner] = await ethers.getSigners();
  console.log("Owner", owner.address);

  const lendingPoolProviderAddress =
    config.mumbaiTest.lendingPoolAddressesProvider;
  // We get the contract to deploy
  const createTournamentFactory = await ethers.getContractFactory(
    "CreateTournamentFactory"
  );

  // const verifyContractFactory = await ethers.getContractFactory("Verify");
  // const verifyFactory = await verifyContractFactory.connect(owner).deploy();

  // await verifyFactory.connect(owner).deployed();

  // console.log("Verify address ", verifyFactory.address);
  const provider = await new ethers.providers.JsonRpcProvider(
    process.env.RPC_ENDPOINT
  );
  const privateKey = process.env.PRIVATE_KEY as any;
  const wallet = new ethers.Wallet(privateKey, provider);

  //const wethToken = new ethers.Contract(config.kovan.wethToken, wethAbi, owner);

  const daiToken = new ethers.Contract(token, usdcAbi, owner);
  const tournamentFactory = await createTournamentFactory
    .connect(owner)
    .deploy();

  await tournamentFactory.connect(owner).deployed();

  console.log("Tournament Factory deployed to:", tournamentFactory.address);

  await daiToken.approve(
    tournamentFactory.address,
    // ethers.utils.parseEther("0.001")
    INITIAL_INVESTED_AMOUNT
  );

  // console.log(
  //   await wethToken.allowance(owner.address, tournamentFactory.address)
  // );
  const transaction = await tournamentFactory
    .connect(owner)
    .setLendingPoolAddressProvider(lendingPoolProviderAddress);
  await transaction.wait();

  // const verificationTransaction = await tournamentFactory
  //   .connect(owner)
  //   .setVerificationAddress(verifyFactory.address);
  // await verificationTransaction.wait();

  console.log(
    "Lending Address",
    await tournamentFactory.getLendingPoolAddressProvider()
  );
  // const options = { value: ethers.utils.parseEther("0.001") };
  ENTRY_FEES = 5 * 10 ** 6;
  INITIAL_INVESTED_AMOUNT = 50 * 10 ** 6;
  const createPoolTxn = await tournamentFactory
    .connect(owner)
    .createTournamentPool(
      "URI",
      1650011248,
      1650011596,
      ENTRY_FEES,
      token,
      INITIAL_INVESTED_AMOUNT,
      aToken
      // options
    );

  await createPoolTxn.wait();

  // console.log("created");
  // // const firstAddressInitialBalance = await wethToken.balanceOf(owner.address);
  // // const secondAddressInitialBalance = await wethToken.balanceOf(
  // //   secondOwner.address
  // // );

  const tournamentAddress = await tournamentFactory
    .connect(owner)
    .tournamentsArray(0);
  console.log("Adress", tournamentAddress);

  const adaiToken = new ethers.Contract(aToken, usdcAbi, owner);

  console.log(
    "Tournament Balance ",
    await adaiToken.balanceOf(tournamentAddress)
  );

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
