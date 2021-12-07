// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibChallenges, ChallengeTypeIO} from "../libraries/LibChallenges.sol";
import {LibAppStorage, Modifiers, Dathlete, ChallengeType} from "../libraries/LibAppStorage.sol";
import {LibDathlete} from "../libraries/LibDathlete.sol";
import {LibStrings} from "../libraries/LibStrings.sol";
import {LibERC1155} from "../libraries/LibERC1155.sol";

contract ChallengesFacet is Modifiers {
    //using LibAppStorage for AppStorage;

    event TransferToParent(address indexed _toContract, uint256 _toTokenId, uint256 indexed _tokenTypeId, uint256 _value);

    /***********************************|
   |             Read Functions         |
   |__________________________________*/

    struct ChallengeIdIO {
        uint256 challengeId;
        uint256 balance;
    }

    ///@notice Returns balance for each challenge that exists for an account
    ///@param _account Address of the account to query
    ///@return bals_ An array of structs,each struct containing details about each challenge owned
    function challengeBalances(address _account) external view returns (ChallengeIdIO[] memory bals_) {
        uint256 count = s.ownerChallenges[_account].length;
        bals_ = new ChallengeIdIO[](count);
        for (uint256 i; i < count; i++) {
            uint256 challengeId = s.ownerChallenges[_account][i];
            bals_[i].balance = s.ownerChallengeBalances[_account][challengeId];
            bals_[i].challengeId = challengeId;
        }
    }

    ///@notice Returns balance for each challenge(and their types) that exists for an account
    ///@param _owner Address of the account to query
    ///@return output_ An array of structs containing details about each challenge owned(including the challenge types)
    function challengeBalancesWithTypes(address _owner) external view returns (ChallengeTypeIO[] memory output_) {
        uint256 count = s.ownerChallenges[_owner].length;
        output_ = new ChallengeTypeIO[](count);
        for (uint256 i; i < count; i++) {
            uint256 challengeId = s.ownerChallenges[_owner][i];
            output_[i].balance = s.ownerChallengeBalances[_owner][challengeId];
            output_[i].challengeId = challengeId;
            output_[i].challengeType = s.challengeTypes[challengeId];
        }
    }

    /**
        @notice Get the balance of an account's tokens.
        @param _owner  The address of the token holder
        @param _id     ID of the token
        @return bal_    The _owner's balance of the token type requested
     */
    function balanceOf(address _owner, uint256 _id) external view returns (uint256 bal_) {
        bal_ = s.ownerChallengeBalances[_owner][_id];
    }

    /// @notice Get the balance of a non-fungible parent token
    /// @param _tokenContract The contract tracking the parent token
    /// @param _tokenId The ID of the parent token
    /// @param _id     ID of the token
    /// @return value The balance of the token
    function balanceOfToken(
        address _tokenContract,
        uint256 _tokenId,
        uint256 _id
    ) external view returns (uint256 value) {
        value = s.nftChallengeBalances[_tokenContract][_tokenId][_id];
    }

    ///@notice Returns the balances for all ERC1155 challenges for a ERC721 token
    ///@dev Only valid for claimed dathletes
    ///@param _tokenContract Contract address for the token to query
    ///@param _tokenId Identifier of the token to query
    ///@return bals_ An array of structs containing details about each challenge owned
    function challengeBalancesOfToken(address _tokenContract, uint256 _tokenId) external view returns (ChallengeIdIO[] memory bals_) {
        uint256 count = s.nftChallenges[_tokenContract][_tokenId].length;
        bals_ = new ChallengeIdIO[](count);
        for (uint256 i; i < count; i++) {
            uint256 challengeId = s.nftChallenges[_tokenContract][_tokenId][i];
            bals_[i].challengeId = challengeId;
            bals_[i].balance = s.nftChallengeBalances[_tokenContract][_tokenId][challengeId];
        }
    }

    ///@notice Returns the balances for all ERC1155 challenges for a ERC721 token
    ///@dev Only valid for claimed dathletes
    ///@param _tokenContract Contract address for the token to query
    ///@param _tokenId Identifier of the token to query
    ///@return challengeBalancesOfTokenWithTypes_ An array of structs containing details about each challenge owned(including the types)
    function challengeBalancesOfTokenWithTypes(address _tokenContract, uint256 _tokenId)
        external
        view
        returns (ChallengeTypeIO[] memory challengeBalancesOfTokenWithTypes_)
    {
        challengeBalancesOfTokenWithTypes_ = LibChallenges.challengeBalancesOfTokenWithTypes(_tokenContract, _tokenId);
    }

    /**
        @notice Get the balance of multiple account/token pairs
        @param _owners The addresses of the token holders
        @param _ids    ID of the tokens
        @return bals   The _owner's balance of the token types requested (i.e. balance for each (owner, id) pair)
     */
    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory bals) {
        require(_owners.length == _ids.length, "ChallengesFacet: _owners length not same as _ids length");
        bals = new uint256[](_owners.length);
        for (uint256 i; i < _owners.length; i++) {
            uint256 id = _ids[i];
            address owner = _owners[i];
            bals[i] = s.ownerChallengeBalances[owner][id];
        }
    }

    ///@notice Query the challenge type of a particular challenge
    ///@param _challengeId Challenge to query
    ///@return challengeType_ A struct containing details about the challenge type of an challenge with identifier `_challengeId`
    function getChallengeType(uint256 _challengeId) public view returns (ChallengeType memory challengeType_) {
        require(_challengeId < s.challengeTypes.length, "ChallengesFacet: Challenge type doesn't exist");
        challengeType_ = s.challengeTypes[_challengeId];
    }

    ///@notice Query the challenge type of multiple  challenges
    ///@param _challengeIds An array containing the identifiers of challenges to query
    ///@return challengeTypes_ An array of structs,each struct containing details about the challenge type of the corresponding challenge
    function getChallengeTypes(uint256[] calldata _challengeIds) external view returns (ChallengeType[] memory challengeTypes_) {
        if (_challengeIds.length == 0) {
            challengeTypes_ = s.challengeTypes;
        } else {
            challengeTypes_ = new ChallengeType[](_challengeIds.length);
            for (uint256 i; i < _challengeIds.length; i++) {
                challengeTypes_[i] = s.challengeTypes[_challengeIds[i]];
            }
        }
    }

    ///@notice Query the newest challenge type of a particular challenge
    ///@return challengeType_ A struct containing details about the challenge type of an challenge with identifier `_challengeId`
    function getNewestChallengeType() public view returns (ChallengeType memory challengeType_) {
        challengeType_ = s.challengeTypes[s.challengeTypes.length - 1];
    }

    /**
        @notice Get the URI for a challenge type
        @return URI for token type
    */
    function uri(uint256 _id) external view returns (string memory) {
        require(_id < s.challengeTypes.length, "ChallengesFacet: Challenge _id not found");
        string memory hexstringtokenID;
        hexstringtokenID = LibStrings.uint2hexstr(_id);

        return string(abi.encodePacked("ipfs://f0", hexstringtokenID));
    }

    /**
        @notice Set the base url for all challenge types
        @param _value The new base url        
    */
    function setBaseURI(string memory _value) external onlyOwner {
        s.challengesBaseUri = _value;
        for (uint256 i; i < s.challengeTypes.length; i++) {
            string memory hexId = LibStrings.uint2hexstr(i);
            string memory val = LibStrings.concatenate(_value, hexId);
            emit LibERC1155.URI(val, hexId);
        }
    }
}
