import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { e18, deployFixture as fixture } from "./fixtures/core";

describe("BondingCurveSale", function () {
  it("Should deploy properly", async function () {
    const { bondingCurveSale, vestedToken, owner } = await loadFixture(fixture);
    expect(await bondingCurveSale.token()).to.equal(vestedToken.target);
    expect(await bondingCurveSale.destination()).to.equal(owner.address);
    expect(await bondingCurveSale.destination()).to.equal(owner.address);
  });

  it("Should test bondingCurveETH function properly", async function () {
    const { bondingCurveSale } = await loadFixture(fixture);
    expect(await bondingCurveSale.bondingCurveETH(e18)).to.equal(
      "79920000000000000000000"
    );
    expect(await bondingCurveSale.bondingCurveETH(e18 * 100n)).to.equal(
      "7200000000000000000000000"
    );
    expect(await bondingCurveSale.bondingCurveETH(e18 * 500n)).to.equal(
      "20000000000000000000000000"
    );
  });

  it("Should allow a user to get tokens if he invests 1 ETH properly", async function () {
    const { bondingCurveSale, otherAccount, vestedToken } = await loadFixture(
      fixture
    );

    expect(await vestedToken.balanceOf(otherAccount)).to.equal("0");

    await bondingCurveSale.connect(otherAccount).mint({ value: e18 });

    expect(await vestedToken.balanceOf(otherAccount)).to.equal(
      "79920000000000000000000"
    );
  });
});
