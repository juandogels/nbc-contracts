//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./NBMonCore.sol";

/**
 * @dev Base contract used for minting NBMons. 
 */
contract NBMonMinting is NBMonCore {
    // calls _mintOrigin.
    function mintOrigin(uint256 _randomNumber, address _owner, uint32 _baseEvolveDuration) public onlyMinter {
        _mintOrigin(_randomNumber, _owner, _baseEvolveDuration);
    }

    // calls _mintWild.
    function mintWild(
        uint256 _randomNumber,
        uint32 _gender,
        uint32 _shiny,
        uint32 _genus,
        uint8 _elementOne, 
        uint8 _elementTwo,
        address _owner,
        uint32 _baseEvolveDuration
    ) public onlyMinter {
        _mintWild(_randomNumber, _gender, _shiny, _genus, _elementOne, _elementTwo, _owner, _baseEvolveDuration);
    }

    /**
     * @dev Mints an origin NBMon.
     * Note: _randomNumber will be randomized from the server side and passed on as an argument.
     * _baseEvolveDuration is set on '../gamestats/evolveDuration.txt' and will also be passed on as an argument.
     * Since the minted NBMon is always going to be an origin, the nbmonType is therefore set to 1 (origin).
     */
    function _mintOrigin(uint256 _randomNumber, address _owner, uint32 _baseEvolveDuration) private {
        uint32[] memory _nbmonStats = _randomizeNbmonStatsOrigin(_randomNumber, _baseEvolveDuration);
        uint8[] memory _elements = _randomizeElements(_randomNumber);
        uint8[] memory _potential = _randomizePotential(_randomNumber);
        uint8[] memory _inheritedPassives;
        uint8[] memory _inheritedMoves;

        NBMon memory _nbmon = NBMon(
            currentNBMonCount,
            _owner,
            block.timestamp,
            block.timestamp,
            _nbmonStats,
            _elements,
            _potential,
            _inheritedPassives,
            _inheritedMoves
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
     * @dev Wild NBMons can ONLY be minted when captured in the game.
     * When you sync your data to the blockchain, the wild NBMons that you've captured will be minted to your inventory.
     * Note: The game MUST use the defined modulo logic from NBMonCore to randomize _gender, _genera, _elementOne and _elementTwo to ensure fairness.
     */
    function _mintWild(
        uint256 _randomNumber,
        uint32 _gender,
        uint32 _shiny,
        uint32 _genus,
        uint8 _elementOne, 
        uint8 _elementTwo,
        address _owner,
        uint32 _baseEvolveDuration
        ) private {
            uint32[] memory _nbmonStats = _syncNbmonStatsWild(_randomNumber, _gender, _shiny, _genus, _baseEvolveDuration);
            uint8[] memory _elements = _syncElementsWild(_elementOne, _elementTwo);
            uint8[] memory _potential = _randomizePotential(_randomNumber);
            uint8[] memory _inheritedPassives;
            uint8[] memory _inheritedMoves;

            NBMon memory _nbmon = NBMon(
                currentNBMonCount,
                _owner,
                block.timestamp,
                block.timestamp,
                _nbmonStats,
                _elements,
                _potential,
                _inheritedPassives,
                _inheritedMoves
            );

            nbmons.push(_nbmon);
            ownerNBMons[_owner].push(_nbmon);
            _safeMint(_owner, currentNBMonCount);
            ownerNBMonIds[_owner].push(currentNBMonCount);
            currentNBMonCount++;
            ownerNBMonCount[_owner]++;
            emit NBMonMinted(currentNBMonCount, _owner);
    }

    // randomizes the potential stats for the minted NBMon.
    function _randomizePotential(uint256 _randomNumber) private view returns (uint8[] memory _potential) {
        _potential = new uint8[](7);

        for (uint8 i = 0; i < 7; i++) {
            _potential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, i))) % _maxPotential + 1);
        }

        return _potential;
    }

    // randomizes the elements of the minted NBMon.
    function _randomizeElements(uint256 _randomNumber) private view returns (uint8[] memory _elements) {
        _elements = new uint8[](2);

        for (uint8 i = 0; i < 2; i++) {
            _elements[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, i))) % _elementTypes + 1);
        }
        // first element must NOT be a null element. If it is null, it is converted to a natural species instead.
        // second element MAY be a null element.
        if (_elements[0] == 1) {
            _elements[0] = 2;
        }

        return _elements;
    }

    // syncs the elements of the wild NBMon minted
    // Note: _elementOne and _elementTwo are passed on from the game server
    function _syncElementsWild(uint8 _elementOne, uint8 _elementTwo) private pure returns (uint8[] memory _elements) {
        _elements = new uint8[](2);

        // most likely not needed since the game already checks that the wild NBMon cannot have a null first element.
        if (_elementOne == 1) {
            _elements[0] = 2;
        } else {
            _elements[0] = _elementOne;
        }
        _elements[1] = _elementTwo;

        return _elements;
    }

    //syncs the stats of the wild NBMon minted
    //_shiny is a number between 1 to _shinyChance from NBMonCore
    function _syncNbmonStatsWild(
        uint256 _randomNumber, 
        uint32 _gender, 
        uint32 _shiny,
        uint32 _genus, 
        uint32 _baseEvolveDuration
        ) private view returns (uint32[] memory _nbmonStats) {
            _nbmonStats = new uint32[](7);

            //gender is already assigned from parameter
            _nbmonStats[0] = _gender;
            //randomizing rarity
            _nbmonStats[1] = uint32(uint256(keccak256(abi.encode(_randomNumber, 1))) % _rarityChance + 1);
            //shinyChance is already assigned from parameter
            _nbmonStats[2] = _shiny;
            //nbmonType for this function is always going to be a wild, so 2.
            _nbmonStats[3] = 2;
            //_baseEvolveDuration
            //will be changed according to rarity in the server side.
            _nbmonStats[4] = _baseEvolveDuration;
            //genera is already assigned from parameter
            _nbmonStats[5] = _genus;
            //randomizing fertility
            _nbmonStats[6] = uint32(uint256(keccak256(abi.encode(_randomNumber, 6))) % _baseFertilityChance + 1);

            return _nbmonStats;
    }

    // randomizes the stats of the minted NBMon (Note: only used for _mintOrigin).
    function _randomizeNbmonStatsOrigin(uint256 _randomNumber, uint32 _baseEvolveDuration) private view returns (uint32[] memory _nbmonStats) {
        _nbmonStats = new uint32[](7);
        
        //randomizing gender
        _nbmonStats[0] = uint32(uint256(keccak256(abi.encode(_randomNumber, 0))) % _genders + 1);
        //randomizing rarity
        _nbmonStats[1] = uint32(uint256(keccak256(abi.encode(_randomNumber, 1))) % _rarityChance + 1);
        //randomizing isShiny
        _nbmonStats[2] = uint32(uint256(keccak256(abi.encode(_randomNumber, 2))) % _shinyChance + 1);
        //nbmonType for this function is always going to be an origin, so 1.
        _nbmonStats[3] = 1;
        //_baseEvolveDuration
        //will be changed according to rarity in the server side.
        _nbmonStats[4] = _baseEvolveDuration;
        //randomizing genus
        _nbmonStats[5] = uint32(uint256(keccak256(abi.encode(_randomNumber, 5))) % _genera + 1);
        //randomizing fertility
        _nbmonStats[6] = uint32(uint256(keccak256(abi.encode(_randomNumber, 6))) % _baseFertilityChance + 1);

        return _nbmonStats;
    }
}