import { HardhatUserConfig } from "hardhat/config";
import dotenv from "dotenv";
dotenv.config();

import "@typechain/hardhat";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-ethers";
import "hardhat-abi-exporter";

const MNEMONIC_PATH = "m/44'/60'/0'/0";
const MNEMONIC = process.env.MNEMONIC || "";

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  typechain: {
    target: "ethers-v6",
    alwaysGenerateOverloads: false, // should overloads with full signatures like deposit(uint256) be generated always, even if there are no overloads?
    externalArtifacts: ["externalArtifacts/*.json"], // optional array of glob patterns with external artifacts to process (for example external libs from node_modules)
    dontOverrideCompile: false, // defaults to false
  },
  networks: {
    hardhat: {
      forking: {
        url: "https://rpc.ankr.com/base",
      },
    },
    base: {
      url: "https://mainnet.base.org",
      chainId: 8453,
      accounts: {
        mnemonic: MNEMONIC,
        path: MNEMONIC_PATH,
        initialIndex: 0,
        count: 10,
      },
    },
    baseGoerli: {
      url: "https://goerli.base.org",
      chainId: 84531,
      gasPrice: 2000000000,
      accounts: {
        mnemonic: MNEMONIC,
        path: MNEMONIC_PATH,
        initialIndex: 0,
        count: 10,
      },
    },
  },
  abiExporter: {
    path: "./generated-abi",
    runOnCompile: true,
    clear: true,
    flat: true,
    spacing: 2,
    // pretty: true,
    // format: "minimal",
  },
  etherscan: {
    apiKey: {
      base: process.env.BASESCAN_KEY || "",
      baseGoerli: process.env.BASESCAN_KEY || "",
    },
    customChains: [
      {
        network: "base",
        chainId: 8453,
        urls: {
          apiURL: "https://api.basescan.org/api",
          browserURL: "https://basescan.org",
        },
      },
      {
        network: "baseGoerli",
        chainId: 84531,
        urls: {
          apiURL: "https://api-goerli.basescan.org/api",
          browserURL: "https://goerli.basescan.org",
        },
      },
    ],
  },
  solidity: {
    version: "0.8.19",
  },
};

export default config;
