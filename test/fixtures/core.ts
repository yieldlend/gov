import { ethers } from "hardhat";

export const e18 = BigInt(10) ** 18n;

export async function deployFixture() {
  // Contracts are deployed using the first signer/account by default
  const [owner, otherAccount, vault] = await ethers.getSigners();

  const YieldLend = await ethers.getContractFactory("YieldLend");
  const token = await YieldLend.connect(owner).deploy();

  const VestedYieldLend = await ethers.getContractFactory("VestedYieldLend");
  const vestedToken = await VestedYieldLend.deploy();

  const YieldLocker = await ethers.getContractFactory("YieldLocker");
  const locker = await YieldLocker.deploy(token.target);

  const MockAggregator = await ethers.getContractFactory("MockAggregator");
  const mockOracle = await MockAggregator.deploy(2100n * 10n ** 8n);

  const FeeDistributor = await ethers.getContractFactory("FeeDistributor");
  const feeDistributor = await FeeDistributor.deploy();

  const StakingEmissions = await ethers.getContractFactory("StakingEmissions");
  const stakingEmissions = await StakingEmissions.deploy();

  const BondingCurve = await ethers.getContractFactory("BondingCurveSale");
  const sale = await BondingCurve.deploy(
    token.target, // address _destination,
    mockOracle.target, // address _ethUsdPrice,
    vestedToken.target, // IERC20 _token,
    e18 * 1500n, // uint256 _ethToRaise,
    e18 * 10000000000n, // uint256 _reserveInLP,
    e18 * 20000000000n // uint256 _reserveToSell
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

  await feeDistributor.initialize(locker.target, vestedToken.target);
  await stakingEmissions.initialize(
    feeDistributor.target,
    vestedToken.target,
    4807692n * e18
  );

  const supply = (100000000000n * e18) / 100n;

  // fund 5% unvested to staking bonus
  await token.transfer(bonusPool.target, 5n * supply);

  // send 10% to liquidity
  await token.transfer(token.target, 10n * supply);

  // send 20% vested tokens to bonding curve
  await token.transfer(vesting.target, 20n * supply);
  await vestedToken.transfer(sale.target, 20n * supply);

  // send 10% vested tokens to the staking contract
  await token.transfer(vesting.target, 10n * supply);
  await vestedToken.transfer(stakingEmissions.target, 10n * supply);

  // send 47% for emissions
  await token.transfer(vesting.target, 47n * supply);
  await vestedToken.transfer(vault.address, 47n * supply);

  // whitelist the bonding sale contract
  await vestedToken.addwhitelist(sale.target, true);
  await vestedToken.addwhitelist(stakingEmissions.target, true);
  await vestedToken.addwhitelist(feeDistributor.target, true);
  await token.bulkExcludeFromFees(
    [vesting.target, locker.target, bonusPool.target],
    true
  );

  // start vesting and staking emissions (for test)
  await vesting.start();
  await stakingEmissions.start();

  return {
    bonusPool,
    ethers,
    feeDistributor,
    locker,
    otherAccount,
    owner,
    sale,
    stakingEmissions,
    token,
    vestedToken,
    vesting,
  };
}
