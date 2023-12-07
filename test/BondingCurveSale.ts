import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { e18, deployFixture as fixture } from "./fixtures/core";

describe("BondingCurveSale", function () {
  it("Should deploy properly", async function () {
    const { bondingCurveSale, vestedToken, token } = await loadFixture(fixture);
    expect(await bondingCurveSale.token()).to.equal(vestedToken.target);
    expect(await bondingCurveSale.destination()).to.equal(token.target);
    expect(await bondingCurveSale.latestAnswer()).to.equal("0");
  });

  it("Should test bondingCurveETH function properly", async function () {
    const { bondingCurveSale } = await loadFixture(fixture);
    expect(await bondingCurveSale.bondingCurveETH(e18)).to.equal(
      "26657777777777760000000"
    );
    expect(await bondingCurveSale.bondingCurveETH(e18 * 100n)).to.equal(
      "2577777777777777760000000"
    );
    expect(await bondingCurveSale.bondingCurveETH(e18 * 1500n)).to.equal(
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
      "26657777777777760000000"
    );
    expect(await bondingCurveSale.latestAnswer()).to.equal("1260");
  });

  it("Should allow a user to get tokens if he invests 10 ETH properly", async function () {
    const { bondingCurveSale, otherAccount, vestedToken } = await loadFixture(
      fixture
    );

    expect(await vestedToken.balanceOf(otherAccount)).to.equal("0");

    await bondingCurveSale.connect(otherAccount).mint({ value: e18 * 10n });

    expect(await vestedToken.balanceOf(otherAccount)).to.equal(
      "265777777777777760000000"
    );
    expect(await bondingCurveSale.latestAnswer()).to.equal("12600");
  });
});
