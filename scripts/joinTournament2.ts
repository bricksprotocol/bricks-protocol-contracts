import { run, ethers } from "hardhat";
import { config } from "../config";
import Web3 from "web3";
import usdcAbi from "../abis/usdc.json";

let ENTRY_FEES: any = Web3.utils.toWei("5", "ether");
const tournamentAddress = "0x09E3823795C50cE47153409d0EeA0f33317b943D";
const token = config.mumbaiTest.daiToken;
const aToken = config.mumbaiTest.adaiToken;

async function main() {
  await run("compile");

  const tournamentFactory = await ethers.getContractFactory("Tournament");
  const tournament = tournamentFactory.attach(tournamentAddress);

  const [owner, secondOwner] = await ethers.getSigners();
  console.log("Owner", owner.address, secondOwner.address);
  const daiToken = new ethers.Contract(token, usdcAbi, secondOwner);
  //ENTRY_FEES = 0.01 * 10 ** 8;

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
  //const options = { value: ENTRY_FEES };

  const secondAddressTournamentEntry = await tournament
    .connect(secondOwner)
    .joinTournament();
  await secondAddressTournamentEntry.wait();

  // console.log(
  //   await tournament.connect(secondOwner).participants(1),
  //   " ",
  //   await tournament.connect(secondOwner).participants(0)
  // );

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
