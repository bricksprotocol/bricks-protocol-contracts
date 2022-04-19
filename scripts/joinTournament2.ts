import { run, ethers } from "hardhat";
import { config } from "../config";
import Web3 from "web3";
import usdcAbi from "../abis/usdc.json";

let ENTRY_FEES: any = Web3.utils.toWei("5", "ether");
const tournamentAddress = "0xfdA75ABc927aeD011Cd16B5F0D1C702A9123D4d1";
const token = config.mumbaiTest.usdtToken;
const aToken = config.mumbaiTest.ausdtToken;

async function main() {
  await run("compile");

  const tournamentFactory = await ethers.getContractFactory("Tournament");
  const tournament = tournamentFactory.attach(tournamentAddress);

  const [owner, secondOwner] = await ethers.getSigners();
  console.log("Owner", owner.address, secondOwner.address);
  const daiToken = new ethers.Contract(token, usdcAbi, secondOwner);
  ENTRY_FEES = 6 * 10 ** 6;

  const approveTxn = await daiToken.approve(
    tournamentAddress,
    // ethers.utils.parseEther("0.001")
    ethers.BigNumber.from(ENTRY_FEES).toString()
  );
  await approveTxn.wait();
  // const daiToken2 = new ethers.Contract(
  //   config.kovan.daiToken,
  //   usdcAbi,
  //   secondOwner
  // );

  // await daiToken2.approve(
  //   tournamentAddress,
  //   // ethers.utils.parseEther("0.001")
  //   ENTRY_FEES
  // );

  const secondAddressTournamentEntry = await tournament
    .connect(secondOwner)
    .joinTournament();
  await secondAddressTournamentEntry.wait();

  //   const provider = await new ethers.providers.JsonRpcProvider(
  //     process.env.RPC_ENDPOINT
  //   );
  //   const privateKey = process.env.PRIVATE_KEY as any;
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
