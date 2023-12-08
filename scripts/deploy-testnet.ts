import hre, { ethers } from "hardhat";
import { e18 } from "../test/fixtures/core";

// An example of a deploy script that will deploy and call a simple contract.
async function main() {
  // Contracts are deployed using the first signer/account by default
  const [owner] = await ethers.getSigners();

  const YieldLend = await ethers.getContractFactory("YieldLend");
  const token = await YieldLend.connect(owner).deploy();

  const VestedYieldLend = await ethers.getContractFactory("VestedYieldLend");
  const vestedToken = await VestedYieldLend.deploy();

  const YieldLocker = await ethers.getContractFactory("YieldLocker");
  const locker = await YieldLocker.deploy(token.target);

  const MockAggregator = await ethers.getContractFactory("MockAggregator");
  const mockOracle = await MockAggregator.deploy(2100n * 10n ** 8n);

  const BondingCurve = await ethers.getContractFactory("BondingCurveSale");
  const sale = await BondingCurve.deploy(
    token.target, // address _destination,
    mockOracle.target, // address _ethUsdPrice,
    vestedToken.target, // IERC20 _token,
    e18 * 1500n, // uint256 _ethToRaise,
    e18 * 10000000n, // uint256 _reserveInLP,
    e18 * 20000000n // uint256 _reserveToSell
  );

  const StreamedVesting = await ethers.getContractFactory("StreamedVesting");
  const vesting = await StreamedVesting.deploy();

  const BonusPool = await ethers.getContractFactory("BonusPool");
  const bonusPool = await BonusPool.deploy(token.target, vesting.target);

  await vesting.initialize(
    token.target,
    vestedToken.target,
    locker.target,
    bonusPool.target
  );

  // fund 5% to staking bonus
  const supply = 1000000n * e18;
  await token.transfer(bonusPool.target, 5n * supply);

  // send 10% to liquidity
  await token.transfer(token.target, 10n * supply);

  // send 20% vested tokens to bonding curve
  await vestedToken.transfer(sale.target, 20n * supply);
  await token.transfer(vesting.target, 20n * supply);

  // send 47% for emissions
  await token.transfer(vesting.target, 20n * supply);

  // whitelist the bonding sale contract
  await vestedToken.addwhitelist(sale.target, true);
  await token.bulkExcludeFromFees(
    [vesting.target, locker.target, bonusPool.target],
    true
  );

  await hre.run("verify:verify", {
    address: token.target,
    constructorArguments: [],
  });
  await hre.run("verify:verify", {
    address: vestedToken.target,
    constructorArguments: [],
  });
  await hre.run("verify:verify", {
    address: locker.target,
    constructorArguments: [token.target],
  });
  await hre.run("verify:verify", {
    address: vesting.target,
    constructorArguments: [token.target],
  });
  await hre.run("verify:verify", {
    address: bonusPool.target,
    constructorArguments: [token.target, vesting.target],
  });
  await hre.run("verify:verify", {
    address: sale.target,
    constructorArguments: [
      token.target, // address _destination,
      mockOracle.target, // address _ethUsdPrice,
      vestedToken.target, // IERC20 _token,
      e18 * 1500n, // uint256 _ethToRaise,
      e18 * 10000000n, // uint256 _reserveInLP,
      e18 * 20000000n, // uint256 _reserveToSell
    ],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
