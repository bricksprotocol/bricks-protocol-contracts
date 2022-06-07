import { run, ethers } from "hardhat";
import { config } from "../config";
import Web3 from "web3";
import usdcAbi from "../abis/usdc.json";
import EthCrypto from "eth-crypto";
import Tournament from "../artifacts/contracts/Tournament.sol/Tournament.json";
import { AbiItem } from "web3-utils";

let ENTRY_FEES: any = Web3.utils.toWei("5", "ether");
const tournamentAddress = "0xcc543452dB4D56369aC6Fc681b1862B648c0013a";
const token = config.mumbaiTest.daiToken;
const aToken = config.mumbaiTest.adaiToken;
const privateKey = process.env.PRIVATE_KEY;

async function executeAdminTxn(
  ownerAddress: string,
  rewardValue: number,
  participantAddress: string
) {
  const web3 = new Web3("https://matic-mumbai.chainstacklabs.com/");
  const networkId = await web3.eth.net.getId();
  const myContract = new web3.eth.Contract(
    Tournament.abi as unknown as AbiItem[],
    tournamentAddress
  );
  web3.eth.accounts.wallet.add(privateKey!);
  const tx = myContract.methods.setParticipantReward(
    rewardValue,
    participantAddress
  );
  const gas = await tx.estimateGas({ from: ownerAddress });
  const gasPrice = await web3.eth.getGasPrice();
  const data = tx.encodeABI();
  const nonce = await web3.eth.getTransactionCount(ownerAddress);

  const signedTx = await web3.eth.accounts.signTransaction(
    {
      to: myContract.options.address,
      data,
      gas,
      gasPrice,
      nonce,
      chainId: networkId,
    },
    privateKey!
  );
  await web3.eth.sendSignedTransaction(signedTx.rawTransaction!);
}

async function executeAdminTxnForCompletionStatus(ownerAddress: string) {
  const web3 = new Web3("https://matic-mumbai.chainstacklabs.com/");
  const networkId = await web3.eth.net.getId();
  const myContract = new web3.eth.Contract(
    Tournament.abi as unknown as AbiItem[],
    tournamentAddress
  );
  const tx = myContract.methods.setCompletionStatus();
  const gas = await tx.estimateGas({ from: ownerAddress });
  const gasPrice = await web3.eth.getGasPrice();
  const data = tx.encodeABI();
  const nonce = await web3.eth.getTransactionCount(ownerAddress);

  const signedTx = await web3.eth.accounts.signTransaction(
    {
      to: myContract.options.address,
      data,
      gas,
      gasPrice,
      nonce,
      chainId: networkId,
    },
    privateKey!
  );
  //console.log(`Old data value: ${await myContract.methods.data().call()}`);
  const receipt = await web3.eth.sendSignedTransaction(
    signedTx.rawTransaction!
  );
  // console.log(`Transaction hash: ${receipt.transactionHash}`);
  //console.log(`New data value: ${await myContract.methods.data().call()}`);
}

async function main() {
  await run("compile");

  const tournamentFactory = await ethers.getContractFactory("Tournament");
  const tournament = tournamentFactory.attach(tournamentAddress);

  const [owner, secondOwner] = await ethers.getSigners();
  console.log("Owner", owner.address, secondOwner.address);

  // console.log(
  //   "Asset",
  //   await tournament.asset(),
  //   "LP address ",
  //   await tournament.lending_pool_address()
  // );
  const adaiToken = new ethers.Contract(aToken, usdcAbi, owner);
  const daiToken = new ethers.Contract(token, usdcAbi, owner);

  console.log("Balance ", await adaiToken.balanceOf(tournamentAddress));

  const message: number = 1500;
  const messageHash = ethers.utils.solidityKeccak256(
    ["string"],
    [message.toString()]
  );
  await executeAdminTxn(owner.address, message, secondOwner.address);
  const signature = await secondOwner.signMessage(
    ethers.utils.arrayify(messageHash)
  );
  console.log("Signature ", signature);
  //await new Promise((r) => setTimeout(r, 900 * 1000));
  console.log("Completion status", await tournament.isCompleted());
  if (!(await tournament.isCompleted())) {
    console.log("Owner", await tournament.owner());
    await executeAdminTxnForCompletionStatus(owner.address);
  }
  const secondAddressTournamentEntry = await tournament
    .connect(secondOwner)
    .withdrawFunds(signature);
  await secondAddressTournamentEntry.wait();
  console.log("Completion status", await tournament.isCompleted());
  console.log(
    "Second Address Balance ",
    await daiToken.balanceOf(secondOwner.address)
  );
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
