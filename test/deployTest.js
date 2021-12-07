/* global describe it before ethers */
const { expect } = require('chai')
const truffleAssert = require('truffle-assertions')
// const { idText } = require('typescript')

// eslint-disable-next-line no-unused-vars
// const { expect } = require('chai')

// import ERC721 from '../artifacts/ERC721.json'
// import { ethers } from 'ethers'

// const { deployProject } = require('../scripts/deploy-ganache.js')

const { deployProject } = require('../scripts/deploy.js')
const { challengeTypes } = require('../scripts/testChallengeTypes.js')

// numBytes is how many bytes of the uint that we care about
function uintToInt8Array (uint, numBytes) {
  uint = ethers.utils.hexZeroPad(uint.toHexString(), numBytes).slice(2)
  const array = []
  for (let i = 0; i < uint.length; i += 2) {
    array.unshift(ethers.BigNumber.from('0x' + uint.substr(i, 2)).fromTwos(8).toNumber())
  }
  return array
}

function sixteenBitArrayToUint (array) {
  const uint = []
  for (let challenge of array) {
    if (typeof challenge === 'string') {
      challenge = parseInt(challenge)
    }
    uint.push(challenge.toString(16).padStart(4, '0'))
  }
  if (array.length > 0) return ethers.BigNumber.from('0x' + uint.join(''))
  return ethers.BigNumber.from(0)
}

function sixteenBitIntArrayToUint (array) {
  const uint = []
  for (let challenge of array) {
    if (typeof challenge === 'string') {
      challenge = parseInt(challenge)
    }
    if (challenge < 0) {
      challenge = (1 << 16) + challenge
    }
    // console.log(challenge.toString(16))
    uint.push(challenge.toString(16).padStart(4, '0'))
  }
  if (array.length > 0) return ethers.BigNumber.from('0x' + uint.join(''))
  return ethers.BigNumber.from(0)
}

function uintToChallengeIds (uint) {
  uint = ethers.utils.hexZeroPad(uint.toHexString(), 32).slice(2)
  const array = []
  for (let i = 0; i < uint.length; i += 4) {
    array.unshift(ethers.BigNumber.from('0x' + uint.substr(i, 4)).fromTwos(16).toNumber())
  }
  return array
}

const testDathleteId = '0'
const testChallengeId = '1'

describe('Deploying Contracts and Minting Dathletes', async function () {
  this.timeout(300000)
  before(async function () {
    const deployVars = await deployProject('deployTest')
    global.set = true
    global.account = deployVars.account
    global.dathleteDiamond = deployVars.dathleteDiamond
    global.dathleteFacet = deployVars.dathleteFacet
    global.challengesFacet = deployVars.challengesFacet
    global.challengesTransferFacet = deployVars.challengesTransferFacet
    global.shopFacet = deployVars.shopFacet
    global.daoFacet = deployVars.daoFacet
    global.prtcleTokenContract = deployVars.prtcleTokenContract
    global.diamondLoupeFacet = deployVars.diamondLoupeFacet
  })
  it('Should mint 10,000,000 PRTCLE tokens', async function () {
    await global.prtcleTokenContract.mint()
    const balance = await global.prtcleTokenContract.balanceOf(global.account)
    const oneMillion = ethers.utils.parseEther('10000000')
    expect(balance).to.equal(oneMillion)
  })
})

describe('Buying Dathletes', function () {
  it('Dathlete should cost 100 PRTCLE', async function () {
    const balance = await prtcleTokenContract.balanceOf(account)
    await prtcleTokenContract.approve(dathleteDiamond.address, balance)
    const buyAmount = (50 * Math.pow(10, 18)).toFixed() // 1 dathlete
    await truffleAssert.reverts(shopFacet.buyDathletes(account, buyAmount), 'Not enough PRTCLE to buy dathletes')
  })

  it('Should purchase dathlete', async function () {
    const balance = await prtcleTokenContract.balanceOf(account)
    await prtcleTokenContract.approve(dathleteDiamond.address, balance)
    const buyAmount = ethers.utils.parseEther('500') // 1 dathletes
    const tx = await global.shopFacet.buyDathletes(account, buyAmount)
    const receipt = await tx.wait()

    const myDathletes = await global.dathleteFacet.allDathletesOfOwner(account)
    expect(myDathletes.length).to.equal(5)
  })
})

