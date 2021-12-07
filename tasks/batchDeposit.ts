import { LedgerSigner } from "@ethersproject/hardware-wallets";
import { task } from "hardhat/config";
import { ContractReceipt, ContractTransaction } from "@ethersproject/contracts";
import { Signer } from "@ethersproject/abstract-signer";
import { ChallengesTransferFacet } from "../typechain-types";
import { gasPrice, xDaiDiamondAddress } from "../scripts/helperFunctions";
import { HardhatRuntimeEnvironment } from "hardhat/types";
import { ethers } from "ethers";

function removeDuplicates(gotchiIds: string[]) {
  const uniqueGotchis: string[] = [];
  const duplicateGotchis: string[] = [];
  let index: number = 0;
  for (index; index < gotchiIds.length; index++) {
    if (uniqueGotchis.includes(gotchiIds[index])) {
      duplicateGotchis.push(gotchiIds[index]);
    }
    if (!uniqueGotchis.includes(gotchiIds[index])) {
      uniqueGotchis.push(gotchiIds[index]);
    }
  }
  console.log("removed", duplicateGotchis.length, "duplicate gotchis");
  return uniqueGotchis;
}

interface TaskArgs {
  dathleteIds: string;
  quantity: string;
  challengeId: string;
}

task(
  "batchDeposit",
  "Allows the batch deposit of ERC1155 to multiple ERC721 tokens"
)
  .addParam("dathleteIds", "String array of Dathlete IDs")
  .addParam(
    "quantity",
    "The amount of ERC1155 tokens to deposit into each ERC721 token"
  )
  .addParam("challengeId", "The Challenge to deposit")
  .setAction(async (taskArgs: TaskArgs, hre: HardhatRuntimeEnvironment) => {
    const dathleteIDs: string[] = taskArgs.dathleteIds.split(",");
    const quantity: number = Number(taskArgs.quantity);
    const challengeId: number = Number(taskArgs.challengeId);

    //assuming all Challenge drops are in the data/airdrops/Challengedrops folder
    // const { dathletes } = require(`../data/airdrops/Challengedrops/${filename}.ts`);
    const diamondAddress = xDaiDiamondAddress;
    const ChallengeManager = "0xe9f952f50ff1c5f7f25d7120ba6126fb40620a72";
    let signer: Signer;
    const testing = ["hardhat", "localhost"].includes(hre.network.name);
    if (testing) {
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [ChallengeManager],
      });
      signer = await hre.ethers.provider.getSigner(ChallengeManager);
    } else if (hre.network.name === "xdai") {
      //   signer = new LedgerSigner(
      //     hre.ethers.provider as ethers.providers.Provider,
      //     "hid",
      //     "m/44'/60'/2'/0/0"
      //   );
    } else {
      throw Error("Incorrect network selected");
    }

    //     const ChallengesTransfer = (
    //       await hre.ethers.getContractAt("ChallengesTransferFacet", diamondAddress)
    //     ).connect(signer) as ChallengesTransferFacet;
    //     const uniqueIds: string[] = removeDuplicates(gotchiIDs);
    //     console.log(
    //       "Batch Depositing",
    //       quantity,
    //       "Challenges of ChallengeId",
    //       ChallengeId,
    //       "to",
    //       uniqueIds.length,
    //       "dathletes"
    //     );
    //     // let eachGotchi: number[] = Array(1).fill(ChallengeId);
    //     // let eachValue: number[] = Array(1).fill(quantity);
    //     const tx: ContractTransaction =
    //       await ChallengesTransfer.batchBatchTransferToParent(
    //         ChallengeManager,
    //         diamondAddress,
    //         uniqueIds,
    //         Array(uniqueIds.length).fill([ChallengeId]),
    //         Array(uniqueIds.length).fill([quantity]),
    //         { gasPrice: gasPrice }
    //       );
    //     console.log("tx:", tx.hash);
    //     let receipt: ContractReceipt = await tx.wait();
    //     // console.log("Gas used:", strDisplay(receipt.gasUsed.toString()));
    //     if (!receipt.status) {
    //       throw Error(`Error:: ${tx.hash}`);
    //     }
  });
