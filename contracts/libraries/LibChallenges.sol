// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibAppStorage, AppStorage, ChallengeType} from "./LibAppStorage.sol";
import {LibERC1155} from "./LibERC1155.sol";

struct ChallengeTypeIO {
    uint256 balance;
    uint256 challengeId;
    ChallengeType challengeType;
}

library LibChallenges {
    function challengeBalancesOfTokenWithTypes(address _tokenContract, uint256 _tokenId)
        internal
        view
        returns (ChallengeTypeIO[] memory challengeBalancesOfTokenWithTypes_)
    {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 count = s.nftChallenges[_tokenContract][_tokenId].length;
        challengeBalancesOfTokenWithTypes_ = new ChallengeTypeIO[](count);
        for (uint256 i; i < count; i++) {
            uint256 challengeId = s.nftChallenges[_tokenContract][_tokenId][i];
            uint256 bal = s.nftChallengeBalances[_tokenContract][_tokenId][challengeId];
            challengeBalancesOfTokenWithTypes_[i].challengeId = challengeId;
            challengeBalancesOfTokenWithTypes_[i].balance = bal;
            challengeBalancesOfTokenWithTypes_[i].challengeType = s.challengeTypes[challengeId];
        }
    }

    function addToParent(
        address _toContract,
        uint256 _toTokenId,
        uint256 _id,
        uint256 _value
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.nftChallengeBalances[_toContract][_toTokenId][_id] += _value;
        if (s.nftChallengeIndexes[_toContract][_toTokenId][_id] == 0) {
            s.nftChallenges[_toContract][_toTokenId].push(uint16(_id));
            s.nftChallengeIndexes[_toContract][_toTokenId][_id] = s.nftChallenges[_toContract][_toTokenId].length;
        }
    }

    function addToOwner(
        address _to,
        uint256 _id,
        uint256 _value
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.ownerChallengeBalances[_to][_id] += _value;
        if (s.ownerChallengeIndexes[_to][_id] == 0) {
            s.ownerChallenges[_to].push(uint16(_id));
            s.ownerChallengeIndexes[_to][_id] = s.ownerChallenges[_to].length;
        }
    }

    function removeFromOwner(
        address _from,
        uint256 _id,
        uint256 _value
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 bal = s.ownerChallengeBalances[_from][_id];
        require(_value <= bal, "LibChallenges: Doesn't have that many to transfer");
        bal -= _value;
        s.ownerChallengeBalances[_from][_id] = bal;
        if (bal == 0) {
            uint256 index = s.ownerChallengeIndexes[_from][_id] - 1;
            uint256 lastIndex = s.ownerChallenges[_from].length - 1;
            if (index != lastIndex) {
                uint256 lastId = s.ownerChallenges[_from][lastIndex];
                s.ownerChallenges[_from][index] = uint16(lastId);
                s.ownerChallengeIndexes[_from][lastId] = index + 1;
            }
            s.ownerChallenges[_from].pop();
            delete s.ownerChallengeIndexes[_from][_id];
        }
    }

    function removeFromParent(
        address _fromContract,
        uint256 _fromTokenId,
        uint256 _id,
        uint256 _value
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 bal = s.nftChallengeBalances[_fromContract][_fromTokenId][_id];
        require(_value <= bal, "Challenges: Doesn't have that many to transfer");
        bal -= _value;
        s.nftChallengeBalances[_fromContract][_fromTokenId][_id] = bal;
        if (bal == 0) {
            uint256 index = s.nftChallengeIndexes[_fromContract][_fromTokenId][_id] - 1;
            uint256 lastIndex = s.nftChallenges[_fromContract][_fromTokenId].length - 1;
            if (index != lastIndex) {
                uint256 lastId = s.nftChallenges[_fromContract][_fromTokenId][lastIndex];
                s.nftChallenges[_fromContract][_fromTokenId][index] = uint16(lastId);
                s.nftChallengeIndexes[_fromContract][_fromTokenId][lastId] = index + 1;
            }
            s.nftChallenges[_fromContract][_fromTokenId].pop();
            delete s.nftChallengeIndexes[_fromContract][_fromTokenId][_id];
        }
    }
}
