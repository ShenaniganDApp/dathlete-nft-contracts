// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Modifiers, AppStorage, ChallengeType, Season} from "../libraries/LibAppStorage.sol";
import {LibDathlete} from "../libraries/LibDathlete.sol";
// import "hardhat/console.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {LibERC721} from "../libraries/LibERC721.sol";
import {LibERC1155} from "../libraries/LibERC1155.sol";
import {LibChallenges} from "../libraries/LibChallenges.sol";

contract ShopFacet is Modifiers {
    event MintDathletes(
        address indexed _from,
        address indexed _to,
        // uint256 indexed _batchId,
        uint256 _tokenId,
        uint256 _numDathletesToPurchase,
        uint256 seasonId
    );

    event BuyDathletes(
        address indexed _from,
        address indexed _to,
        // uint256 indexed _batchId,
        uint256 _tokenId,
        uint256 _numDathletesToPurchase,
        uint256 _totalPrice
    );

    event PurchaseChallengesWithPrtcle(
        address indexed _buyer,
        address indexed _to,
        uint256[] _challengeIds,
        uint256[] _quantities,
        uint256 _totalPrice
    );
    event PurchaseTransferChallengesWithPrtcle(
        address indexed _buyer,
        address indexed _to,
        uint256[] _challengeIds,
        uint256[] _quantities,
        uint256 _totalPrice
    );

    ///@notice Allow an address to purchase a dathlete
    ///@dev Only dathletes from season 1 can be purchased via the contract
    ///@param _to Address to send the dathlete once purchased
    ///@param _prtcle The amount of PRTCLE the buyer is willing to pay //calculation will be done to know how much dathlete he recieves based on the season's dathlete price
    function buyDathletes(address _to, uint256 _prtcle) external {
        uint256 currentSeasonId = s.currentSeasonId;
        require(currentSeasonId == 1, "ShopFacet: Can only purchase from Season 1");
        Season storage season = s.seasons[currentSeasonId];
        uint256 price = season.dathletePrice;
        require(_prtcle >= price, "Not enough PRTCLE to buy dathletes");
        uint256[3] memory tiers;
        tiers[0] = price * 5;
        tiers[1] = tiers[0] + (price * 2 * 10);
        tiers[2] = tiers[1] + (price * 3 * 10);
        require(_prtcle <= tiers[2], "Can't buy more than 25");
        address sender = msg.sender;
        uint256 numToPurchase;
        uint256 totalPrice;
        if (_prtcle <= tiers[0]) {
            numToPurchase = _prtcle / price;
            totalPrice = numToPurchase * price;
        } else {
            if (_prtcle <= tiers[1]) {
                numToPurchase = (_prtcle - tiers[0]) / (price * 2);
                totalPrice = tiers[0] + (numToPurchase * (price * 2));
                numToPurchase += 5;
            } else {
                numToPurchase = (_prtcle - tiers[1]) / (price * 3);
                totalPrice = tiers[1] + (numToPurchase * (price * 3));
                numToPurchase += 15;
            }
        }
        uint256 seasonCount = season.totalCount + numToPurchase;
        require(seasonCount <= season.seasonMaxSize, "ShopFacet: Exceeded max number of dathletes for this season");
        s.seasons[currentSeasonId].totalCount = uint24(seasonCount);
        uint32 tokenId = s.tokenIdCounter;
        emit BuyDathletes(sender, _to, tokenId, numToPurchase, totalPrice);
        for (uint256 i; i < numToPurchase; i++) {
            s.dathletes[tokenId].owner = _to;
            s.dathletes[tokenId].seasonId = uint16(currentSeasonId);
            s.tokenIdIndexes[tokenId] = s.tokenIds.length;
            s.tokenIds.push(tokenId);
            s.ownerTokenIdIndexes[_to][tokenId] = s.ownerTokenIds[_to].length;
            s.ownerTokenIds[_to].push(tokenId);
            emit LibERC721.Transfer(address(0), _to, tokenId);
            tokenId++;
        }
        s.tokenIdCounter = tokenId;
        // LibDathlete.verify(tokenId);
        LibDathlete.purchase(sender, totalPrice);
    }

    ///@notice Allow an challenge manager to mint neew dathletes
    ///@dev Will throw if the max number of dathletes for the current season has been reached
    ///@param _to The destination of the minted dathletes
    ///@param _amount the amunt of dathletes to mint
    function mintDathletes(address _to, uint256 _amount) external onlyChallengeManager {
        uint256 currentSeasonId = s.currentSeasonId;
        Season storage season = s.seasons[currentSeasonId];
        address sender = msg.sender;
        uint256 seasonCount = season.totalCount + _amount;
        require(seasonCount <= season.seasonMaxSize, "ShopFacet: Exceeded max number of dathletes for this season");
        s.seasons[currentSeasonId].totalCount = uint24(seasonCount);
        uint32 tokenId = s.tokenIdCounter;
        emit MintDathletes(sender, _to, tokenId, _amount, currentSeasonId);
        for (uint256 i; i < _amount; i++) {
            s.dathletes[tokenId].owner = _to;
            s.dathletes[tokenId].seasonId = uint16(currentSeasonId);
            s.tokenIdIndexes[tokenId] = s.tokenIds.length;
            s.tokenIds.push(tokenId);
            s.ownerTokenIdIndexes[_to][tokenId] = s.ownerTokenIds[_to].length;
            s.ownerTokenIds[_to].push(tokenId);
            emit LibERC721.Transfer(address(0), _to, tokenId);
            tokenId++;
        }
        s.tokenIdCounter = tokenId;
    }

    ///@notice Allow an address to purchase multiple challenges
    ///@dev Buying an challenge typically mints it, it will throw if an challenge has reached its maximum quantity
    ///@param _to Address to send the challenges once purchased
    ///@param _challengeIds The identifiers of the challenges to be purchased
    ///@param _quantities The quantities of each challenge to be bought
    function purchaseChallengesWithPrtcle(
        address _to,
        uint256[] calldata _challengeIds,
        uint256[] calldata _quantities
    ) external {
        address sender = msg.sender;
        require(_challengeIds.length == _quantities.length, "ShopFacet: _challengeIds not same length as _quantities");
        uint256 totalPrice;
        for (uint256 i; i < _challengeIds.length; i++) {
            uint256 challengeId = _challengeIds[i];
            uint256 quantity = _quantities[i];
            ChallengeType storage challengeType = s.challengeTypes[challengeId];
            require(challengeType.canPurchaseWithPrtcle, "ShopFacet: Can't purchase challenge type with PRTCLE");
            uint256 totalQuantity = challengeType.totalQuantity + quantity;
            require(totalQuantity <= challengeType.maxQuantity, "ShopFacet: Total challenge type quantity exceeds max quantity");
            challengeType.totalQuantity = totalQuantity;
            totalPrice += quantity * challengeType.prtclePrice;
            LibChallenges.addToOwner(_to, challengeId, quantity);
        }
        uint256 prtcleBalance = IERC20(s.prtcleContract).balanceOf(sender);
        require(prtcleBalance >= totalPrice, "ShopFacet: Not enough PRTCLE!");
        emit PurchaseChallengesWithPrtcle(sender, _to, _challengeIds, _quantities, totalPrice);
        emit LibERC1155.TransferBatch(sender, address(0), _to, _challengeIds, _quantities);
        LibDathlete.purchase(sender, totalPrice);
        LibERC1155.onERC1155BatchReceived(sender, address(0), _to, _challengeIds, _quantities, "");
    }

    ///@notice Allow an address to purchase multiple challenges after they have been minted
    ///@dev Only one challenge per transaction can be purchased from the Diamond contract
    ///@param _to Address to send the challenges once purchased
    ///@param _challengeIds The identifiers of the challenges to be purchased
    ///@param _quantities The quantities of each challenge to be bought

    function purchaseTransferChallengesWithPrtcle(
        address _to,
        uint256[] calldata _challengeIds,
        uint256[] calldata _quantities
    ) external {
        require(_to != address(0), "ShopFacet: Can't transfer to 0 address");
        require(_challengeIds.length == _quantities.length, "ShopFacet: ids not same length as values");
        address sender = msg.sender;
        address from = address(this);
        uint256 totalPrice;
        for (uint256 i; i < _challengeIds.length; i++) {
            uint256 challengeId = _challengeIds[i];
            uint256 quantity = _quantities[i];
            require(quantity == 1, "ShopFacet: Can only purchase 1 of an challenge per transaction");
            ChallengeType storage challengeType = s.challengeTypes[challengeId];
            require(challengeType.canPurchaseWithPrtcle, "ShopFacet: Can't purchase challenge type with PRTCLE");
            totalPrice += quantity * challengeType.prtclePrice;
            LibChallenges.removeFromOwner(from, challengeId, quantity);
            LibChallenges.addToOwner(_to, challengeId, quantity);
        }
        uint256 prtcleBalance = IERC20(s.prtcleContract).balanceOf(sender);
        require(prtcleBalance >= totalPrice, "ShopFacet: Not enough PRTCLE!");
        emit LibERC1155.TransferBatch(sender, from, _to, _challengeIds, _quantities);
        emit PurchaseTransferChallengesWithPrtcle(sender, _to, _challengeIds, _quantities, totalPrice);
        LibDathlete.purchase(sender, totalPrice);
        LibERC1155.onERC1155BatchReceived(sender, from, _to, _challengeIds, _quantities, "");
    }
}
