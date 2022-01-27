//SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

import "./NBMonCore.sol";

/**
 * @dev Base contract used for minting NBMons. 
 */
contract NBMonMinting is NBMonCore {
    // calls _mintOrigin.
    function mintOrigin(uint256 _randomNumber, address _owner) public onlyMinter {
        _mintOrigin(_randomNumber, _owner);
    }

    // calls _mintWild.
    function mintWild(
        uint256 _randomNumber,
        uint32 _gender,
        uint32 _mutation,
        uint32 _genus,
        address _owner
    ) public onlyMinter {
        _mintWild(_randomNumber, _gender, _mutation, _genus, _owner);
    }

    /**
     * @dev Mints an origin NBMon.
     * Note: _randomNumber will be randomized from the server side and passed on as an argument.
     * _baseEvolveDuration is set on '../gamestats/evolveDuration.txt' and will also be passed on as an argument.
     * Since the minted NBMon is always going to be an origin, the nbmonType is therefore set to 1 (origin).
     */
    function _mintOrigin(uint256 _randomNumber, address _owner) private {
        uint32[] memory _nbmonStats = _randomizeNbmonStats(_randomNumber);

        //getting types from genus (_nbmonStats[4])
        uint32 _genus = _nbmonStats[4];
        //gets types of genus from _type mapping
        uint8[] memory _nbmonTypes = _type[_genus];

        //randomizing potential based on rarity
        uint8[] memory _potential = new uint8[](7);
        uint32 _rarity = _nbmonStats[1];
        //using current logic from ../gamestats/rarity.txt
        //if rarity = common
        if (_rarity <= 649) {
            for (uint8 i = 0; i < 7; i++) {
                //potential is between 0 to 20
                _potential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, i))) % 21);
            }
        //if rarity = uncommon
        } else if (_rarity <= 849) {
            for (uint8 i = 0; i < 7; i++) {
                //potential is between 8 and 25
                _potential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, i))) % 18 + 8);
            }
        //if rarity == rare
        } else if (_rarity <= 949) {
            for (uint8 i = 0; i < 7; i++) {
                //potential is between 16 and 35
                _potential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, i))) % 20 + 16);
            }
        //if rarity = epic
        } else if (_rarity <= 989) {
            for (uint8 i = 0; i < 7; i++) {
                //potential is between 25 and 45
                _potential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, i))) % 21 + 25);
            }
        //if rarity = legendary
        } else if (_rarity <= 998) {
            for (uint8 i = 0; i < 7; i++) {
                //potential is between 35 and 55
                _potential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, i))) % 21 + 35);
            } 
        // if rarity = mythical
        } else if (_rarity == 999) {
           for (uint8 i = 0; i < 7; i++) {
                //potential is between 46 and 65
                _potential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, i))) % 20 + 46);
            }  
        }

        uint16[] memory _passives = _randomizePassives(_randomNumber);
        uint8[] memory _inheritedPassives;
        uint8[] memory _inheritedMoves;

        NBMon memory _nbmon = NBMon(
            currentNBMonCount,
            _owner,
            block.timestamp,
            block.timestamp,
            _nbmonStats,
            _nbmonTypes,
            _potential,
            _passives,
            _inheritedPassives,
            _inheritedMoves,
            false
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
     * The game will handle _gender, _mutation and _genus.
     * Note: Wild NBMons' genera MUST already be paired with their respective types.
     */
    function _mintWild(
        uint256 _randomNumber,
        uint32 _gender,
        uint32 _mutation,
        uint32 _genus,
        address _owner
        ) private {
            uint32[] memory _nbmonStats = _syncNbmonStatsWild(_randomNumber, _gender, _mutation, _genus);
            //gets types of genus from _type mapping
            //assumes that genus is already paired with their respective types
            uint8[] memory _nbmonTypes = _type[_genus];

            //randomizing potential based on rarity
            uint8[] memory _potential = new uint8[](7);
            uint32 _rarity = _nbmonStats[1];
            //using current logic from ../gamestats/rarity.txt
            //if rarity = common
            if (_rarity <= 649) {
            for (uint8 i = 0; i < 7; i++) {
                //potential is between 0 to 15
                _potential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, i))) % 16);
            }
            //if rarity = uncommon
            } else if (_rarity <= 849) {
                for (uint8 i = 0; i < 7; i++) {
                    //potential is between 5 and 20
                    _potential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, i))) % 16 + 5);
                }
            //if rarity == rare
            } else if (_rarity <= 949) {
                for (uint8 i = 0; i < 7; i++) {
                    //potential is between 11 and 25
                    _potential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, i))) % 15 + 11);
                }
            //if rarity = epic
            } else if (_rarity <= 989) {
                for (uint8 i = 0; i < 7; i++) {
                    //potential is between 18 and 30
                    _potential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, i))) % 13 + 18);
                }
            //if rarity = legendary
            } else if (_rarity <= 998) {
                for (uint8 i = 0; i < 7; i++) {
                    //potential is between 26 and 40
                    _potential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, i))) % 15 + 26);
                } 
            // if rarity = mythical
            } else if (_rarity == 999) {
            for (uint8 i = 0; i < 7; i++) {
                    //potential is between 35 and 50
                    _potential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, i))) % 16 + 35);
                }  
            }

            uint16[] memory _passives = _randomizePassives(_randomNumber);
            uint8[] memory _inheritedPassives;
            uint8[] memory _inheritedMoves;

            NBMon memory _nbmon = NBMon(
                currentNBMonCount,
                _owner,
                block.timestamp,
                block.timestamp,
                _nbmonStats,
                _nbmonTypes,
                _potential,
                _passives,
                _inheritedPassives,
                _inheritedMoves,
                false
            );

            nbmons.push(_nbmon);
            ownerNBMons[_owner].push(_nbmon);
            _safeMint(_owner, currentNBMonCount);
            ownerNBMonIds[_owner].push(currentNBMonCount);
            currentNBMonCount++;
            ownerNBMonCount[_owner]++;
            emit NBMonMinted(currentNBMonCount, _owner);
    }

    // randomizes the stats of the minted NBMon. Only used for origins.
    function _randomizeNbmonStats(uint256 _randomNumber) private view returns (uint32[] memory _nbmonStats) {
        _nbmonStats = new uint32[](6);
        
        //randomizing gender
        _nbmonStats[0] = uint32(uint256(keccak256(abi.encode(_randomNumber, 0))) % _totalGenders + 1);
        //randomizing rarity
        _nbmonStats[1] = uint32(uint256(keccak256(abi.encode(_randomNumber, 1))) % _rarityChance);

        //randomizing mutation (mutation chance is _mutationChance for minted NBMons)
        uint32 _randMutationChance = uint32(uint256(keccak256(abi.encode(_randomNumber, 2))) % _mutationChance);
        //if NBMon is mutated
        if (_randMutationChance == 0) {
            // choose one of the possible mutation types
            _nbmonStats[2] = uint32(uint256(keccak256(abi.encode(_randomNumber, 3))) % _mutationTypes + 1);
        } else {
            // else return 0/not mutated
            _nbmonStats[2] = 0;
        }

        //species for this function is always going to be an origin, so 1.
        _nbmonStats[3] = 1;
        //randomizing genus
        _nbmonStats[4] = uint32(uint256(keccak256(abi.encode(_randomNumber, 4))) % _totalGenera + 1);
        //getting fertility points
        _nbmonStats[5] = _maxFertilityPoints;

        return _nbmonStats;
    }

    // randomizes the passives of the NBMon. Taken from ..gamestats/passives.txt.
    function _randomizePassives(uint256 _randomNumber) private view returns (uint16[] memory _passives) {
        _passives = new uint16[](2);
        for (uint16 i = 0; i < 2; i++) {
            _passives[i] = uint16(uint256(keccak256(abi.encode(_randomNumber, i))) % _totalPassives + 1);
        }

        return _passives;
    }

    //syncs the stats of the wild NBMon minted
    function _syncNbmonStatsWild(
        uint256 _randomNumber, 
        uint32 _gender, 
        uint32 _mutationType,
        uint32 _genus
        ) private view returns (uint32[] memory _nbmonStats) {
            _nbmonStats = new uint32[](7);

            //gender is already assigned from the game
            _nbmonStats[0] = _gender;
            //randomizing rarity
            _nbmonStats[1] = uint32(uint256(keccak256(abi.encode(_randomNumber, 1))) % _rarityChance);
            //mutation is already assigned from the game
            _nbmonStats[2] = _mutationType;
            //nbmonType for this function is always going to be a wild, so 2.
            _nbmonStats[3] = 2;
            //genus is already assigned from parameter
            _nbmonStats[4] = _genus;
            //getting fertility
            _nbmonStats[5] = _maxFertilityPoints;

            return _nbmonStats;
    }
}