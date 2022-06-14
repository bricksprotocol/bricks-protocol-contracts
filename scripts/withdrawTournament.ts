import { config as dotEnvConfig } from "dotenv";
dotEnvConfig();
import { run, ethers } from "hardhat";
import { config } from "../config";
import Web3 from "web3";
import usdcAbi from "../abis/usdc.json";
import EthCrypto from "eth-crypto";
import Tournament from "../artifacts/contracts/Tournament.sol/Tournament.json";
import { AbiItem } from "web3-utils";

let ENTRY_FEES: any = Web3.utils.toWei("5", "ether");
const tournamentAddress = "0xE7718026996b1C1D8fdC10236a1a170d9827a96C";
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
  const tx = myContract.methods.setParticipantReward(
    rewardValue,
    participantAddress
  );
  const gas = await tx.estimateGas({ from: ownerAddress });
  const gasPrice = await web3.eth.getGasPrice();
  const data = tx.encodeABI();
  //const nonce = await web3.eth.getTransactionCount(ownerAddress);

  const signedTx = await web3.eth.accounts.signTransaction(
    {
      to: myContract.options.address,
      data,
      gas,
      //gasPrice,
      //nonce,
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
  //const nonce = await web3.eth.getTransactionCount(ownerAddress);

  const signedTx = await web3.eth.accounts.signTransaction(
    {
      to: myContract.options.address,
      data,
      gas,
      //gasPrice,
      // nonce,
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

  const signers = await ethers.getSigners();
  const messages = [1000, 1200, 1100, 180, 190, 200, 300, 4000, 830, 1000];
  let ownerBalance = 0;
  for (let i = 0; i < signers.length; i++) {
    //console.log("Owner", owner.address, secondOwner.address);
    console.log("Tr owner ", await tournament.owner());
    // console.log(
    //   "Asset",
    //   await tournament.asset(),
    //   "LP address ",
    //   await tournament.lending_pool_address()
    // );
    const adaiToken = new ethers.Contract(aToken, usdcAbi, signers[i]);
    const daiToken = new ethers.Contract(token, usdcAbi, signers[i]);

    console.log("Balance ", await adaiToken.balanceOf(tournamentAddress));

    // const signerIdentity = EthCrypto.createIdentity();
    // const message = EthCrypto.hash.keccak256([{ type: "uint256", value: "40" }]);
    // console.log("pvt key", signeyrIdentity.privateKey);
    // const signature = EthCrypto.sign(signerIdentity.privateKey, message);

    //await new Promise((r) => setTimeout(r, 900 * 1000));
    const message: number = messages[i];
    const messageHash = ethers.utils.solidityKeccak256(
      ["string"],
      [message.toString()]
    );

    await executeAdminTxn(signers[0].address, message, signers[i].address);
    const signature = await signers[i].signMessage(
      ethers.utils.arrayify(messageHash)
    );
    console.log("Signature ", signature);
    // const signatureVerification = await tournament.verifyMessage(
    //   "4037",
    //   signature
    // );
    // console.log("verification ", signatureVerification);

    const intiialBalance = await daiToken.balanceOf(signers[i].address);
    console.log(`Signer-${i + 1} Address Intiital Balance `, intiialBalance);
    console.log(
      `Signer-${i + 1} Has withdrawn `,
      await tournament.connect(signers[i]).hasUserWithdrawn()
    );
    console.log(
      `Signer-${i + 1} Completion status`,
      await tournament.connect(signers[i]).isCompleted()
    );
    // if (!(await tournament.connect(signers[i]).isCompleted())) {
    //   console.log("Owner", await tournament.owner());
    //   await executeAdminTxnForCompletionStatus(signers[0].address);
    // }
    //await executeAdminTxnForCompletionStatus(signers[0].address);

    console.log(
      `Signer-${i + 1} Completion status`,
      await tournament.connect(signers[i]).isCompleted()
    );
    const firstAddressTournamentEntry = await tournament
      .connect(signers[i])
      .withdrawFunds(signature);
    await firstAddressTournamentEntry.wait();
    console.log(
      `Signer-${i + 1} Has withdrawn `,
      await tournament.connect(signers[i]).hasUserWithdrawn()
    );

    // const secondAddressTournamentEntry = await tournament
    //   .connect(secondOwner)
    //   .withdrawFunds(60);
    // await secondAddressTournamentEntry.wait();

    //   const secondAddressTournamentEntry = await tournament
    //     .connect(secondOwner)
    //     .withdrawFunds(60);
    //   await secondAddressTournamentEntry.wait();

    console.log(
      `Signer-${i + 1} First Address After Balance `,
      await daiToken.balanceOf(signers[i].address)
    );

    if (i === 0) {
      ownerBalance = await daiToken.balanceOf(signers[i].address);
    }

    console.log(
      `Signer-${i + 1} Balance Diff `,
      (await daiToken.balanceOf(signers[i].address)) - intiialBalance
    );
  }
  const daiToken = new ethers.Contract(token, usdcAbi, signers[0]);

  console.log("Withdrawing protocol fees ");
  const protocolWithdrawalTxn = await tournament
    .connect(signers[0])
    .withdrawProtocolFees();
  console.log(
    "After protocol withdrawal baalance ",
    await daiToken.balanceOf(signers[0].address)
  );
  await protocolWithdrawalTxn.wait();

  console.log(
    "After protocol withdrawal balance diff ",
    (await daiToken.balanceOf(signers[0].address)) - ownerBalance
  );
}
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
