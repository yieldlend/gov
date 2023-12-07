import { ethers } from "hardhat";

export const e18 = BigInt(10) ** 18n;

export async function deployFixture() {
  // Contracts are deployed using the first signer/account by default
  const [owner, otherAccount] = await ethers.getSigners();

  const YieldLend = await ethers.getContractFactory("YieldLend");
  const token = await YieldLend.connect(owner).deploy();

  const VestedYieldLend = await ethers.getContractFactory("VestedYieldLend");
  const vestedToken = await VestedYieldLend.deploy();

  const YieldLocker = await ethers.getContractFactory("YieldLocker");
  const yieldLocker = await YieldLocker.deploy(token.target);

  const MockAggregator = await ethers.getContractFactory("MockAggregator");
  const mockOracle = await MockAggregator.deploy(2100n * 10n ** 8n);

  const BondingCurve = await ethers.getContractFactory("BondingCurveSale");
  const bondingCurveSale = await BondingCurve.deploy(
    token.target, // address _destination,
    mockOracle.target, // address _ethUsdPrice,
    vestedToken.target, // IERC20 _token,
    e18 * 500n, // uint256 _ethToRaise,
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
    yieldLocker.target,
    bonusPool.target
  );

  // fund 5% to staking bonus
  const supply = 1000000n * e18;
  await token.transfer(bonusPool.target, 5n * supply);

  // send 10% to liquidity
  await token.transfer(token.target, 10n * supply);

  // send 20% vested tokens to bonding curve
  await vestedToken.transfer(bondingCurveSale.target, 20n * supply);
  await token.transfer(vesting.target, 20n * supply);

  // send 47% for emissions
  await token.transfer(vesting.target, 20n * supply);

  // whitelist the bonding sale contract
  await vestedToken.addwhitelist(bondingCurveSale.target, true);
  await token.excludeFromFees(vesting.target, true);

  return {
    token,
    bonusPool,
    vesting,
    vestedToken,
    owner,
    yieldLocker,
    otherAccount,
    bondingCurveSale,
  };
}
