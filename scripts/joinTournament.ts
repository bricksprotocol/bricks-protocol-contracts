import { run, ethers } from "hardhat";
import { config } from "../config";
import Web3 from "web3";
import usdcAbi from "../abis/usdc.json";

const tournamentAddress = "0xE41f86744E2eCcDDa6cA8DEb64B438E7f5530e6E";
const token = config.mumbaiTest.daiToken;
const aToken = config.mumbaiTest.adaiToken;
let ENTRY_FEES: any = Web3.utils.toWei("5", "ether");

async function main() {
  await run("compile");

  const tournamentFactory = await ethers.getContractFactory("Tournament");
  const tournament = tournamentFactory.attach(tournamentAddress);

  const signers = await ethers.getSigners();
  //console.log("Owner", owner.address, secondOwner.address);
  // ENTRY_FEES = 0.01 * 10 ** 8;

  for (let i = 0; i < signers.length; i++) {
    const daiToken = new ethers.Contract(token, usdcAbi, signers[i]);

    const approveTxn = await daiToken.approve(
      tournamentAddress,
      // ethers.utils.parseEther("0.001")
      ethers.BigNumber.from(ENTRY_FEES).toString()
    );

    await approveTxn.wait();
    //const options = { value: ENTRY_FEES };

    const firstAddressTournamentEntry = await tournament
      .connect(signers[i])
      .joinTournament();
    await firstAddressTournamentEntry.wait();
  }

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
