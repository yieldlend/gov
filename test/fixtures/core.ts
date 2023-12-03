import { ethers } from "hardhat";

export const e18 = BigInt(10) ** 18n;

export async function deployFixture() {
  // Contracts are deployed using the first signer/account by default
  const [owner, otherAccount] = await ethers.getSigners();

  const YieldLend = await ethers.getContractFactory("YieldLend");
  const token = await YieldLend.deploy();

  const VestedYieldLend = await ethers.getContractFactory("VestedYieldLend");
  const vestedToken = await VestedYieldLend.deploy();

  const YieldLocker = await ethers.getContractFactory("YieldLocker");
  const yieldLocker = await YieldLocker.deploy(token.target);

  const BondingCurve = await ethers.getContractFactory("BondingCurveSale");
  const bondingCurveSale = await BondingCurve.deploy(vestedToken.target, 1);

  const StreamedVesting = await ethers.getContractFactory("StreamedVesting");
  const streamedVesting = await StreamedVesting.deploy();

  const BonusPool = await ethers.getContractFactory("BonusPool");
  const bonusPool = await BonusPool.deploy(
    token.target,
    streamedVesting.target
  );

  await streamedVesting.initialize(
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
  await token.transfer(streamedVesting.target, 20n * supply);

  // send 47% for emissions
  await token.transfer(streamedVesting.target, 20n * supply);

  return {
    token,
    bonusPool,
    streamedVesting,
    vestedToken,
    owner,
    yieldLocker,
    otherAccount,
    bondingCurveSale,
  };
}
