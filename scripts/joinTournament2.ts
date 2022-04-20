import { run, ethers } from "hardhat";
import { config } from "../config";
import Web3 from "web3";
import usdcAbi from "../abis/usdc.json";

let ENTRY_FEES: any = Web3.utils.toWei("0.001", "ether");
const tournamentAddress = "0x20091649CD716f403497fbf00778586267eDeF80";
const token = config.mumbaiTest.wmaticToken;
const aToken = config.mumbaiTest.aWmaticToken;

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
  const options = { value: ethers.utils.parseEther("0.001") };

  const secondAddressTournamentEntry = await tournament
    .connect(secondOwner)
    .joinTournament(options);
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
