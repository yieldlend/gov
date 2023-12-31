const totalSupply = 100000000000;
const ethPrice = 2350;

const usdToRaise = 1000000;
const ethToRaise = 1500;
const reserveToSell = totalSupply * 0.2;
const reserveInLP = totalSupply * 0.1;

const valuationUsdFromRaise = (
  reserveInLP: number,
  usdInLp: number,
  totalSupply: number
) => totalSupply * (usdInLp / reserveInLP);

const valuationEthFromRaise = (
  reserveInLP: number,
  ethInLp: number,
  totalSupply: number
) => totalSupply * ((ethInLp * ethPrice) / reserveInLP);

console.log("tokens to sell", reserveToSell);
console.log("usd to raise", usdToRaise);
console.log("eth to raise", ethToRaise);
console.log("tokens in LP", reserveInLP);
console.log("valuation", valuationUsdFromRaise(reserveInLP, 100, totalSupply));

const bondingCurveETH = (x: number) =>
  reserveToSell * (1 - (1 - x / ethToRaise) ** 2);

const bondingCurveUSD = (x: number) =>
  reserveToSell * (1 - (1 - x / usdToRaise) ** 2);

const bondingCurveETHv2 = (x: number) => reserveToSell * (x / ethToRaise) ** 2;

const bondingCurveUSDv2 = (x: number) => reserveToSell * (x / usdToRaise) ** 2;

const tokensReceivedETH = (
  prevTokensSold: number,
  prevEthGiven: number,
  ethGiven: number
) => bondingCurveETH(prevEthGiven + ethGiven) - prevTokensSold;

const tokensReceivedETHv2 = (
  prevTokensSold: number,
  prevEthGiven: number,
  ethGiven: number
) => bondingCurveETHv2(prevEthGiven + ethGiven) - prevTokensSold;

const tokensReceivedUSD = (
  prevTokensSold: number,
  prevUsdGiven: number,
  usdGiven: number
) => bondingCurveUSD(prevUsdGiven + usdGiven) - prevTokensSold;

console.log("bonding USD - 10%", bondingCurveUSD(usdToRaise * 0.1));
console.log("sale 1 for 900k$", tokensReceivedUSD(0, 0, 900000));
console.log("sale 1 for 100k$", tokensReceivedUSD(0, 0, 100000));
console.log(
  "sale 2 for 200k$",
  tokensReceivedUSD(tokensReceivedUSD(0, 0, 100000), 100000, 200000)
);

console.log("\n\nETH raise:");

const check = (n: number) => {
  const tokensRecvd = tokensReceivedETH(0, 0, n);

  const percentage = n / 1500;
  const tokensInLp = percentage * reserveInLP;

  const valuation = valuationEthFromRaise(tokensInLp, n * 0.6, totalSupply);
  console.log(`\nvaluation at ${n} eth raised`, valuation);
  console.log(`eth bought price`, n * ethPrice);
  console.log(`tokens sold`, tokensRecvd);
  console.log(`tokens sold price`, tokensRecvd * (valuation / totalSupply));

  console.log(`price`, valuation / totalSupply);
  console.log(
    "percentage of sale completed",
    Math.round((100 * tokensReceivedETH(0, 0, n)) / (totalSupply * 0.2))
  );
};

// check(1);
check(0.052);
// check(25);
// check(50);
// check(100);
// check(250);
// check(500);

// console.log("bonding USD - 10%", bondingCurveETH(ethToRaise * 0.1));
// console.log("sale 1 for 900k$", tokensReceivedETH(0, 0, 428));
// console.log("sale 1 for 100k$", tokensReceivedETH(0, 0, 47));
// console.log(
//   "sale 2 for 200k$",
//   tokensReceivedETH(tokensReceivedETH(0, 0, 47), 47, 94)
// );
