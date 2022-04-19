// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { run, ethers } from "hardhat";
import { config } from "../config";
import Web3 from "web3";
import wethAbi from "../abis/weth.json";
import usdcAbi from "../abis/usdc.json";
import adaiAbi from "../abis/adai.json";
import { makeTransferProxyAdminOwnership } from "@openzeppelin/hardhat-upgrades/dist/admin";

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  await run("compile");

  const [owner, secondOwner] = await ethers.getSigners();
  console.log("Owner", owner.address);

  const usdcToken = new ethers.Contract(
    "0x2058a9d7613eee744279e3856ef0eada5fcbaa7e",
    usdcAbi,
    owner
  );

  console.log("User Balance ", await usdcToken.balanceOf(owner.address));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
