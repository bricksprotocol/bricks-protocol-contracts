import { run, ethers } from "hardhat";
import { config } from "../config";
import Web3 from "web3";
import usdcAbi from "../abis/usdc.json";

const tournamentAddress = "0xDca0ffE9FF4968A614d2C1269B8de448771A5a89";
const token = config.mumbaiTest.daiToken;
const aToken = config.mumbaiTest.adaiToken;
let ENTRY_FEES: any = Web3.utils.toWei("0.01", "ether");

async function main() {
  await run("compile");

  const tournamentFactory = await ethers.getContractFactory("Tournament");
  const tournament = tournamentFactory.attach(tournamentAddress);

  const [owner, secondOwner] = await ethers.getSigners();
  console.log("Owner", owner.address, secondOwner.address);
  const daiToken = new ethers.Contract(token, usdcAbi, owner);
  // ENTRY_FEES = 0.01 * 10 ** 8;

  // const approveTxn = await daiToken.approve(
  //   tournamentAddress,
  //   // ethers.utils.parseEther("0.001")
  //   ethers.BigNumber.from(ENTRY_FEES).toString()
  // );

  // await approveTxn.wait();
  const options = { value: ENTRY_FEES };

  const firstAddressTournamentEntry = await tournament
    .connect(owner)
    .joinTournament(options);
  await firstAddressTournamentEntry.wait();

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

  // const secondAddressTournamentEntry = await tournament
  //   .connect(secondOwner)
  //   .joinTournament();
  // await secondAddressTournamentEntry.wait();

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
