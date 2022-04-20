import { run, ethers } from "hardhat";
import { config } from "../config";
import Web3 from "web3";
import usdcAbi from "../abis/usdc.json";
import EthCrypto from "eth-crypto";

let ENTRY_FEES: any = Web3.utils.toWei("5", "ether");
const tournamentAddress = "0x20091649CD716f403497fbf00778586267eDeF80";
const token = config.mumbaiTest.wmaticToken;
const aToken = config.mumbaiTest.aWmaticToken;

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
  const adaiToken = new ethers.Contract(aToken, usdcAbi, owner);
  const daiToken = new ethers.Contract(token, usdcAbi, owner);

  console.log("Balance ", await adaiToken.balanceOf(tournamentAddress));

  const message: number = 60;
  const messageHash = ethers.utils.solidityKeccak256(
    ["string"],
    [message.toString()]
  );
  const signature = await secondOwner.signMessage(
    ethers.utils.arrayify(messageHash)
  );
  console.log("Signature ", signature);
  //await new Promise((r) => setTimeout(r, 900 * 1000));

  const secondAddressTournamentEntry = await tournament
    .connect(secondOwner)
    .withdrawFunds(60, signature);
  await secondAddressTournamentEntry.wait();

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