describe('Challenges', async function () {
  it('Shows challenge URI', async function () {
    const uri = await global.challengesFacet.uri(testChallengeId)
    console.log('uri: ', uri);
    expect(uri).to.equal('ipfs://f0')
  })

  it('Can mint challenges', async function () {
    let balance = await global.challengesFacet.balanceOf(account, '0')
    expect(balance).to.equal(0)
    // To do: Get max length of wearables array

    //  await truffleAssert.reverts(challengesFacet.mintChallenges(account, ['8'], ['10']), 'challengesFacet: Wearable does not exist')
    await truffleAssert.reverts(daoFacet.mintChallenges(account, ['0'], ['10']), 'DAOFacet: Total challenge type quantity exceeds max quantity')
    await global.daoFacet.mintChallenges(account, [testChallengeId], ['10'])
    balance = await global.challengesFacet.balanceOf(account, testChallengeId)
    expect(balance).to.equal(10)

    // await global.daoFacet.mintChallenges(account, [62], ['10'])

    // const result = await global.challengesFacet.challengeBalancesWithSlots(account)
    // console.log(result)
  })

  it('Can transfer challenges to Dathlete', async function () {
    await global.challengesTransferFacet.transferToParent(
      global.account, // address _from,
      global.dathleteFacet.address, // address _toContract,
      testDathleteId, // uint256 _toTokenId,
      testChallengeId, // uint256 _id,
      '10' // uint256 _value
    )
    const balance = await global.challengesFacet.balanceOfToken(dathleteFacet.address, testDathleteId, testChallengeId)
    expect(balance).to.equal(10)
  })

  it('Can transfer wearables from Dathlete back to owner', async function () {
    await global.challengesTransferFacet.transferFromParent(
      global.dathleteFacet.address, // address _fromContract,
      testDathleteId, // uint256 _fromTokenId,
      global.account, // address _to,
      testChallengeId, // uint256 _id,
      '10' // uint256 _value
    )
    const balance = await global.challengesFacet.balanceOf(account, testChallengeId)
    expect(balance).to.equal(10)
  })

describe('Seasons', async function () {
  it('Cannot create new season until first is finished', async function () {
    const purchaseNumber = ethers.utils.parseEther('100')
    await truffleAssert.reverts(daoFacet.createSeason('10000', purchaseNumber, '0x000000'), 'DathleteFacet: Season must be full before creating new')
  })

  it('Cannot exceed max season size', async function () {
    for (let i = 0; i < 399; i++) {
      const purchaseNumber = ethers.utils.parseEther('5500')
      await global.shopFacet.buyDathletes(account, purchaseNumber)
    }

    // const totalSupply = await global.dathleteFacet.totalSupply()
    const singleDathlete = ethers.utils.parseEther('5500')
    await truffleAssert.reverts(global.shopFacet.buyDathletes(account, singleDathlete), 'ShopFacet: Exceeded max number of dathletes for this season')

    //  const receipt = await tx.wait()
  })

  it('Can create new Season', async function () {
    let currentSeason = await global.dathleteGameFacet.currentSeason()
    expect(currentSeason.seasonId_).to.equal(1)
    await daoFacet.createSeason('10000', ethers.utils.parseEther('100'), '0x000000')
    currentSeason = await global.dathleteGameFacet.currentSeason()
    expect(currentSeason.seasonId_).to.equal(2)
  })
})

describe('Revenue transfers', async function () {
  it('Buying dathletes should send revenue to 2 wallets', async function () {
    // 0 = burn (33%)
    // 1 = dao (77%)

    let revenueShares = [0x0, 0xf0c5d2dcfdb3736b70e84d756b7423ff331d646f]
    const beforeBalances = []
    for (let index = 0; index < 2; index++) {
      const address = revenueShares[index]
      const balance = await global.prtcleTokenContract.balanceOf(address)
      beforeBalances[index] = balance
    }

    // Buy 10 Dathletes
    await global.shopFacet.buyDathletes(account, ethers.utils.parseEther('1500'))

    // Calculate shares from 100 Dathletes
    const burnShare = ethers.utils.parseEther('495')
    const daoShare = ethers.utils.parseEther('150')
    const shares = [burnShare, daoShare]

    // Verify the new balances
    for (let index = 0; index < 2; index++) {
      const address = revenueShares[index]

      const beforeBalance = ethers.BigNumber.from(beforeBalances[index])
      const afterBalance = ethers.BigNumber.from(await global.prtcleTokenContract.balanceOf(address))
      expect(afterBalance).to.equal(beforeBalance.add(shares[index]))
    }
  })
})

describe('Shop', async function () {
  it('Should return balances and challenge types', async function () {
    const challengesAndBalances = await global.challengesFacet.challengeBalancesWithTypes(account)
    // console.log('challenges and balances:', challengesAndBalances.balances)
  })

  it('Should purchase challenges using PRTCLE', async function () {
    let balances = await global.challengesFacet.challengeBalances(account)
    // Start at 1 because 0 is always empty
    // console.log(balances)
    // expect(balances[57]).to.equal(0)

    // Hawaiian Shirt and SantaHat
    await global.shopFacet.purchaseChallengesWithGhst(account, ['114', '115', '116', '126', '127', '128', '129'], ['10', '10', '10', '100', '10', '10', '10'])
    balances = await global.challengesFacet.challengeBalances(account)
    expect(balances[4].balance).to.equal(10)
    // console.log(balances)
  })
})

describe('DAO Functions', async function () {
  it('Only DAO or admin can set game manager', async function () {
    // To do: Check revert using another account
    await daoFacet.setGameManager(account)
    const gameManager = await daoFacet.gameManager()
    expect(gameManager).to.equal(account)
  })

function eightBitArrayToUint (array) {
  const uint = []
  for (const num of array) {
    const value = ethers.BigNumber.from(num).toTwos(8)
    uint.unshift(value.toHexString().slice(2))
  }
  return ethers.BigNumber.from('0x' + uint.join(''))
}})})