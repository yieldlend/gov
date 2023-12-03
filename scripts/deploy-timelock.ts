import hre from "hardhat";

// An example of a deploy script that will deploy and call a simple contract.
async function main() {
  console.log(`Running deploy script for the token contract`);

  // Create deployer object and load the artifact of the contract you want to deploy.
  const [deployer] = await hre.ethers.getSigners();
  console.log("deployer", deployer.address);

  const admin = "0x3f927868aAdb217ed137e87c44c83e4A3EB7f70B";

  const args = [
    86400 * 2, // uint256 minDelay,
    admin, // address admin,
    [admin], // address[] memory proposers,
    [admin], // address[] memory cancellors,
    ["0x0000000000000000000000000000000000000000"], // address[] memory executors
  ];

  const factory = await hre.ethers.getContractFactory("YieldLendTimelock");
  const contract = await factory.deploy(
    args[0] as number,
    args[1] as string,
    args[2] as string[],
    args[3] as string[],
    args[4] as string[]
  );

  await contract.waitForDeployment();

  console.log(`deployed to ${contract.target}`);
  await hre.run("verify:verify", {
    address: await contract.getAddress(),
    constructorArguments: args,
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
