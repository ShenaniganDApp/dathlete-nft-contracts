// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Modifiers, ChallengeType} from "../libraries/LibAppStorage.sol";
import {LibERC1155} from "../libraries/LibERC1155.sol";
import {LibChallenges} from "../libraries/LibChallenges.sol";

contract DAOFacet is Modifiers {
    event DaoTransferred(address indexed previousDao, address indexed newDao);
    event DaoTreasuryTransferred(address indexed previousDaoTreasury, address indexed newDaoTreasury);
    event AddChallengeType(ChallengeType _challengeType);
    event CreateSeason(uint256 indexed _seasonId, uint256 _seasonMaxSize, uint256 _dathletePrice);
    event ChallengeTypeMaxQuantity(uint256[] _challengeIds, uint256[] _maxQuanities);
    event ChallengeManagerAdded(address indexed newChallengeManager_);
    event ChallengeManagerRemoved(address indexed challengeManager_);
    event UpdateChallengePrice(uint256 _challengeId, uint256 _priceInWei);

    /***********************************|
   |             Write Functions        |
   |__________________________________*/

    ///@notice Allow the Diamond owner or DAO to set a new Dao address and Treasury address
    ///@param _newDao New DAO address
    ///@param _newDaoTreasury New treasury address
    function setDao(address _newDao, address _newDaoTreasury) external onlyDaoOrOwner {
        emit DaoTransferred(s.dao, _newDao);
        emit DaoTreasuryTransferred(s.daoTreasury, _newDaoTreasury);
        s.dao = _newDao;
        s.daoTreasury = _newDaoTreasury;
    }

    ///@notice Allow the Diamond owner or DAO to add challenge managers
    ///@param _newChallengeManagers An array containing the addresses that need to be added as challenge managers
    function addChallengeManagers(address[] calldata _newChallengeManagers) external onlyDaoOrOwner {
        for (uint256 index = 0; index < _newChallengeManagers.length; index++) {
            address newChallengeManager = _newChallengeManagers[index];
            s.challengeManagers[newChallengeManager] = true;
            emit ChallengeManagerAdded(newChallengeManager);
        }
    }

    ///@notice Allow the Diamond owner or DAO to remove challenge managers
    ///@dev Will throw if one of the addresses in `_challengeManagers` is not an challenge manager
    ///@param _challengeManagers An array containing the addresses that need to be removed from existing challenge managers
    function removeChallengeManagers(address[] calldata _challengeManagers) external onlyDaoOrOwner {
        for (uint256 index = 0; index < _challengeManagers.length; index++) {
            address challengeManager = _challengeManagers[index];
            require(s.challengeManagers[challengeManager] == true, "DAOFacet: challengeManager does not exist or already removed");
            s.challengeManagers[challengeManager] = false;
            emit ChallengeManagerRemoved(challengeManager);
        }
    }

    ///@notice Allow an challenge manager to increase the max quantity of an challenge
    ///@dev Will throw if the new maxquantity is less than the existing quantity
    ///@param _challengeIds An array containing the identifiers of challenges whose quantites are to be increased
    ///@param _maxQuantities An array containing the new max quantity of each challenge
    function updateChallengeTypeMaxQuantity(uint256[] calldata _challengeIds, uint256[] calldata _maxQuantities) external onlyChallengeManager {
        require(_challengeIds.length == _maxQuantities.length, "DAOFacet: _challengeIds length not the same as _newQuantities length");
        for (uint256 i; i < _challengeIds.length; i++) {
            uint256 challengeId = _challengeIds[i];
            uint256 maxQuantity = _maxQuantities[i];
            require(maxQuantity >= s.challengeTypes[challengeId].totalQuantity, "DAOFacet: maxQuantity is greater than existing quantity");
            s.challengeTypes[challengeId].maxQuantity = maxQuantity;
        }
        emit ChallengeTypeMaxQuantity(_challengeIds, _maxQuantities);
    }

    ///@notice Allow the Diamond owner or DAO to create a new Season
    ///@dev Will throw if the previous season is not full yet
    ///@param _seasonMaxSize The maximum number of dathletes in the new season
    ///@param _dathletePrice The base price of dathletes in the new season(in $GHST)
    function createSeason(uint24 _seasonMaxSize, uint96 _dathletePrice) external onlyDaoOrOwner returns (uint256 seasonId_) {
        uint256 currentSeasonId = s.currentSeasonId;
        require(
            s.seasons[currentSeasonId].totalCount == s.seasons[currentSeasonId].seasonMaxSize,
            "DathleteFacet: Season must be full before creating new"
        );
        seasonId_ = currentSeasonId + 1;
        s.currentSeasonId = uint16(seasonId_);
        s.seasons[seasonId_].seasonMaxSize = _seasonMaxSize;
        s.seasons[seasonId_].dathletePrice = _dathletePrice;
        emit CreateSeason(seasonId_, _seasonMaxSize, _dathletePrice);
    }

    struct CreateSeasonPayload {
        uint24 _seasonMaxSize;
        uint96 _dathletePrice;
    }

    //May overload the block gas limit but worth trying
    ///@notice allow an challenge manager to create a new Season, also uploading the collateral types,collateral svgs,eyeshape types and eyeshape svgs all in one transaction
    ///@param _payload A struct containing all details needed to be uploaded for a new Season
    function createSeasonWithPayload(CreateSeasonPayload calldata _payload) external onlyChallengeManager returns (uint256 seasonId_) {
        uint256 currentSeasonId = s.currentSeasonId;
        require(
            s.seasons[currentSeasonId].totalCount == s.seasons[currentSeasonId].seasonMaxSize,
            "DathleteFacet: Season must be full before creating new"
        );

        seasonId_ = currentSeasonId + 1;

        s.currentSeasonId = uint16(seasonId_);
        s.seasons[seasonId_].seasonMaxSize = _payload._seasonMaxSize;
        s.seasons[seasonId_].dathletePrice = _payload._dathletePrice;
        emit CreateSeason(seasonId_, _payload._seasonMaxSize, _payload._dathletePrice);
    }

    ///@notice Allow an challenge manager to mint new ERC1155 challenges
    ///@dev Will throw if a particular challenge current supply has reached its maximum supply
    ///@param _to The address to mint the challenges to
    ///@param _challengeIds An array containing the identifiers of the challenges to mint
    ///@param _quantities An array containing the number of challenges to mint
    function mintChallenges(
        address _to,
        uint256[] calldata _challengeIds,
        uint256[] calldata _quantities
    ) external onlyChallengeManager {
        require(_challengeIds.length == _quantities.length, "DAOFacet: Ids and quantities length must match");
        address sender = msg.sender;
        uint256 challengeTypesLength = s.challengeTypes.length;
        for (uint256 i; i < _challengeIds.length; i++) {
            uint256 challengeId = _challengeIds[i];

            require(challengeTypesLength > challengeId, "DAOFacet: Challenge type does not exist");

            uint256 quantity = _quantities[i];
            uint256 totalQuantity = s.challengeTypes[challengeId].totalQuantity + quantity;
            require(totalQuantity <= s.challengeTypes[challengeId].maxQuantity, "DAOFacet: Total challenge type quantity exceeds max quantity");

            LibChallenges.addToOwner(_to, challengeId, quantity);
            s.challengeTypes[challengeId].totalQuantity = totalQuantity;
        }
        emit LibERC1155.TransferBatch(sender, address(0), _to, _challengeIds, _quantities);
        LibERC1155.onERC1155BatchReceived(sender, address(0), _to, _challengeIds, _quantities, "");
    }

    ///@notice Allow an challenge manager to add challenge types
    ///@param _challengeTypes An array of structs where each struct contains details about each challenge to be added
    function addChallengeTypes(ChallengeType[] memory _challengeTypes) external onlyChallengeManager {
        insertChallengeTypes(_challengeTypes);
    }

    function insertChallengeTypes(ChallengeType[] memory _challengeTypes) internal {
        uint256 challengeTypesLength = s.challengeTypes.length;
        for (uint256 i; i < _challengeTypes.length; i++) {
            uint256 challengeId = challengeTypesLength++;
            s.challengeTypes.push(_challengeTypes[i]);
            emit AddChallengeType(_challengeTypes[i]);
            emit LibERC1155.TransferSingle(msg.sender, address(0), address(0), challengeId, 0);
        }
    }

    ///@notice Allow an challenge manager to set the price of multiple challenges in GHST
    ///@dev Only valid for existing challenges that can be purchased with GHST
    ///@param _challengeIds The challenges whose price is to be changed
    ///@param _newPrices The new prices of the challenges
    function batchUpdateChallengesPrice(uint256[] calldata _challengeIds, uint256[] calldata _newPrices) public onlyChallengeManager {
        require(_challengeIds.length == _newPrices.length, "DAOFacet: Challenges must be the same length as prices");
        for (uint256 i; i < _challengeIds.length; i++) {
            uint256 challengeId = _challengeIds[i];
            ChallengeType storage challenge = s.challengeTypes[challengeId];
            challenge.prtclePrice = _newPrices[i];
            emit UpdateChallengePrice(challengeId, _newPrices[i]);
        }
    }
}
