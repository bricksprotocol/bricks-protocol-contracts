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
const token = config.mumbaiTest.daiToken;
const aToken = config.mumbaiTest.adaiToken;
async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  await run("compile");

  const signers = await ethers.getSigners();
  //console.log("Owner", owner.address);

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
  const createFactory = createTournamentFactory.attach(
    "0xB49225C9A62Dfd05e5E8AaFD5BE25DA58581a965"
  );
  const tournamentLength: any = await createFactory.getCount();
  const tournamentFactory = await ethers.getContractFactory("Tournament");
  const tournament = tournamentFactory.attach(
    "0xEF3994C94B7d34b45A79D027268fE9159bCD4575"
  );
  console.log("Total Balance Amount", await tournament.totalBalance());
  console.log(
    "Total Withdrawn Amount",
    await tournament.totalWithdrawnAmountFn()
  );

  for (let i = 0; i < signers.length; i++) {
    console.log(
      `Participant reward mapping ${signers[i].address}`,
      await tournament.connect(signers[i]).participantRewardMappingFn()
    );
  }

  //   console.log(
  //     await tournament
  //       .connect("0x1cD2e346dF8171C610987255d0061b41c8a2B1cD")
  //       .computeEntryFeesWithRewards(7960)
  //   );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
