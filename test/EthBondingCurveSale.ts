import {
  loadFixture,
  time,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { e18, deployFixture as fixture } from "./fixtures/core";

describe("EthBondingCurveSale", function () {
  it("Should deploy properly", async function () {
    const { bondingCurveSale, vestedToken, owner } = await loadFixture(fixture);
    expect(await bondingCurveSale.token()).to.equal(vestedToken.target);
    expect(await bondingCurveSale.destination()).to.equal(owner.address);
    expect(await bondingCurveSale.destination()).to.equal(owner.address);
  });

  describe("For a user who has some vested tokens", function () {
    // todo

    it("Should create a new vest properly", async function () {
      const { streamedVesting, token, vestedToken, owner } = await loadFixture(
        fixture
      );
      expect(await vestedToken.balanceOf(owner.address)).greaterThan(0);
      await vestedToken.approve(streamedVesting.target, e18 * 100n);

      await streamedVesting.createVest(e18 * 100n); // start vesting 100 tokens.

      expect(await streamedVesting.lastId()).to.equal(1n);
      expect(await streamedVesting.userToIds(owner.address, 0)).to.equal(1n);
      expect(await vestedToken.balanceOf(streamedVesting.target)).eq(0);
    });

    it("Should vest 1/3rd after one month", async function () {
      const amt = e18 * 100n;
      const { streamedVesting, token, vestedToken, owner } = await loadFixture(
        fixture
      );
      expect(await vestedToken.balanceOf(owner.address)).greaterThan(0);
      await vestedToken.approve(streamedVesting.target, e18 * 100n);

      await streamedVesting.createVest(e18 * 100n); // start vesting 100 tokens.
      expect(await streamedVesting.claimable(1)).to.equal(0);

      const vestBefore = await streamedVesting.vests(1);
      expect(vestBefore.claimed).eq(0);
      expect(vestBefore.amount).eq(e18 * 100n);

      await time.increase(86400 * 30);
      expect(await streamedVesting.claimable(1)).to.equal(amt / 3n);

      await streamedVesting.claimVest(1); // start vesting 100 tokens.

      const vestAfter = await streamedVesting.vests(1);
      expect(vestAfter.claimed).greaterThan(amt / 3n);
      expect(vestAfter.amount).eq(e18 * 100n);
    });
  });
});
