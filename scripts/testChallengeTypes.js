const { isThrowStatement } = require('typescript')

const challengeTypes = [
    {
      id: 0,
      name: 'The Void',
      description: 'The Void',
      prtclePrice: 0,
      maxQuantity: 0,
      canPurchaseWithPrtcle: false,
      canBeTransferred: false,
      totalQuantity: 0,
    },
    {
      id: 1,
      name: 'BWW Blazin Wing Challenge',
      description: 'Eat 10 wings in 5 minutes; no water',
      prtclePrice: 5,
      maxQuantity: '1000',
      canPurchaseWithPrtcle: false,
      canBeTransferred: true,
      totalQuantity: 0,
    },
    {
      id: 2,
      name: 'Do a Backflip',
      description: 'Do a Backflip Description',
      prtclePrice: 5,
      maxQuantity: '1000',
      canPurchaseWithPrtcle: false,
      canBeTransferred: true,
      totalQuantity: 0,
    },
    {
      id: 3,
      name: 'Hold My Breathe for 5 minutes',
      description: 'Hold My Breathe for 5 minutes',
      prtclePrice: 5,
      maxQuantity: '1000',
      canPurchaseWithPrtcle: false,
      canBeTransferred: true,
      totalQuantity: 0,
    },
    {
      id: 4,
      name: 'Dunk a Basketball',
      description: 'Dunk',
      prtclePrice: 50,
      maxQuantity: '250',
      canPurchaseWithPrtcle: true,
      canBeTransferred: true,
      totalQuantity: 0
    }
  ]
  
  function eightBitIntArrayToUint(array) {
    if (array.length === 0) {
      return ethers.BigNumber.from(0)
    }
    const uint = []
    for (const num of array) {
      if (num > 127) {
        throw (Error('Value beyond signed 8 int '))
      }
      const value = ethers.BigNumber.from(num).toTwos(8)
      uint.unshift(value.toHexString().slice(2))
    }
    return ethers.BigNumber.from('0x' + uint.join(''))
  }
  
  function boolsArrayToUint16(bools) {
    const uint = []
    for (const b of bools) {
      if (b) {
        uint.push('1')
      } else {
        uint.push('0')
      }
    }
    // console.log(bools)
    // console.log(uint.join(''))
    // console.log(uint.join('').padStart(16, '0'))
    // console.log('-------------')
    return parseInt(uint.join('').padStart(16, '0'), 2)
  }
  
  
  function getChallengeTypes() {
    const result = []
    for (const challengeType of challengeTypes) {
      challengeType.prtclePrice = ethers.utils.parseEther(challengeType.prtclePrice.toString())
      result.push(challengeType)
      
    }
    return result
  }
  
  exports.challengeTypes = getChallengeTypes()