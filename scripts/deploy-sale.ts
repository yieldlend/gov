import hre from "hardhat";
import { e18 } from "../test/fixtures/core";

// An example of a deploy script that will deploy and call a simple contract.
async function main() {
  console.log(`Running deploy script for the token contract`);

  // Create deployer object and load the artifact of the contract you want to deploy.
  const [deployer] = await hre.ethers.getSigners();
  console.log("deployer", deployer.address);

  const args: any[] = [
    "0x3f927868aAdb217ed137e87c44c83e4A3EB7f70B", // address _destination,
    "0x71041dddad3595f9ced3dccfbe3d1f4b0a16bb70", // address _ethUsdPrice,
    "0x3F7A11bb98959966260347233BFE6559a1067dbf", // IERC20 _token,
    e18 * 1500n, // uint256 _ethToRaise,
    e18 * 10000000000n, // uint256 _reserveInLP,
    e18 * 20000000000n, // uint256 _reserveToSell
  ];

  const factory = await hre.ethers.getContractFactory("BondingCurveSale");
  const contract = await factory.deploy(...args);

  await contract.waitForDeployment();

  console.log(`deployed to ${contract.target}`);
  await hre.run("verify:verify", {
    address: contract.target,
    constructorArguments: args,
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
