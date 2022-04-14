import { run, ethers } from "hardhat";
import { config } from "../config";
import Web3 from "web3";

async function main() {
  await run("compile");

  const tournamentFactory = await ethers.getContractFactory("Tournament");
  const tournament = tournamentFactory.attach(
    "0xb8caeaa6d921aa42168ffc4c3f84027fc9059d55"
  );

  const [owner, secondOwner] = await ethers.getSigners();
  console.log("Owner", owner.address, secondOwner.address);

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
