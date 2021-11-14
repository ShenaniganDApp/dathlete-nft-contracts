// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibAppStorage, AppStorage, ChallengeType} from "./LibAppStorage.sol";
import {LibERC721} from "../libraries/LibERC721.sol";
import {LibChallenges, ChallengeTypeIO} from "../libraries/LibChallenges.sol";

struct DathleteInfo {
    uint256 tokenId;
    string name;
    address owner;
    bool locked;
    string cid;
    ChallengeTypeIO[] challenges;
}

library LibDathlete {
    function getDathlete(uint256 _tokenId) internal view returns (DathleteInfo memory dathleteInfo_) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        dathleteInfo_.tokenId = _tokenId;
        dathleteInfo_.owner = s.dathletes[_tokenId].owner;
        dathleteInfo_.cid = s.dathletes[_tokenId].cid;
        dathleteInfo_.name = s.dathletes[_tokenId].name;
        dathleteInfo_.locked = s.dathletes[_tokenId].locked;
        dathleteInfo_.challenges = LibChallenges.challengeBalancesOfTokenWithTypes(address(this), _tokenId);
    }

    function transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // remove
        uint256 index = s.ownerTokenIdIndexes[_from][_tokenId];
        uint256 lastIndex = s.ownerTokenIds[_from].length - 1;
        if (index != lastIndex) {
            uint32 lastTokenId = s.ownerTokenIds[_from][lastIndex];
            s.ownerTokenIds[_from][index] = lastTokenId;
            s.ownerTokenIdIndexes[_from][lastTokenId] = index;
        }
        s.ownerTokenIds[_from].pop();
        delete s.ownerTokenIdIndexes[_from][_tokenId];
        if (s.approved[_tokenId] != address(0)) {
            delete s.approved[_tokenId];
            emit LibERC721.Approval(_from, address(0), _tokenId);
        }
        // add
        s.dathletes[_tokenId].owner = _to;
        s.ownerTokenIdIndexes[_to][_tokenId] = s.ownerTokenIds[_to].length;
        s.ownerTokenIds[_to].push(uint32(_tokenId));
        emit LibERC721.Transfer(_from, _to, _tokenId);
    }
}
