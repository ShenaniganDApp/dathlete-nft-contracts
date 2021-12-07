/* global ethers hre */
/* eslint-disable  prefer-const */

const { LedgerSigner } = require("@ethersproject/hardware-wallets");
const { challengeTypes } = require("./testChallengeTypes.js");


let signer;
const diamondAddress = "0x99bbA657f2BbC93c02D617f8bA121cB8Fc104Acf";
const gasLimit = 15000000;
const gasPrice = 20000000000;


async function main() {
  const challengeManager = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

  let owner = challengeManager;
  const testing = ["hardhat", "localhost"].includes(hre.network.name);
  if (testing) {
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [owner],
    });
    signer = await ethers.provider.getSigner(owner);
  } else if (hre.network.name === "matic") {
    signer = new LedgerSigner(ethers.provider, "hid", "m/44'/60'/2'/0/0");
  } else {
    throw Error("Incorrect network selected");
  }
  let tx;
  let receipt;

  let daoFacet = (
    await ethers.getContractAt("DAOFacet", diamondAddress)
  ).connect(signer);
  console.log("Adding challenges", 0, "to", challengeTypes.length);

  tx = await daoFacet.addChallengeTypes(challengeTypes);

  receipt = await tx.wait();
  if (!receipt.status) {
    throw Error(`Error:: ${tx.hash}`);
  }
  console.log("Challenges were added:", tx.hash);

  const challengeIds = [];
  const quantities = [];
  challengeTypes.forEach((challengeType) => {
    challengeIds.push(challengeType.id);
    quantities.push(challengeType.maxQuantity);
  });

  console.log("Mint prize challenges to Challenge Manager");

  tx = await daoFacet.mintChallenges(challengeManager, challengeIds, quantities, {
    gasPrice: gasPrice,
  });
  receipt = await tx.wait();
  if (!receipt.status) {
    throw Error(`Error:: ${tx.hash}`);
  }

  console.log("Prize challenges minted:", tx.hash);

  return {
    signer,
    diamondAddress,
  };
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

exports.addTestChallenges