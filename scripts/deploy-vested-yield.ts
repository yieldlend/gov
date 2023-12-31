import hre from "hardhat";

// An example of a deploy script that will deploy and call a simple contract.
async function main() {
  console.log(`Running deploy script for the token contract`);

  // Create deployer object and load the artifact of the contract you want to deploy.
  const [deployer] = await hre.ethers.getSigners();
  console.log("deployer", deployer.address);

  // const factory = await hre.ethers.getContractFactory("VestedYieldLend");
  // const contract = await factory.deploy();

  // await contract.waitForDeployment();

  // console.log(`deployed to ${greeterContract.address}`);
  await hre.run("verify:verify", {
    address: "0x3F7A11bb98959966260347233BFE6559a1067dbf",
    constructorArguments: [],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
