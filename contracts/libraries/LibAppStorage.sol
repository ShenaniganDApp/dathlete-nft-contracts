// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "./LibDiamond.sol";

struct Dathlete {
    address owner;
    bool locked;
}

struct ChallengeType {
    uint256 maxQuantity; //Total number that can be minted of this item.
    uint256 totalQuantity; //The total quantity of this item minted so far
    bool canBeTransferred;
}

struct AppStorage {
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftChallengeBalances;
    mapping(address => mapping(uint256 => uint256[])) nftChallenges;
    ChallengeType[] challengeTypes;
    // indexes are stored 1 higher so that 0 means no items in items array
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) nftChallengeIndexes;
    mapping(address => mapping(uint256 => uint256)) ownerChallengeBalances;
    mapping(address => uint256[]) ownerChallenges;
    // indexes are stored 1 higher so that 0 means no items in items array
    mapping(address => mapping(uint256 => uint256)) ownerChallengeIndexes;
    mapping(uint256 => Dathlete) dathletes;
    mapping(address => uint32[]) ownerTokenIds;
    mapping(address => mapping(uint256 => uint256)) ownerTokenIdIndexes;
    uint32[] tokenIds;
    mapping(uint256 => uint256) tokenIdIndexes;
    mapping(uint256 => address) approved;
    uint32 tokenIdCounter;
    string challengesBaseUri;
    bytes32 domainSeparator;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;
}
