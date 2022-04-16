import { run, ethers } from "hardhat";
import { config } from "../config";
import Web3 from "web3";
import usdcAbi from "../abis/usdc.json";

let ENTRY_FEES: any = Web3.utils.toWei("5", "ether");
const tournamentAddress = "0xB01290cf052bEfcf619E2242bFB2Dfc04664C654";
async function main() {
  await run("compile");

  const tournamentFactory = await ethers.getContractFactory("Tournament");
  const tournament = tournamentFactory.attach(tournamentAddress);

  const [owner, secondOwner] = await ethers.getSigners();
  console.log("Owner", owner.address, secondOwner.address);

  console.log(
    "Asset",
    await tournament.asset(),
    "LP address ",
    await tournament.lending_pool_address()
  );
  const adaiToken = new ethers.Contract(config.kovan.adaiToken, usdcAbi, owner);
  const daiToken = new ethers.Contract(config.kovan.daiToken, usdcAbi, owner);

  console.log("Balance ", await adaiToken.balanceOf(tournamentAddress));

  //await new Promise((r) => setTimeout(r, 900 * 1000));

  const firstAddressTournamentEntry = await tournament.withdrawFunds(40);
  await firstAddressTournamentEntry.wait();
  const secondAddressTournamentEntry = await tournament
    .connect(secondOwner)
    .withdrawFunds(60);
  await secondAddressTournamentEntry.wait();

  //   const secondAddressTournamentEntry = await tournament
  //     .connect(secondOwner)
  //     .withdrawFunds(60);
  //   await secondAddressTournamentEntry.wait();

  console.log(
    "First Address Balance ",
    await daiToken.balanceOf(owner.address)
  );

  console.log(
    "Second Address Balance ",
    await daiToken.balanceOf(secondOwner.address)
  );
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
