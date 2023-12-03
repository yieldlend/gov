import {
  loadFixture,
  time,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { e18, deployFixture as fixture } from "./fixtures/core";

describe("StreamedVesting", function () {
  it("Should deploy properly", async function () {
    const { streamedVesting, token, vestedToken, owner } = await loadFixture(
      fixture
    );
    expect(await streamedVesting.underlying()).to.equal(token.target);
    expect(await streamedVesting.vestedToken()).to.equal(vestedToken.target);

    expect(await vestedToken.balanceOf(streamedVesting.target)).eq(0);
    expect(await token.balanceOf(streamedVesting.target)).greaterThan(0);
    expect(await streamedVesting.lastId()).to.equal(0);
    expect(await streamedVesting.userToIds(owner.address, 0)).to.equal(0);
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

  // describe("Withdrawals", function () {
  //   describe("Validations", function () {
  //     it("Should revert with the right error if called too soon", async function () {
  //       const { lock } = await loadFixture(deployOneYearLockFixture);

  //       await expect(lock.withdraw()).to.be.revertedWith(
  //         "You can't withdraw yet"
  //       );
  //     });

  //     it("Should revert with the right error if called from another account", async function () {
  //       const { lock, unlockTime, otherAccount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // We can increase the time in Hardhat Network
  //       await time.increaseTo(unlockTime);

  //       // We use lock.connect() to send a transaction from another account
  //       await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
  //         "You aren't the owner"
  //       );
  //     });

  //     it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
  //       const { lock, unlockTime } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       // Transactions are sent using the first signer by default
  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).not.to.be.reverted;
  //     });
  //   });

  //   describe("Events", function () {
  //     it("Should emit an event on withdrawals", async function () {
  //       const { lock, unlockTime, lockedAmount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw())
  //         .to.emit(lock, "Withdrawal")
  //         .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
  //     });
  //   });

  //   describe("Transfers", function () {
  //     it("Should transfer the funds to the owner", async function () {
  //       const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
  //         deployOneYearLockFixture
  //       );

  //       await time.increaseTo(unlockTime);

  //       await expect(lock.withdraw()).to.changeEtherBalances(
  //         [owner, lock],
  //         [lockedAmount, -lockedAmount]
  //       );
  //     });
  //   });
  // });
});
