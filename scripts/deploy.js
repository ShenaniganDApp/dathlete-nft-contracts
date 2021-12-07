/* global ethers hre */

const diamond = require('../js/diamond-util/src/index.js')
// const deployToken= require('../scripts/deployTesttoken.js')

function addCommas (nStr) {
  nStr += ''
  const x = nStr.split('.')
  let x1 = x[0]
  const x2 = x.length > 1 ? '.' + x[1] : ''
  var rgx = /(\d+)(\d{3})/
  while (rgx.test(x1)) {
    x1 = x1.replace(rgx, '$1' + ',' + '$2')
  }
  return x1 + x2
}

function strDisplay (str) {
  return addCommas(str.toString())
}

async function main (scriptName) {
  console.log('SCRIPT NAME:', scriptName)

  const accounts = await ethers.getSigners()
  const account = await accounts[0].getAddress()
  const secondAccount= await accounts[1].getAddress()
  console.log('Account: ' + account)
  console.log('---')
  let tx
  let totalGasUsed = ethers.BigNumber.from('0')
  let receipt
  let initialSeasonSize
  let prtcleTokenContract
  let dao
  let daoTreasury
  let challengeManagers
  const gasLimit = 12300000


  const dathletePrice = ethers.utils.parseEther('100')
  const name = 'Dathlete'
  const symbol = 'DATH'
  if (hre.network.name === 'localhost') {
    dao = account // 'todo' // await accounts[1].getAddress()
    daoTreasury = account
    challengeManagers = [account] // 'todo'
    initialSeasonSize = '100'
  

    // prtcleTokenContract = set below
    dao = await accounts[1].getAddress()
    daoTreasury = await accounts[1].getAddress()
    challengeManagers = [account] // 'todo'
  } else if (hre.network.name === 'xdai') {
    initialSeasonSize = '1000'

    // XDai prtcle token address
    prtcleTokenContract = await ethers.getContractAt('Particle', '0xeDaA788Ee96a0749a2De48738f5dF0AA88E99ab5')

    dao = 'todo' // await accounts[1].getAddress()
    daoTreasury = 'todo'
    rarityFarming = 'todo' // await accounts[2].getAddress()
    pixelCraft = 'todo' // await accounts[3].getAddress()
  } else if (hre.network.name === 'kovan') {
    initialSeasonSize = '10000'

    prtcleTokenContract = await ethers.getContractAt('Particle', '0xeDaA788Ee96a0749a2De48738f5dF0AA88E99ab5')
    // console.log('PRTCLE diamond address:' + prtcleDiamond.address)

    dao = account // 'todo' // await accounts[1].getAddress()
    daoTreasury = account
    challengeManagers = [account] // 'todo'
    mintAddress = account // 'todo'
  
  } else {
    throw Error('No network settings for ' + hre.network.name)
  }

  async function deployFacets (...facets) {
    const instances = []
    for (let facet of facets) {
      let constructorArgs = []
      if (Array.isArray(facet)) {
        ;[facet, constructorArgs] = facet
      }
      const factory = await ethers.getContractFactory(facet)
      const facetInstance = await factory.deploy(...constructorArgs)
      await facetInstance.deployed()
      const tx = facetInstance.deployTransaction
      const receipt = await tx.wait()
      console.log(`${facet} deploy gas used:` + strDisplay(receipt.gasUsed))
      totalGasUsed = totalGasUsed.add(receipt.gasUsed)
      instances.push(facetInstance)
    }
    return instances
  }
  let [
    dathleteFacet,
    challengesFacet,
    challengesTransferFacet,
    daoFacet,
    shopFacet,
  ] = await deployFacets(
    'DathleteFacet',
    'ChallengesFacet',
    'ChallengesTransferFacet',
    'DAOFacet',
    'ShopFacet',
  )
  if (hre.network.name === 'localhost') {
    const Prtcle = await ethers.getContractFactory("Particle");
    prtcleTokenContract = await Prtcle.deploy(account);
  
    prtcleTokenContract = await ethers.getContractAt('Particle', prtcleTokenContract.address)
    console.log('PRTCLE address:' + prtcleTokenContract.address)
  }

  // eslint-disable-next-line no-unused-vars
  const dathleteDiamond = await diamond.deploy({
    diamondName: 'Diamond',
    initDiamond: 'contracts/upgradeInitializers/DiamondInit.sol:DiamondInit',
    facets: [
      ['DathleteFacet', dathleteFacet],
      ['ChallengesFacet', challengesFacet],
      ['ChallengesTransferFacet', challengesTransferFacet],
      ['DAOFacet', daoFacet],
      ['ShopFacet', shopFacet],
    ],
    owner: account,
    args: [[dao, daoTreasury, prtcleTokenContract.address, name, symbol]]
  })
  console.log('Dathlete diamond address:' + dathleteDiamond.address)

  tx = dathleteDiamond.deployTransaction
  receipt = await tx.wait()
  console.log('Dathlete diamond deploy gas used:' + strDisplay(receipt.gasUsed))
  totalGasUsed = totalGasUsed.add(receipt.gasUsed)

  // create first season
  daoFacet = await ethers.getContractAt('DAOFacet', dathleteDiamond.address)
  tx = await daoFacet.createSeason(initialSeasonSize, dathletePrice)
  receipt = await tx.wait()
  console.log('Season created:' + strDisplay(receipt.gasUsed))
  totalGasUsed = totalGasUsed.add(receipt.gasUsed)

  receipt = await tx.wait()
  console.log('Dathlete diamond deploy gas used:' + strDisplay(receipt.gasUsed))
  totalGasUsed = totalGasUsed.add(receipt.gasUsed)

  const diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', dathleteDiamond.address)
  dathleteFacet = await ethers.getContractAt('DathleteFacet', dathleteDiamond.address)
  shopFacet = await ethers.getContractAt('ShopFacet', dathleteDiamond.address)

  
  if (hre.network.name === 'localhost') {
  console.log('Adding challenge managers')
  tx = await daoFacet.addChallengeManagers(challengeManagers)
  console.log('Adding challenge managers tx:', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Adding challenge manager failed: ${tx.hash}`)
  }
  
  console.log('Adding Challenge managers gas used::' + strDisplay(receipt.gasUsed))
  totalGasUsed = totalGasUsed.add(receipt.gasUsed)

  console.log('Adding Challenge Types')
  challengesFacet = await ethers.getContractAt('ChallengesFacet', dathleteDiamond.address)
  challengesTransferFacet = await ethers.getContractAt('ChallengesTransferFacet', dathleteDiamond.address)

  const { challengeTypes } = require('./testChallengeTypes.js')

  tx = await daoFacet.addChallengeTypes(challengeTypes.slice(0, challengeTypes.length / 4), { gasLimit: gasLimit })
  
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Error:: ${tx.hash}`)
  }
  console.log('Adding Challenge Types (1 / 4) gas used::' + strDisplay(receipt.gasUsed))
  totalGasUsed = totalGasUsed.add(receipt.gasUsed)

  tx = await daoFacet.addChallengeTypes(challengeTypes.slice(challengeTypes.length / 4, (challengeTypes.length / 4) * 2), { gasLimit: gasLimit })
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Error:: ${tx.hash}`)
  }
  console.log('Adding Challenge Types (2 / 4) gas used::' + strDisplay(receipt.gasUsed))
  totalGasUsed = totalGasUsed.add(receipt.gasUsed)

  tx = await daoFacet.addChallengeTypes(challengeTypes.slice((challengeTypes.length / 4) * 2, (challengeTypes.length / 4) * 3), { gasLimit: gasLimit })
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Error:: ${tx.hash}`)
  }
  console.log('Adding Challenge Types (3 / 4) gas used::' + strDisplay(receipt.gasUsed))
  totalGasUsed = totalGasUsed.add(receipt.gasUsed)

  tx = await daoFacet.addChallengeTypes(challengeTypes.slice((challengeTypes.length / 4) * 3), { gasLimit: gasLimit })
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Error:: ${tx.hash}`)
  }
  console.log('Adding Challenge Types (4 / 4) gas used::' + strDisplay(receipt.gasUsed))
  totalGasUsed = totalGasUsed.add(receipt.gasUsed)

  const challengeTypeTest = await challengesFacet.getChallengeType(0)
  console.log('challengeTypes: ', challengeTypeTest);
  

  return {
    account: account,
    dathleteDiamond: dathleteDiamond,
    diamondLoupeFacet: diamondLoupeFacet,
    prtcleTokenContract: prtcleTokenContract,
    challengesFacet: challengesFacet,
    challengesTransferFacet: challengesTransferFacet,
    dathleteFacet: dathleteFacet,
    daoFacet: daoFacet,
    shopFacet: shopFacet,
    secondAccount: secondAccount
  }
}}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployProject = main

// diamond address: 0x7560d1282A3316DE155452Af3ec248d05b8A8044