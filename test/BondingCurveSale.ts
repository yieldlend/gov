import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { e18, deployFixture as fixture } from "./fixtures/core";

describe("BondingCurveSale", () => {
  it("Should deploy properly", async function () {
    const { sale, vestedToken, token } = await loadFixture(fixture);
    expect(await sale.token()).to.equal(vestedToken.target);
    expect(await sale.destination()).to.equal(token.target);
    expect(await sale.latestAnswer()).to.equal("0");
  });

  it("Should test bondingCurveETH function properly", async function () {
    const { sale: sale } = await loadFixture(fixture);
    expect(await sale.bondingCurveETH(e18)).to.equal(
      "26657777777777760000000000"
    );
    expect(await sale.bondingCurveETH(e18 * 100n)).to.equal(
      "2577777777777777760000000000"
    );
    expect(await sale.bondingCurveETH(e18 * 1500n)).to.equal(
      "20000000000000000000000000000"
    );
  });

  it("Should allow a user to get tokens if he invests 1 ETH properly", async function () {
    const { sale, otherAccount, vestedToken } = await loadFixture(fixture);

    expect(await vestedToken.balanceOf(otherAccount)).to.equal("0");

    await sale.connect(otherAccount).mint({ value: e18 });

    expect(await vestedToken.balanceOf(otherAccount)).to.equal(
      "26657777777777760000000000"
    );
    expect(await sale.latestAnswer()).to.equal("12600");
  });

  it("Should allow a user to get tokens if he invests 10 ETH properly", async function () {
    const { sale, otherAccount, vestedToken } = await loadFixture(fixture);

    expect(await vestedToken.balanceOf(otherAccount)).to.equal("0");
    await sale.connect(otherAccount).mint({ value: e18 * 10n });

    expect(await vestedToken.balanceOf(otherAccount)).to.equal(
      "265777777777777760000000000"
    );
    expect(await sale.latestAnswer()).to.equal("126000");
  });

  describe("Test Referral system", () => {
    it("Should generate referral code properly", async function () {
      const { sale, otherAccount: other, owner } = await loadFixture(fixture);
      expect(await sale.referralCode(other.address)).eq("15449397688776");
      expect(await sale.referralCode(owner.address)).eq("133934255514214");
    });

    it("Should accumulate referral earnings properly", async function () {
      const { sale, otherAccount, owner, ethers } = await loadFixture(fixture);

      const referralCode = await sale.referralCode(owner.address);
      await sale
        .connect(otherAccount)
        .mintWithReferral(referralCode, { value: e18 * 10n });

      expect(await sale.referralEarnings(referralCode)).eq(e18); // should have earned 1eth

      const balBefore = await owner.provider.getBalance(owner.address);
      await sale.connect(owner).claimReferralRewards();
      const balAfter = await owner.provider.getBalance(owner.address);

      // should have at least 0.99 eth more
      await expect(balAfter - balBefore).greaterThan((e18 * 99n) / 100n);

      // should revert second claim and random claims
      await expect(sale.connect(owner).claimReferralRewards()).revertedWith(
        "no earnings"
      );
      await expect(
        sale.connect(otherAccount).claimReferralRewards()
      ).revertedWith("no earnings");
    });
  });
});
