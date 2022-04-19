import { run, ethers } from "hardhat";
import { config } from "../config";
import Web3 from "web3";
import usdcAbi from "../abis/usdc.json";

let ENTRY_FEES: any = Web3.utils.toWei("5", "ether");
const tournamentAddress = "0xda8D72c67A543B1F5177d411D94d5fC7CBB817Cf";
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

  await daiToken.approve(
    tournamentAddress,
    // ethers.utils.parseEther("0.001")
    ethers.BigNumber.from(ENTRY_FEES).toString()
  );

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
