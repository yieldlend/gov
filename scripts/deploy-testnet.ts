import hre, { ethers } from "hardhat";
import { e18 } from "../test/fixtures/core";
import { waitForTx } from "./utils";

// An example of a deploy script that will deploy and call a simple contract.
async function main() {
  // Contracts are deployed using the first signer/account by default
  const [owner] = await ethers.getSigners();

  const admin = "0x3f927868aAdb217ed137e87c44c83e4A3EB7f70B";

  const YieldLend = await ethers.getContractFactory("YieldLend");
  const token = await YieldLend.connect(owner).deploy();
  console.log("token at", token.target);

  const VestedYieldLend = await ethers.getContractFactory("VestedYieldLend");
  const vestedToken = await VestedYieldLend.deploy();
  console.log("vestedToken at", vestedToken.target);

  const YieldLocker = await ethers.getContractFactory("YieldLocker");
  const locker = await YieldLocker.deploy(token.target);
  console.log("locker at", locker.target);

  const MockAggregator = await ethers.getContractFactory("MockAggregator");
  const mockOracle = await MockAggregator.deploy(2100n * 10n ** 8n);
  console.log("mockOracle at", mockOracle.target);

  const BondingCurve = await ethers.getContractFactory("BondingCurveSale");
  const sale = await BondingCurve.deploy(
    token.target, // address _destination,
    mockOracle.target, // address _ethUsdPrice,
    vestedToken.target, // IERC20 _token,
    e18 * 1500n, // uint256 _ethToRaise,
    e18 * 10000000000n, // uint256 _reserveInLP,
    e18 * 20000000000n // uint256 _reserveToSell
  );
  console.log("sale at", sale.target);

  const StreamedVesting = await ethers.getContractFactory("StreamedVesting");
  const vesting = await StreamedVesting.deploy();
  console.log("vesting at", vesting.target);

  const BonusPool = await ethers.getContractFactory("BonusPool");
  const bonusPool = await BonusPool.deploy(token.target, vesting.target);
  console.log("bonusPool at", bonusPool.target);

  console.log("deployment done");

  await waitForTx(
    vesting.initialize(
      token.target,
      vestedToken.target,
      locker.target,
      bonusPool.target
    )
  );

  // 100000000000n
  // 1000000n
  // fund 5% to staking bonus
  const supply = (100000000000n * e18) / 100n;
  await waitForTx(token.transfer(bonusPool.target, 5n * supply));

  // send 10% to liquidity
  await waitForTx(token.transfer(token.target, 10n * supply));

  // send 20% vested tokens to bonding curve
  await waitForTx(token.transfer(vesting.target, 20n * supply));
  await waitForTx(vestedToken.transfer(sale.target, 20n * supply));

  // send 47% for emissions
  await waitForTx(token.transfer(vesting.target, 47n * supply));
  await waitForTx(vestedToken.transfer(admin, 47n * supply));

  // send 10% for staking rewards
  await waitForTx(token.transfer(vesting.target, 10n * supply));
  await waitForTx(vestedToken.transfer(admin, 10n * supply));

  // whitelist the bonding sale contract
  await waitForTx(vestedToken.addwhitelist(sale.target, true));
  await waitForTx(
    token.bulkExcludeFromFees(
      [vesting.target, locker.target, bonusPool.target],
      true
    )
  );

  // send remaining tokens to the admin wallet
  // await token.transfer(admin, 18n * supply);
  // await vestedToken.transfer(admin, 18n * supply);
  await waitForTx(vestedToken.burn(supply * 23n));

  console.log("init done");

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
    constructorArguments: [],
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
      e18 * 10000000000n, // uint256 _reserveInLP,
      e18 * 20000000000n, // uint256 _reserveToSell
    ],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
