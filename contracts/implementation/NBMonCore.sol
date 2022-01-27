//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "../BEP721/NFTCore.sol";
import "../security/Ownable.sol";

/**
 @dev Base contract for NBMon which contains all functionality and methods related with our Realm Hunter game
 */
contract NBMonCore is NFTCore {
    constructor() BEP721("NBMon", "NBMON") {
        // sets URI of NBMons
        setBaseURI("https://nbcompany.io/nbmon/");

        ///maps genus to types
        // Lamox = toxic, electric 
        _type[1] = [4, 15];
        // Licorine = fire, earth
        _type[2] = [2, 5];
        // Birvo = wind
        _type[3] = [6, 0];
        // Dranexx = spirit, psychic
        _type[4] = [11, 13];
        // Heree = nature
        _type[5] = [9, 0];
        // Milnas = fire
        _type[6] = [2, 0];
        // Schoggi = ordinary
        _type[7] = [1, 0];
        // Pongu = frost, crystal
        _type[8] = [7, 8];
        // Prawdek = nature, toxic
        _type[9] = [9, 15];
        // Roggo = earth, nature
        _type[10] = [5, 9];
        // Todillo = earth, reptile
        _type[11] = [5, 14];
    }

    /**
     * @dev Instance of an NBMon with detailed stats instantiated as a struct
     * Note: A lot of the fields are assigned a uint type so that changes are easier to be amended in the future.
     */
    struct NBMon {
        // tokenId for NBMon
        uint256 nbmonId;
        // current owner for NBMon
        address owner;
        uint256 bornAt;
        // timestamp of when NBMon was transferred to current owner (when selling in marketplace, transferring from wallet etc)
        uint256 transferredAt;
        // contains gender, rarity, mutation, species, evolveDuration, genera and fertility
        // check '../gamestats/genders.txt' for more info.
        // check '../gamestats/rarity.txt' for more info.
        // check '../gamestats/mutation.txt' for more info.
        // check '../gamestats/species.txt' for more info.
        // check '../gamestats/genera.txt' for more info.
        // check '../gamestats/fertility.txt' for more info
        uint32[] nbmonStats;

        // Each NBMon can have up to two types. types are predetermined depending on the genus.
        // more on types at '../gamestats/types.txt'
        uint8[] types;

        /// @dev contains all of the potential of the NBMon
        /// including health pool, energy, attack, defense, special attack, special defense, speed
        /// Note: does NOT take into consideration of rarity in the blockchain side. Actual potential stats will be reflected in-game.
        /// check '../gamestats/potential.txt' for more info.
        uint8[] potential;

        /// @dev contains the passives of the NBMon
        // when minted, it will pick 2 of the available passives.
        // all available passives are found in '../gamestats/passives.txt'
        uint16[] passives;

        // only used for breeding to inherit 2 passives from the passive set of the parent NBMons
        // if minted, it will be an empty array
        // check '../gamestats/passives.txt' for more info
        uint8[] inheritedPassives;

        // only used for breeding to inherit 2 moves from the move set of the parent NBMons
        // if minted, it will be an empty array
        // check '../gamestats/moveset.txt' for more info
        uint8[] inheritedMoves; 

        // checks if offspring is still an egg based on baseEvolutionDuration.
        // logic: if bornAt + baseEvolutionDuration <= now, user can evolve NBMon.
        bool isEgg; 
    }

    NBMon[] internal nbmons;

    // mapping from owner address to amount of NBMons owned
    mapping(address => uint256) internal ownerNBMonCount;
    // mapping from owner address to array of IDs of the NBMons the owner owns
    mapping(address => uint256[]) internal ownerNBMonIds;
    // mapping from owner address to list of NBMons owned;
    mapping(address => NBMon[]) internal ownerNBMons;

    //mapping from genus to types of respective genus
    // e.g. 1 (Lamox) -> [8, 19] (electric, toxic)
    mapping(uint32 => uint8[]) internal _type;
    
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

    // updates or adds types of specified genus to _type mapping
    function updateTypesOfGenus(uint32 _genus, uint8 _typeOne, uint8 _typeTwo) public onlyAdmin {
        _type[_genus] = [_typeOne, _typeTwo];
    }

    // returns the types of the specified genus
    function getTypesOfGenus(uint32 _genus) public view returns (uint8[] memory) {
        return _type[_genus];
    }

    // burns and deletes the NBMon from circulating supply
    function burnNBMon(uint256 _nbmonId) public {
        require(_exists(_nbmonId), "NBMonCore: Burning non-existant NBMon");
        require(nbmons[_nbmonId - 1].owner == _msgSender(), "NBMonCore: Owner does not own specified NBMon.");
        _burn(_nbmonId);
        emit NBMonBurned(_nbmonId);
    }

    /**
     * @dev These numbers are the base modulo for the values of each NBMon stat. If changed, the minted NBMon can have a different stat based on the new modulo.
     * Note: Bear in mind that the descriptions for each variable are based off during contract deployment. These variables may change. 
     * Check in BSCSCAN or by taking an instance of this contract for the actual values of each variable.
     */
    uint8 public _totalGenders = 2;
    // check ../gamestats/rarity.txt for further information
    uint16 public _rarityChance = 1000;
    // chance for mutation is 1/1000. will change for breeding depending if one or both parents are mutated.
    // check ../gamestats/mutation.txt for further information.
    uint16 public _mutationChance = 1000;
    // used during breeding. chance for mutation is 1/100 if one parent is mutated.
    uint16 public _oneParentMutationChance = 100;
    // used during breeding. chance for mutation is 1/10 if both parents are mutated.
    uint16 public _twoParentsMutationChance = 10;
    // assumes each NBMon has 4 possible mutation types.
    // 0 if not mutated, 1-4 if mutated. check ../gamestats/mutation.txt for further information.
    uint8 public _mutationTypes = 4;
    // check ../gamestats/species.txt for further information
    uint8 public _totalSpecies = 3;
    //check ../gamestats/genera.txt for further information
    uint16 public _totalGenera = 11;
    //types such as fire, water etc. check ../gamestats/types.txt' for further information.
    uint8 public _totalTypes = 13;
    //passives found under ../gamestats/passives.txt 
    uint16 public _totalPassives = 24;
    //check ../gamestats/potential.txt for further information.
    uint8 public _maxPotential = 65;
    // depending on the rarity, the amount of fertility points you lose will differ.
    // check ../gamestats/fertility.txt' for further information
    uint16 public _maxFertilityPoints = 3000;
    // how long an NBMon needs to wait since it was born until it can evolve to an adult NBMon from its egg. Minted NBMons will instantly be born.
    // 259200 seconds/3 days is the base duration for a common NBMon. Each rarity increase increases the evolution duration by 1 day.
    uint32 public _baseEvolutionDuration = 259200;

    /// @dev Functions for changing the modulo
    function changeTotalGenders(uint8 totalGenders_) public onlyAdmin {
        _totalGenders = totalGenders_;
    }
    function changeRarityChance(uint16 rarityChance_) public onlyAdmin {
        _rarityChance = rarityChance_;
    }
    function changeMutationChance(uint16 mutationChance_) public onlyAdmin {
        _mutationChance = mutationChance_;
    }
    function changeMutationTypes(uint8 mutationTypes_) public onlyAdmin {
        _mutationTypes = mutationTypes_;
    }
    function changeTotalSpecies(uint8 totalSpecies_) public onlyAdmin {
        _totalSpecies = totalSpecies_;
    }
    function changeTotalGenera(uint16 totalGenera_) public onlyAdmin {
        _totalGenera = totalGenera_;
    }
    function changeTypes(uint8 totalTypes_) public onlyAdmin {
        _totalTypes = totalTypes_;
    }
    function changeMaxPotential(uint8 maxPotential_) public onlyAdmin {
        _maxPotential = maxPotential_;
    }
    function changeMaxFertilityPoints(uint16 maxFertilityPoints_) public onlyAdmin {
        _maxFertilityPoints = maxFertilityPoints_;
    }
    function changeBaseEvolutionDuration(uint32 baseEvolutionDuration_) public onlyAdmin {
        _baseEvolutionDuration = baseEvolutionDuration_;
    }
    /**
     * END OF BASE STATS CHANGE
     */

    /**
     * @dev Singular purpose functions designed to make reading code easier for front-end
     * Otherwise not needed since getNBMon and getAllNBMonsOfOwner and getNBMon contains complete information at once
     */
    function getNbmonStats(uint256 _nbmonId) public view returns (uint32[] memory) {
        return nbmons[_nbmonId - 1].nbmonStats;
    }
    function getBornAt(uint256 _nbmonId) public view returns (uint256) {
        return nbmons[_nbmonId - 1].bornAt;
    }
    function getTransferredAt(uint256 _nbmonId) public view returns (uint256) {
        return nbmons[_nbmonId - 1].transferredAt;
    }
    function getTypes(uint256 _nbmonId) public view returns (uint8[] memory) {
        return nbmons[_nbmonId - 1].types;
    }
    function getPotential(uint256 _nbmonId) public view returns (uint8[] memory) {
        return nbmons[_nbmonId - 1].potential;
    }
    function getPassives(uint256 _nbmonId) public view returns (uint16[] memory) {
        return nbmons[_nbmonId - 1].passives;
    }
    function getInheritedPassives(uint256 _nbmonId) public view returns (uint8[] memory) {
        return nbmons[_nbmonId - 1].inheritedPassives;
    }
    function getInheritedMoves(uint256 _nbmonId) public view returns (uint8[] memory) {
        return nbmons[_nbmonId - 1].inheritedMoves;
    }
}