// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "./LibDiamond.sol";

struct Dathlete {
    string name;
    address owner;
    bool locked;
    string cid;
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
    mapping(address => mapping(address => bool)) operators;
    mapping(uint256 => address) approved;
    uint32 tokenIdCounter;
    string challengesBaseUri;
    bytes32 domainSeparator;
    string name;
    string symbol;
    mapping(address => bool) challengeManagers;
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
    modifier onlyDathleteOwner(uint256 _tokenId) {
        require(msg.sender == s.dathletes[_tokenId].owner, "LibAppStorage: Only dathlete owner can call this function");
        _;
    }
    modifier onlyUnlocked(uint256 _tokenId) {
        require(s.dathletes[_tokenId].locked == false, "LibAppStorage: Only callable on unlocked Dathlete");
        _;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier onlyChallengeManager() {
        address sender = msg.sender;
        require(s.challengeManagers[sender] == true, "LibAppStorage: only an ChallengeManager can call this function");
        _;
    }
    modifier onlyOwnerOrChallengeManager() {
        address sender = msg.sender;
        require(
            sender == LibDiamond.contractOwner() || s.challengeManagers[sender] == true,
            "LibAppStorage: only an Owner or ChallengeManager can call this function"
        );
        _;
    }
}
