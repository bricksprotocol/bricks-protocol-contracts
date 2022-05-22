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
import { CreateTournamentFactory } from "../typechain";
const ETHERSCAN_TX_URL = "https://kovan.etherscan.io/tx/";
let ENTRY_FEES: any = Web3.utils.toWei("5", "ether");
let INITIAL_INVESTED_AMOUNT: any = Web3.utils.toWei("50", "ether");
const token = config.mumbaiTest.daiToken;
const aToken = config.mumbaiTest.adaiToken;
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

  const tournament = await ethers.getContractFactory("Tournament");

  const tournamentDeployed = await tournament.connect(owner).deploy();

  await tournamentDeployed.connect(owner).deployed();

  console.log("tournament");

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
  //   const tournamentFactory = await createTournamentFactory
  //     .connect(owner)
  //     .deploy();

  //   await tournamentFactory.connect(owner).deployed();

  //   console.log("Tournament Factory deployed to:", tournamentFactory.address);
  //console.log("Tr address", tournamentDeployed.address);

  const tournamentFactory = createTournamentFactory.attach(
    "0xc8869C6Ef8163AbCF178c775D9ad4aA3371B3Bee"
  );

  // const tournamentFactory = await upgrades.deployProxy(
  //   createTournamentFactory,
  //   [tournamentDeployed.address]
  // );
  // const tournamentFactory = await createTournamentFactory
  //   .connect(owner)
  //   .deploy(tournamentDeployed.address);

  //await tournamentFactory.deployed();

  //console.log(tournamentFactory.address, " proxy address");

  //console.log("Beacon Imp ", await tournamentFactory.getImplementation());
  //   console.log(
  //     await upgrades.erc1967.getImplementationAddress(tournamentFactory.address),
  //     " getImplementationAddress"
  //   );
  //   console.log(
  //     await upgrades.erc1967.getAdminAddress(tournamentFactory.address),
  //     " getAdminAddress"
  //   );

  const approveTxn = await daiToken.approve(
    tournamentFactory.address,
    // ethers.utils.parseEther("0.001")
    ethers.BigNumber.from(Web3.utils.toWei("120", "ether")).toString()
  );
  await approveTxn.wait();

  // console.log(
  //   await wethToken.allowance(owner.address, tournamentFactory.address)
  // );
  const transaction = await tournamentFactory.setLendingPoolAddressProvider(
    lendingPoolProviderAddress
  );
  await transaction.wait();

  // const verificationTransaction = await tournamentFactory
  //   .connect(owner)
  //   .setVerificationAddress(verifyFactory.address);
  // await verificationTransaction.wait();

  console.log(
    "Lending Address",
    await tournamentFactory.getLendingPoolAddressProvider()
  );

  console.log("beacon address ", await tournamentFactory.tournamentBeacon());
  //const options = { value: Web3.utils.toWei("0.01", "ether") };
  // ENTRY_FEES = 0.01 * 10 ** 8;
  //INITIAL_INVESTED_AMOUNT = 0.1 * 10 ** 8;
  const createPoolTxn = await tournamentFactory
    .connect(owner)
    .createTournamentPool(
      "URI",
      1651840820,
      1651841195,
      ENTRY_FEES,
      token,
      INITIAL_INVESTED_AMOUNT,
      aToken,
      false
    );

  await createPoolTxn.wait();

  // const createPoolTxn2 = await tournamentFactory
  //   .connect(owner)
  //   .createTournamentPool(
  //     "Game URI",
  //     1651840820,
  //     1651841195,
  //     ENTRY_FEES,
  //     token,
  //     INITIAL_INVESTED_AMOUNT,
  //     aToken,
  //     false
  //   );

  // await createPoolTxn2.wait();

  // console.log("created");
  // // const firstAddressInitialBalance = await wethToken.balanceOf(owner.address);
  // // const secondAddressInitialBalance = await wethToken.balanceOf(
  // //   secondOwner.address
  // // );

  const tournamentAddress = await tournamentFactory
    .connect(owner)
    .tournamentsArray(0);
  console.log("Proxy Tournament Adress-1", tournamentAddress);

  // const tournamentAddress2 = await tournamentFactory
  //   .connect(owner)
  //   .tournamentsArray(1);

  // console.log("Proxy Tournament Address-2", tournamentAddress2);

  // const adaiToken = new ethers.Contract(aToken, usdcAbi, owner);

  // console.log(
  //   "Tournament Balance ",
  //   await adaiToken.balanceOf(tournamentAddress)
  // );

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
