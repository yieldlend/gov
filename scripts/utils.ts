import { ContractTransactionResponse } from "ethers";

export const wait = (ms: number) =>
  new Promise((resolve) => setTimeout(resolve, ms));

export const waitForTx = async (tx: Promise<ContractTransactionResponse>) => {
  const _tx = await tx;
  console.log("waiitng for tx", _tx.hash);
  await _tx.wait(1);
  return _tx;
};
