//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../BEP721/NFTCore.sol";

/**
 @dev Base contract for NBMon which contains all functionality and methods related with our Realm Hunter game
 */
contract NBMonCore is NFTCore {
    constructor() BEP721("NBMon", "NBMON") {
        setBaseURI("https://nbcompany.io/nbmon/");
    }

    /**
     * @dev Instance of an NBMon with detailed stats instantiated as a struct
     * Note: A lot of the fields are assigned a uint type so that changes are easier to be amended in the future.
     */
    struct NBMon {
        // tokenId for NBMon
        uint256 nbmonId;
        // check './gamestats/genders.txt' for more info.
        uint8 gender;
        // check './gamestats/rarityChance.txt' for more info.
        uint8 rarity;
        // check './gamestats/shinyChance.txt' for more info.
        bool isShiny;
        // current owner for NBMon
        address owner;
        // timestamp of when NBMon is/was born
        uint256 bornAt;
        // timestamp of when NBMon was transferred to current owner (when selling in marketplace, transferring from wallet etc)
        uint256 transferredAt;
        //check './gamestats/evolveDuration.txt' for more info.
        uint32 evolveDuration;
        // check './gamestats/nbmonTypes.txt' for more info.
        uint8 nbmonType;
        // check './gamestats/genera.txt' for more info.
        uint16 genera;

        // Each NBMon can have up to two elements. There is also a chance to get "null" for any of the two element slots.
        // more on elements at './gamestats/elements.txt'
        uint8 elementOne;
        uint8 elementTwo;

        /// @dev contains all of the potential of the NBMon
        /// including health pool, energy, attack, special attack, defense, special defense, speed
        /// Note: does NOT take into consideration of rarity in the blockchain side. Actual EV stats will be reflected in-game.
        /// check './gamestats/potential.txt' for more info.
        uint8 hpPotential;
        uint8 energyPotential;
        uint8 attackPotential;
        uint8 defensePotential;
        uint8 spAttPotential;
        uint8 spDefPotential;
        uint8 speedPotential;

        // only used for breeding to inherit 2 passives from the passive set of the parent NBMons
        // check './gamestats/passives.txt' for more info
        uint8 passiveOne;
        uint8 passiveTwo;

        // only used for breeding to inherit 2 moves from the move set of the parent NBMons
        // check './gamestats/moveset.txt' for more info
        uint8 moveOne;
        uint8 moveTwo;

        // checks the amount of times it can breed. maximum fertility is 8
        // check './gamestats/fertility.txt' for more info
        uint16 fertility;
    }

    NBMon[] internal nbmons;

    // mapping from owner address to amount of NBMons owned
    mapping(address => uint256) internal ownerNBMonCount;
    // mapping from owner address to array of IDs of the NBMons the owner owns
    mapping(address => uint256[]) internal ownerNBMonIds;
    // mapping from owner address to list of NBMons owned;
    mapping(address => NBMon[]) internal ownerNBMons;

    // checks the current NBMon supply for enumeration. Starts at 1 when contract is deployed.
    uint256 public currentNBMonCount = 1;

    event NBMonMinted(uint256 indexed _nbmonId, address indexed _owner);
    event NBMonBurned(uint256 indexed _nbmonId);

    // returns a single NBMon given an ID
    function getNBMon(uint256 _nbmonId) public view returns (NBMon memory) {
        require(_exists(_nbmonId), "NBMonCore: NBMon with the specified ID does not exist");
        return nbmons[_nbmonId - 1];
    }

    // returns all NBMons owned by the owner
    function getAllNBMonsOfOwner(address _owner) public view returns (NBMon[] memory) {
        return ownerNBMons[_owner];
    }

    //returns the amount of NBMons the owner has
    function getOwnerNBMonCount(address _owner) public view returns (uint256) {
        return ownerNBMonCount[_owner];
    }

    // returns the NBMon IDs of the owner's NBMons
    function getOwnerNBMonIds(address _owner) public view returns (uint256[] memory) {
        return ownerNBMonIds[_owner];
    }

    /**
     * @dev These numbers are the base modulo for the values of each NBMon stat. If changed, the minted NBMon can have a different stat.
     * Note: Bare in mind that the descriptions for each variable are based off during contract deployment. These variables may change. 
     * Check in BSCSCAN or by taking an instance of this contract for the actual values of each variable.
     */
    uint8 public _genders = 2;
    // check ./gamestats/rarityChance.txt for further information
    uint16 public _rarityChance = 1000;
    // check ./gamestats/nbmonTypes.txt for further information
    uint8 public _nbmonTypes = 3;
    uint16 public _genus = 11;
    // chance to obtain shiny NBMon is 1/4096.
    uint16 public _shinyChance = 4096;
    //if result is 1, it's considered null, and therefore no element is assigned. 2-13 are elements identified in elements.txt.
    uint8 public _elementTypes = 13;
    uint8 public _maxPotential = 65;
    // an NBMon can have 0-8 fertility. however, depending on the rarity, the end fertility result will be different and that's why a base fertility chance is used.
    // check ./gamestats/fertility.txt' for further information
    uint16 public _baseFertilityChance = 900;

    function changeGenders(uint8 genders_) public onlyAdmin {
        _genders = genders_;
    }
    function changeRarityChance(uint16 rarityChance_) public onlyAdmin {
        _rarityChance = rarityChance_;
    }
    function changeNbmonTypes(uint8 nbmonTypes_) public onlyAdmin {
        _nbmonTypes = nbmonTypes_;
    }
    function changeGenus(uint16 genus_) public onlyAdmin {
        _genus = genus_;
    }
    function changeShinyChance(uint8 shinyChance_) public onlyAdmin {
        _shinyChance = shinyChance_;
    }
    function changeelementTypes(uint8 elementTypes_) public onlyAdmin {
        _elementTypes = elementTypes_;
    }
    function changeMaxPotential(uint8 maxPotential_) public onlyAdmin {
        _maxPotential = maxPotential_;
    }
    function changeBaseFertilityChance(uint16 baseFertilityChance_) public onlyAdmin {
        _baseFertilityChance = baseFertilityChance_;
    }
    /**
     * END OF BASE STATS CHANGE
     */

     function mintOrigin(uint256 _randomNumber, address _owner, uint32 _evolveDurationTime) public {
         _mintOrigin(_randomNumber, _owner, _evolveDurationTime);
     }

    /// Note: _randomNumber will be randomized from the server side and passed on as an argument.
    function _mintOrigin(uint256 _randomNumber, address _owner, uint32 _evolveDurationTime) private {
        uint256[] memory values = new uint256[](15);
        for (uint256 i = 0; i < 15; i++) {
            values[i] = uint256(keccak256(abi.encode(_randomNumber, i)));
        }
        uint8 _gender = uint8(values[0] % _genders) + 1;
        uint8 _rarity = uint8(values[1] % _rarityChance) + 1;
        uint8 _isShiny = uint8(values[2] % _shinyChance) + 1;
        uint8 _nbmonType = uint8(values[3] % 1) + 1;
        uint16 _genera = uint16(values[4] % _genus) + 1;
        uint8 _elementOne = uint8(values[5] % _elementTypes) + 1;
        uint8 _elementTwo = uint8(values[6] % _elementTypes) + 1;
        uint8 _hpPotential = uint8(values[7] % _maxPotential) + 1;
        uint8 _energyPotential = uint8(values[8] % _maxPotential) + 1;
        uint8 _attackPotential = uint8(values[9] % _maxPotential) + 1;
        uint8 _defensePotential = uint8(values[10] % _maxPotential) + 1;
        uint8 _spAttPotential = uint8(values[11] % _maxPotential) + 1;
        uint8 _spDefPotential = uint8(values[12] % _maxPotential) + 1;
        uint8 _speedPotential = uint8(values[13] % _maxPotential) + 1;
        uint8 _fertility = uint8(values[14] % _baseFertilityChance) + 1;

        uint8 gender_;
        uint8 rarity_;
        bool isShiny_;
        uint8 nbmonType_;
        uint16 genera_;
        uint8 elementOne_;
        uint8 elementTwo_;
        uint8 hpPotential_;
        uint8 energyPotential_;
        uint8 attackPotential_;
        uint8 defensePotential_;
        uint8 spAttPotential_;
        uint8 spDefPotential_;
        uint8 speedPotential_;
        uint8 fertility_;

        // assign gender_ to result obtained from randomization (_gender)
        gender_ = _gender;
        // assign rarity_ to result obtained from randomization (_rarity)
        rarity_ = _rarity;
        // assign isShiny_ to result obtained from randomization (_isShiny)
        if (_isShiny <= 1) {
            isShiny_ = true;
        } else {
            isShiny_ = false;
        }
        // assign nbmonType_ to result obtained from randomization (_nbmonType)
        nbmonType_ = _nbmonType;
        //assign genera_ to result obtained from randomization (_genera)
        genera_ = _genera;
        //assign elementOne and elementTwo to result obtained from randomization (_elementOne)
        //elementOne MUST be a non-null element. If it is = 1 (= null), it will get the neutral element instead.
        if (_elementOne == 1) {
            elementOne_ = 2;
        } else {
            elementOne_ = _elementOne;
        }
        elementTwo_ = _elementTwo;
        //assign all the Potentials to the result obtained from randomization (_hpPotential, _energyPotential etc)
        hpPotential_ = _hpPotential;
        energyPotential_ = _energyPotential;
        attackPotential_ = _attackPotential;
        defensePotential_ = _defensePotential;
        spAttPotential_ = _spAttPotential;
        spDefPotential_ = _spDefPotential;
        speedPotential_ = _speedPotential;
        //assign fertility_ to result obtained from randomization (_fertility)
        fertility_ = _fertility;

        NBMon memory _nbmon = NBMon(
            currentNBMonCount,
            gender_,
            rarity_,
            isShiny_,
            _owner,
            block.timestamp,
            block.timestamp,
            _evolveDurationTime,
            nbmonType_,
            genera_,
            elementOne_,
            elementTwo_,
            hpPotential_,
            energyPotential_,
            attackPotential_,
            defensePotential_,
            spAttPotential_,
            spDefPotential_,
            speedPotential_,
            0,
            0,
            0,
            0,
            fertility_
        );
        nbmons.push(_nbmon);
        ownerNBMons[_owner].push(_nbmon);
        _safeMint(_owner, currentNBMonCount);
        ownerNBMonIds[_owner].push(currentNBMonCount);
        currentNBMonCount++;
        ownerNBMonCount[_owner]++;
        emit NBMonMinted(currentNBMonCount, _owner);
    }

    /**
     * @dev Singular purpose functions designed to make reading code easier for front-end
     * Otherwise not needed since getNBMon and getAllNBMonsOfOwner and getNBMon contains complete information at once
     */
    function getGender(uint256 _nbmonId) public view returns (uint8) {
        return nbmons[_nbmonId - 1].gender;
    }
    function getRarity(uint256 _nbmonId) public view returns (uint8) {
        return nbmons[_nbmonId - 1].rarity;
    }
    function getIsShiny(uint256 _nbmonId) public view returns (bool) {
         return nbmons[_nbmonId - 1].isShiny;
    }
    function getBornAt(uint256 _nbmonId) public view returns (uint256) {
        return nbmons[_nbmonId - 1].bornAt;
    }
    function getTransferredAt(uint256 _nbmonId) public view returns (uint256) {
        return nbmons[_nbmonId - 1].transferredAt;
    }
    function getEvolveDuration(uint256 _nbmonId) public view returns (uint32) {
        return nbmons[_nbmonId - 1].evolveDuration;
    }
    function getNbmonType(uint256 _nbmonId) public view returns (uint8) {
        return nbmons[_nbmonId - 1].nbmonType;
    }
     function getGenera(uint256 _nbmonId) public view returns (uint16) {
        return nbmons[_nbmonId - 1].genera;
    }
    function getelementOne(uint256 _nbmonId) public view returns (uint8) {
        return nbmons[_nbmonId - 1].elementOne;
    }
    function getelementTwo(uint256 _nbmonId) public view returns (uint8) {
        return nbmons[_nbmonId - 1].elementTwo;
    }
    function getComboPotential(uint256 _nbmonId) public view returns (
        uint8 _hpPotential,
        uint8 _energyPotential,
        uint8 _attackPotential,
        uint8 _defensePotential,
        uint8 _spAttPotential,
        uint8 _spDefPotential,
        uint8 _speedPotential
    ) {
        NBMon memory _nbmon = nbmons[_nbmonId - 1];
        return (
            _nbmon.hpPotential,
            _nbmon.energyPotential,
            _nbmon.attackPotential,
            _nbmon.defensePotential,
            _nbmon.spAttPotential,
            _nbmon.spDefPotential,
            _nbmon.speedPotential
        );
    }

    function getPassiveOne(uint256 _nbmonId) public view returns (uint8) {
        return nbmons[_nbmonId - 1].passiveOne;
    }
    function getPassiveTwo(uint256 _nbmonId) public view returns (uint8) {
        return nbmons[_nbmonId - 1].passiveTwo;
    }
    function getMoveOne(uint256 _nbmonId) public view returns (uint8) {
        return nbmons[_nbmonId - 1].moveOne;
    }
    function getMoveTwo(uint256 _nbmonId) public view returns (uint8) {
        return nbmons[_nbmonId - 1].moveTwo;
    }

    function getFertility(uint256 _nbmonId) public view returns (uint16) {
        return nbmons[_nbmonId - 1].fertility;
    }
}