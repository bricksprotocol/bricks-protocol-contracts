import { run, ethers } from "hardhat";
import { config } from "../config";
import Web3 from "web3";
import usdcAbi from "../abis/usdc.json";
import EthCrypto from "eth-crypto";

let ENTRY_FEES: any = Web3.utils.toWei("5", "ether");
const tournamentAddress = "0x748FA8396603608B61c47000e05C8eb735D04ae0";
const token = config.mumbaiTest.daiToken;
const aToken = config.mumbaiTest.adaiToken;

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

  // const signerIdentity = EthCrypto.createIdentity();
  // const message = EthCrypto.hash.keccak256([{ type: "uint256", value: "40" }]);
  // console.log("pvt key", signerIdentity.privateKey);
  // const signature = EthCrypto.sign(signerIdentity.privateKey, message);

  //await new Promise((r) => setTimeout(r, 900 * 1000));
  const message: number = 40;
  const messageHash = ethers.utils.solidityKeccak256(
    ["string"],
    [message.toString()]
  );
  const signature = await owner.signMessage(ethers.utils.arrayify(messageHash));
  console.log("Signature ", signature);
  const signatureVerification = await tournament.verifyMessage("40", signature);
  console.log("verification ", signatureVerification);
  const firstAddressTournamentEntry = await tournament.withdrawFunds(
    40,
    signature
  );
  await firstAddressTournamentEntry.wait();
  // const secondAddressTournamentEntry = await tournament
  //   .connect(secondOwner)
  //   .withdrawFunds(60);
  // await secondAddressTournamentEntry.wait();

  //   const secondAddressTournamentEntry = await tournament
  //     .connect(secondOwner)
  //     .withdrawFunds(60);
  //   await secondAddressTournamentEntry.wait();

  console.log(
    "First Address Balance ",
    await daiToken.balanceOf(owner.address)
  );
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
