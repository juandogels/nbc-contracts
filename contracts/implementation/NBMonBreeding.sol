// //SPDX-License-Identifier: MIT

// pragma solidity ^0.8.6;

// import "../security/Strings.sol";
// import "./NBMonCore.sol";

// /**
//  * @dev This contract is used as a basis for the breeding logic for NBMonCore.
//  * This contract does NOT have any of the advanced features yet (e.g. using artifacts to boost certain stats when breeding).
//  * Note: Some of the values/variables here are hard-coded based on current logic from the different .txt files. Should there be any change:
//  * a new breeding contract will replace this since it will NOT affect the main NBMonCore contract. 
//  */
// contract NBMonBreeding is NBMonCore {
//     /// @dev Emitted when breeding is set to 'allowed'. Triggered by _owner. 
//     event BreedingAllowed(address _owner);
//     /// @dev Emitted when breeding is set to 'not allowed'. Triggered by _owner.
//     event BreedingNotAllowed(address _owner);

//     bool public _breedingAllowed;

//     constructor() {
//         // allows breeding during contract deployment.
//         _breedingAllowed = true;
//     }

//     // modifier for functions that require _breedingAllowed to be true to continue.
//     modifier whenBreedingAllowed() {
//         require(_breedingAllowed, "NBMonBreedingExtended: Breeding allowed");
//         _;
//     }

//     // modifier for functions that require _breedingAllowed to be false to continue.
//     modifier whenBreedingNotAllowed() {
//         require(!_breedingAllowed, "NBMonBreeding: Breeding not allowed");
//         _;
//     }

//     // allows breeding when breeding is currently disallowed.
//     function allowBreeding() public whenBreedingNotAllowed onlyAdmin {
//         _breedingAllowed = true;
//         emit BreedingAllowed(_msgSender());
//     }

//     // disallows breeding when breeding is currently allowed.
//     function disallowBreeding() public whenBreedingAllowed onlyAdmin {
//         _breedingAllowed = false;
//         emit BreedingNotAllowed(_msgSender());
//     }

//     /**
//      * @dev breeds 2 NBMons to give birth to an offspring
//      * _maleId NEEDS to be a male and _femaleId needs to be a female for simplicity sake (from current gender logic)
//      * this requirement will be implemented in the frontend
//      */
//     function breedNBMon(uint256 _randomNumber, uint256 _maleId, uint256 _femaleId) public whenBreedingAllowed {
//         NBMon memory _maleParent = nbmons[_maleId - 1];
//         NBMon memory _femaleParent = nbmons[_femaleId - 1];

//         // checks if caller/msg.sender owns both NBMons. Fails and reverts if requirement is not met.
//         require(_maleParent.owner == _msgSender() && _femaleParent.owner == _msgSender(), "NBMonBreeding: Caller does not own both NBMons");

//         // double checking that male parent and female parent have different genders 
//         // most likely not required but is added just in case to save gas fees and revert the transaction here if requirement is not met
//         require(_maleParent.nbmonStats[0] != _femaleParent.nbmonStats[0], "NBMonBreeding: Gender needs to be different");
//         require(_maleParent.nbmonStats[0] == 1, "NBMonBreeding: Male parent is not a male gender");
//         require(_femaleParent.nbmonStats[0] == 2, "NBMonBreeding: Female parent is not a female gender");

//         uint32[] memory _nbmonStats = _offspringStats(_randomNumber, _maleId, _femaleId);

//         //current breeding logic assumes that the genus of the offspring will follow the female parent's genus.
//         //this also means that the types of the offspring will be based on the genus.
//         //getting types from genus (_nbmonStats[4])
//         uint32 _offspringGenus = _nbmonStats[4];
//         //gets types of genus from _type mapping
//         uint8[] memory _offspringTypes = _type[_offspringGenus];

//         //calculating potential of offspring NBMon


//         NBMon memory _offspring = NBMon(
//             currentNBMonCount,
//             _msgSender(),
//             block.timestamp,
//             block.timestamp,
//             _nbmonStats,
//             _offspringTypes,


//         );

//     }

//     /**
//      * @dev Calculates the potential for the offspring based on current breeding potential logic from male and female parent.
//      * Stats consist of: health, energy, attack, defense, special attack, special defense and speed potential
//      * Please check https://www.notion.so/09-01-2022-Changes-8948bd23f5fc4175aec364c0bea95e2e for potential logic
//      * Note: _rarity and genus are obtained from _offspringStats, which is calculated before this function is called.
//      */
//     function _offspringPotential(
//         uint256 _randomNumber, 
//         uint32 _rarity,
//         uint32 _species, 
//         uint256 _maleId, 
//         uint256 _femaleId
//         ) private view returns (uint8[] memory _offspringPotential) {
//             NBMon memory _maleParent = nbmons[_maleId - 1];
//             NBMon memory _femaleParent = nbmons[_femaleId - 1];

//             _offspringPotential = new uint32[](7);

//             /// logic firstly depends on species of offspring (origin, hybrid/wild)
//             // if species = origin
//             if (_species == 1) {
//                 // if rarity is common
//                 if (_rarity <= 649) {
//                     for (uint i = 0; i < 7; i++) {
//                         //randomizes a number between 0 - 999 for logic
//                         uint32 _rand = uint32(uint256(keccak256(abi.encode(_randomNumber, i))) % 1000);
//                         // if both parents have a potential <= 7 for this stat
//                         if (_maleParent.potential[i] <= 7 && _femaleParent.potential[i] <= 7) {
//                             // if _rand is within H2P range, it takes highest of 2 parents 
//                             if (_rand <= 399) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 0 - 20
//                             } else if (_rand <= 649) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             }
//                         // if one parent has a potential between 0 - 7 and other parent has a potential between 8 - 15 for this stat
//                         } else if (
//                             (_maleParent.potential[i] <= 7 && _between(_femaleParent.potential[i], 8, 15)) || 
//                             (_femaleParent.potential[i] <= 7 && _between(_maleParent.potential[i], 8, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 249) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 0 - 20
//                                 } else if (_rand <= 699) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // if both parents have a potential between 8 - 15 for this stat
//                         } else if (_between(_maleParent.potential[i], 8, 15) && _between(_femaleParent.potential[i], 8, 15)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 249) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 0 - 20
//                             } else if (_rand <= 749) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                             _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             }
//                         // If one parent has a potential between 16 - 24 and the other parent has a potential between 0 - 15 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 0, 15)) ||
//                             (_between(_femaleParent.potential[i], 16, 24) && _between(_maleParent.potential[i], 0, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 119) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 0 - 20
//                                 } else if (_rand <= 819) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // If both parents have a potential between 16 - 24 for this stat   
//                         } else if (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 16, 24)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 119) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 0 - 20
//                             } else if (_rand <= 849) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                             _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             }
//                         // If one parent has a potential between 25 - 34 and the other parent has a potential between 0 - 24 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 0, 24)) ||
//                             (_between(_femaleParent.potential[i], 25, 34) && _between(_maleParent.potential[i], 0, 24))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 49) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 0 - 20
//                                 } else if (_rand <= 899) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // If both parents have a potential between 25 - 34 for this stat   
//                         } else if (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 25, 34)) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 49) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 0 - 20
//                                 } else if (_rand <= 919) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // If one parent has a potential between 35 - 45 and the other parent has a potential between 0 - 34 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 0, 34)) ||
//                             (_between(_femaleParent.potential[i], 35, 45) && _between(_maleParent.potential[i], 0, 34))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 19) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 0 - 20
//                                 } else if (_rand <= 939) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // If both parents have a potential between 35 - 45 for this stat
//                         } else if (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 35, 45)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 19) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 0 - 20
//                             } else if (_rand <= 959) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                             _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             }
//                         // If one parent has a potential between 46 - 65 and the other parent has a potential between 0 - 45 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 0, 45)) ||
//                             (_between(_femaleParent.potential[i], 46, 65) && _between(_maleParent.potential[i], 0, 45))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 4) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 0 - 20
//                                 } else if (_rand <= 979) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // If both parents have a potential between 46 - 65 for this stat
//                         } else if (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 46, 65)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 4) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 0 - 20
//                             } else if (_rand <= 989) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                             _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         }
//                     }     
//                 // If rarity is uncommon
//                 } else if (_rarity <= 849) {
//                     //loop through each potential 
//                     for (uint i = 0; i < 7; i++) {
//                         //randomizes a number between 0 - 999 for logic
//                         uint32 _rand = uint32(uint256(keccak256(abi.encode(_randomNumber, i))) % 1000);
//                         // if both parents have a potential between 0 - 7 for this stat
//                         if (_maleParent.potential[i] <= 7 && _femaleParent.potential[i] <= 7) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 299) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 8 - 25
//                             } else if (_rand <= 699) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 18 + 8);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                             _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 0 - 7 and the other parent has a potential between 8 - 15 for this stat
//                         } else if (
//                             (_maleParent.potential[i] <= 7 && _between(_femaleParent.potential[i], 8, 15)) ||
//                             (_femaleParent.potential[i] <= 7 && _between(_maleParent.potential[i], 8, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 324) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 8 - 25
//                                 } else if (_rand <= 624) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 18 + 8);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 8 - 15 for this stat
//                         } else if (_between(_maleParent.potential[i], 8, 15) && _between(_femaleParent.potential[i], 8, 15)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 324) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 8 - 25
//                             } else if (_rand <= 674) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 18 + 8);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 16 - 24 and the other parent has a potential between 0 - 15 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 0, 15)) ||
//                             (_between(_femaleParent.potential[i], 16, 24) && _between(_maleParent.potential[i], 0, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 224) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 8 - 25
//                                 } else if (_rand <= 699) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 18 + 8);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 16 - 24 for this stat
//                         } else if (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 16, 24)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 224) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 8 - 25
//                             } else if (_rand <= 749) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 18 + 8);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 25 - 34 and the other parent has a potential between 0 - 24 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 0, 24)) ||
//                             (_between(_femaleParent.potential[i], 25, 34) && _between(_maleParent.potential[i], 0, 24))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 139) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 8 - 25
//                                 } else if (_rand <= 764) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 18 + 8);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 25 - 34 for this stat
//                         } else if (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 25, 34)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 139) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 8 - 25
//                             } else if (_rand <= 839) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 18 + 8);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 35 - 45 and the other parent has a potential between 0 - 34 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 0, 34)) ||
//                             (_between(_femaleParent.potential[i], 35, 45) && _between(_maleParent.potential[i], 0, 34))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 69) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 8 - 25
//                                 } else if (_rand <= 869) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 18 + 8);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // if both parents have a potential between 35 - 45 for this stat
//                         } else if (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 35, 45)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 69) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 8 - 25
//                             } else if (_rand <= 919) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 18 + 8);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             }  
//                         // if one parent has a potential between 46 - 65 and the other parent has a potential between 0 - 45 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 0, 45)) ||
//                             (_between(_femaleParent.potential[i], 46, 65) && _between(_maleParent.potential[i], 0, 45))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 34) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 8 - 25
//                                 } else if (_rand <= 934) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 18 + 8);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }  
//                         // if both parents have a potential between 46 - 65 for this stat
//                         } else if (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 46, 65)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 34) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 8 - 25
//                             } else if (_rand <= 964) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 18 + 8);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         }
//                     }
//                 // if rarity is rare
//                 } else if (_rarity <= 949) {
//                     //loop through each potential 
//                     for (uint i = 0; i < 7; i++) {
//                         //randomizes a number between 0 - 999 for logic
//                         uint32 _rand = uint32(uint256(keccak256(abi.encode(_randomNumber, i))) % 1000);
//                         // if both parents have a potential between 0 - 7 for this stat
//                         if (_maleParent.potential[i] <= 7 && _femaleParent.potential[i] <= 7) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 249) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 16 - 35
//                             } else if (_rand <= 799) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 16);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                             _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 0 - 7 and the other parent has a potential between 8 - 15 for this stat
//                         } else if (
//                             (_maleParent.potential[i] <= 7 && _between(_femaleParent.potential[i], 8, 15)) ||
//                             (_femaleParent.potential[i] <= 7 && _between(_maleParent.potential[i], 8, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 299) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 16 - 35
//                                 } else if (_rand <= 649) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 16);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 8 - 15 for this stat
//                         } else if (_between(_maleParent.potential[i], 8, 15) && _between(_femaleParent.potential[i], 8, 15)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 324) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 16 - 35
//                             } else if (_rand <= 699) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 16);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 16 - 24 and the other parent has a potential between 0 - 15 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 0, 15)) ||
//                             (_between(_femaleParent.potential[i], 16, 24) && _between(_maleParent.potential[i], 0, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 349) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 16 - 35
//                                 } else if (_rand <= 599) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 16);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 16 - 24 for this stat
//                         } else if (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 16, 24)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 349) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 16 - 35
//                             } else if (_rand <= 574) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 16);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 25 - 34 and the other parent has a potential between 0 - 24 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 0, 24)) ||
//                             (_between(_femaleParent.potential[i], 25, 34) && _between(_maleParent.potential[i], 0, 24))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 249) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 16 - 35
//                                 } else if (_rand <= 649) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 16);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 25 - 34 for this stat
//                         } else if (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 25, 34)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 249) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 16 - 35
//                             } else if (_rand <= 749) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 16);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 35 - 45 and the other parent has a potential between 0 - 34 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 0, 34)) ||
//                             (_between(_femaleParent.potential[i], 35, 45) && _between(_maleParent.potential[i], 0, 34))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 149) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 16 - 35
//                                 } else if (_rand <= 774) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 16);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // if both parents have a potential between 35 - 45 for this stat
//                         } else if (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 35, 45)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 149) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 16 - 35
//                             } else if (_rand <= 849) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 16);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             }  
//                         // if one parent has a potential between 46 - 65 and the other parent has a potential between 0 - 45 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 0, 45)) ||
//                             (_between(_femaleParent.potential[i], 46, 65) && _between(_maleParent.potential[i], 0, 45))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 74) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 16 - 35
//                                 } else if (_rand <= 859) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 16);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }  
//                         // if both parents have a potential between 46 - 65 for this stat
//                         } else if (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 46, 65)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 74) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 16 - 35
//                             } else if (_rand <= 899) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 16);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         }
//                     }
//                 // if rarity is epic
//                 } else if (_rarity <= 989) {
//                     //loop through each potential 
//                     for (uint i = 0; i < 7; i++) {
//                         //randomizes a number between 0 - 999 for logic
//                         uint32 _rand = uint32(uint256(keccak256(abi.encode(_randomNumber, i))) % 1000);
//                         // if both parents have a potential between 0 - 7 for this stat
//                         if (_maleParent.potential[i] <= 7 && _femaleParent.potential[i] <= 7) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 124) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 25 - 45
//                             } else if (_rand <= 874) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 25);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                             _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 0 - 7 and the other parent has a potential between 8 - 15 for this stat
//                         } else if (
//                             (_maleParent.potential[i] <= 7 && _between(_femaleParent.potential[i], 8, 15)) ||
//                             (_femaleParent.potential[i] <= 7 && _between(_maleParent.potential[i], 8, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 174) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 25 - 45
//                                 } else if (_rand <= 799) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 25);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 8 - 15 for this stat
//                         } else if (_between(_maleParent.potential[i], 8, 15) && _between(_femaleParent.potential[i], 8, 15)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 174) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 25 - 45
//                             } else if (_rand <= 774) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 25);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 16 - 24 and the other parent has a potential between 0 - 15 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 0, 15)) ||
//                             (_between(_femaleParent.potential[i], 16, 24) && _between(_maleParent.potential[i], 0, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 249) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 25 - 45
//                                 } else if (_rand <= 749) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 25);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 16 - 24 for this stat
//                         } else if (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 16, 24)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 249) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 25 - 45
//                             } else if (_rand <= 724) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 25);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 25 - 34 and the other parent has a potential between 0 - 24 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 0, 24)) ||
//                             (_between(_femaleParent.potential[i], 25, 34) && _between(_maleParent.potential[i], 0, 24))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 289) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 25 - 45
//                                 } else if (_rand <= 689) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 25);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 25 - 34 for this stat
//                         } else if (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 25, 34)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 289) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 25 - 45
//                             } else if (_rand <= 709) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 25);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 35 - 45 and the other parent has a potential between 0 - 34 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 0, 34)) ||
//                             (_between(_femaleParent.potential[i], 35, 45) && _between(_maleParent.potential[i], 0, 34))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 249) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 25 - 45
//                                 } else if (_rand <= 719) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 25);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // if both parents have a potential between 35 - 45 for this stat
//                         } else if (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 35, 45)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 249) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 25 - 45
//                             } else if (_rand <= 749) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 25);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             }  
//                         // if one parent has a potential between 46 - 65 and the other parent has a potential between 0 - 45 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 0, 45)) ||
//                             (_between(_femaleParent.potential[i], 46, 65) && _between(_maleParent.potential[i], 0, 45))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 124) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 25 - 45
//                                 } else if (_rand <= 849) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 25);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }  
//                         // if both parents have a potential between 46 - 65 for this stat
//                         } else if (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 46, 65)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 124) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 25 - 45
//                             } else if (_rand <= 874) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 25);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         }
//                     }
//                 // if rarity is legendary
//                 } else if (_rarity <= 998) {
//                     //loop through each potential 
//                     for (uint i = 0; i < 7; i++) {
//                         //randomizes a number between 0 - 999 for logic
//                         uint32 _rand = uint32(uint256(keccak256(abi.encode(_randomNumber, i))) % 1000);
//                         // if both parents have a potential between 0 - 7 for this stat
//                         if (_maleParent.potential[i] <= 7 && _femaleParent.potential[i] <= 7) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 49) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 35 - 55
//                             } else if (_rand <= 899) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 35);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                             _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 0 - 7 and the other parent has a potential between 8 - 15 for this stat
//                         } else if (
//                             (_maleParent.potential[i] <= 7 && _between(_femaleParent.potential[i], 8, 15)) ||
//                             (_femaleParent.potential[i] <= 7 && _between(_maleParent.potential[i], 8, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 79) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 35 - 55
//                                 } else if (_rand <= 879) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 35);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 8 - 15 for this stat
//                         } else if (_between(_maleParent.potential[i], 8, 15) && _between(_femaleParent.potential[i], 8, 15)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 79) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 35 - 55
//                             } else if (_rand <= 849) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 35);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 16 - 24 and the other parent has a potential between 0 - 15 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 0, 15)) ||
//                             (_between(_femaleParent.potential[i], 16, 24) && _between(_maleParent.potential[i], 0, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 124) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 35 - 55
//                                 } else if (_rand <= 849) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 35);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 16 - 24 for this stat
//                         } else if (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 16, 24)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 124) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 35 - 55
//                             } else if (_rand <= 799) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 35);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 25 - 34 and the other parent has a potential between 0 - 24 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 0, 24)) ||
//                             (_between(_femaleParent.potential[i], 25, 34) && _between(_maleParent.potential[i], 0, 24))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 179) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 35 - 55
//                                 } else if (_rand <= 799) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 35);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 25 - 34 for this stat
//                         } else if (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 25, 34)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 179) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 35 - 55
//                             } else if (_rand <= 749) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 35);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 35 - 45 and the other parent has a potential between 0 - 34 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 0, 34)) ||
//                             (_between(_femaleParent.potential[i], 35, 45) && _between(_maleParent.potential[i], 0, 34))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 249) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 35 - 55
//                                 } else if (_rand <= 749) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 35);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // if both parents have a potential between 35 - 45 for this stat
//                         } else if (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 35, 45)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 249) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 35 - 55
//                             } else if (_rand <= 709) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 35);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             }  
//                         // if one parent has a potential between 46 - 65 and the other parent has a potential between 0 - 45 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 0, 45)) ||
//                             (_between(_femaleParent.potential[i], 46, 65) && _between(_maleParent.potential[i], 0, 45))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 179) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 35 - 55
//                                 } else if (_rand <= 779) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 35);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }  
//                         // if both parents have a potential between 46 - 65 for this stat
//                         } else if (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 46, 65)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 179) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 35 - 55
//                             } else if (_rand <= 819) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 21 + 35);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         }
//                     }
//                 // if rarity is mythical
//                 } else if (_rarity == 999) {
//                     //loop through each potential 
//                     for (uint i = 0; i < 7; i++) {
//                         //randomizes a number between 0 - 999 for logic
//                         uint32 _rand = uint32(uint256(keccak256(abi.encode(_randomNumber, i))) % 1000);
//                         // if both parents have a potential between 0 - 7 for this stat
//                         if (_maleParent.potential[i] <= 7 && _femaleParent.potential[i] <= 7) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 24) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 46 - 65
//                             } else if (_rand <= 949) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 46);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                             _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 0 - 7 and the other parent has a potential between 8 - 15 for this stat
//                         } else if (
//                             (_maleParent.potential[i] <= 7 && _between(_femaleParent.potential[i], 8, 15)) ||
//                             (_femaleParent.potential[i] <= 7 && _between(_maleParent.potential[i], 8, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 49) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 46 - 65
//                                 } else if (_rand <= 924) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 46);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 8 - 15 for this stat
//                         } else if (_between(_maleParent.potential[i], 8, 15) && _between(_femaleParent.potential[i], 8, 15)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 49) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 46 - 65
//                             } else if (_rand <= 909) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 46);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 16 - 24 and the other parent has a potential between 0 - 15 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 0, 15)) ||
//                             (_between(_femaleParent.potential[i], 16, 24) && _between(_maleParent.potential[i], 0, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 89) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 46 - 65
//                                 } else if (_rand <= 889) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 46);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 16 - 24 for this stat
//                         } else if (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 16, 24)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 89) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 46 - 65
//                             } else if (_rand <= 864) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 46);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 25 - 34 and the other parent has a potential between 0 - 24 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 0, 24)) ||
//                             (_between(_femaleParent.potential[i], 25, 34) && _between(_maleParent.potential[i], 0, 24))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 129) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 46 - 65
//                                 } else if (_rand <= 849) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 46);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 25 - 34 for this stat
//                         } else if (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 25, 34)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 129) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 46 - 65
//                             } else if (_rand <= 819) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 46);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 35 - 45 and the other parent has a potential between 0 - 34 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 0, 34)) ||
//                             (_between(_femaleParent.potential[i], 35, 45) && _between(_maleParent.potential[i], 0, 34))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 179) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 46 - 65
//                                 } else if (_rand <= 799) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 46);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // if both parents have a potential between 35 - 45 for this stat
//                         } else if (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 35, 45)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 179) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 46 - 65
//                             } else if (_rand <= 774) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 46);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             }  
//                         // if one parent has a potential between 46 - 65 and the other parent has a potential between 0 - 45 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 0, 45)) ||
//                             (_between(_femaleParent.potential[i], 46, 65) && _between(_maleParent.potential[i], 0, 45))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 249) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 46 - 65
//                                 } else if (_rand <= 714) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 46);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }  
//                         // if both parents have a potential between 46 - 65 for this stat
//                         } else if (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 46, 65)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 249) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 46 - 65
//                             } else if (_rand <= 749) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 20 + 46);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         }
//                     }
//                 }
//             // if species is hybrid or wild
//             } else if (_species == 2 || _species == 3) {
//                 // if rarity is common
//                 if (_rarity <= 649) {
//                     for (uint i = 0; i < 7; i++) {
//                         //randomizes a number between 0 - 999 for logic
//                         uint32 _rand = uint32(uint256(keccak256(abi.encode(_randomNumber, i))) % 1000);
//                         // if both parents have a potential <= 7 for this stat
//                         if (_maleParent.potential[i] <= 7 && _femaleParent.potential[i] <= 7) {
//                             // if _rand is within H2P range, it takes highest of 2 parents 
//                             if (_rand <= 399) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 0 - 15
//                             } else if (_rand <= 649) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             }
//                         // if one parent has a potential between 0 - 7 and other parent has a potential between 8 - 15 for this stat
//                         } else if (
//                             (_maleParent.potential[i] <= 7 && _between(_femaleParent.potential[i], 8, 15)) || 
//                             (_femaleParent.potential[i] <= 7 && _between(_maleParent.potential[i], 8, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 249) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 0 - 15
//                                 } else if (_rand <= 699) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // if both parents have a potential between 8 - 15 for this stat
//                         } else if (_between(_maleParent.potential[i], 8, 15) && _between(_femaleParent.potential[i], 8, 15)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 249) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 0 - 15
//                             } else if (_rand <= 749) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                             _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             }
//                         // If one parent has a potential between 16 - 24 and the other parent has a potential between 0 - 15 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 0, 15)) ||
//                             (_between(_femaleParent.potential[i], 16, 24) && _between(_maleParent.potential[i], 0, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 119) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 0 - 20
//                                 } else if (_rand <= 819) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // If both parents have a potential between 16 - 24 for this stat   
//                         } else if (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 16, 24)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 119) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 0 - 15
//                             } else if (_rand <= 849) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                             _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             }
//                         // If one parent has a potential between 25 - 34 and the other parent has a potential between 0 - 24 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 0, 24)) ||
//                             (_between(_femaleParent.potential[i], 25, 34) && _between(_maleParent.potential[i], 0, 24))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 49) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 0 - 15
//                                 } else if (_rand <= 899) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // If both parents have a potential between 25 - 34 for this stat   
//                         } else if (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 25, 34)) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 49) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 0 - 15
//                                 } else if (_rand <= 919) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // If one parent has a potential between 35 - 45 and the other parent has a potential between 0 - 34 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 0, 34)) ||
//                             (_between(_femaleParent.potential[i], 35, 45) && _between(_maleParent.potential[i], 0, 34))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 19) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 0 - 15
//                                 } else if (_rand <= 939) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // If both parents have a potential between 35 - 45 for this stat
//                         } else if (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 35, 45)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 19) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 0 - 15
//                             } else if (_rand <= 959) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                             _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             }
//                         // If one parent has a potential between 46 - 65 and the other parent has a potential between 0 - 45 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 0, 45)) ||
//                             (_between(_femaleParent.potential[i], 46, 65) && _between(_maleParent.potential[i], 0, 45))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 4) {
//                                     // checks if male parent has a potential of 50 - 65 (in which case is already above max)
//                                     if (_between(_maleParent.potential[i], 50, 65) || _between(_femaleParent.potential[i], 50, 65)) {
//                                         // maxed out potential for hybrid/wild
//                                         _offspringPotential[i] = 50;
//                                     } else {
//                                         _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                     }
//                                 // if _rand is within R range, it randomizes between 0 - 20
//                                 } else if (_rand <= 979) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     uint8 _averagePotential = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                     if (_averagePotential >= 50) {
//                                         _offspringPotential[i] = 50;
//                                     } else {
//                                         _offspringPotential[i] = _averagePotential;
//                                     }
//                                 }
//                         // If both parents have a potential between 46 - 65 for this stat
//                         } else if (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 46, 65)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 4) {
//                                     // checks if male parent has a potential of 50 - 65 (in which case is already above max)
//                                     if (_between(_maleParent.potential[i], 50, 65) || _between(_femaleParent.potential[i], 50, 65)) {
//                                         // maxed out potential for hybrid/wild
//                                         _offspringPotential[i] = 50;
//                                     } else {
//                                         _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                     }
//                                 // if _rand is within R range, it randomizes between 0 - 15
//                                 } else if (_rand <= 989) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     uint8 _averagePotential = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                     if (_averagePotential >= 50) {
//                                         _offspringPotential[i] = 50;
//                                     } else {
//                                         _offspringPotential[i] = _averagePotential;
//                                     }
//                                 }
//                         }
//                     }     
//                 // If rarity is uncommon
//                 } else if (_rarity <= 849) {
//                     //loop through each potential 
//                     for (uint i = 0; i < 7; i++) {
//                         //randomizes a number between 0 - 999 for logic
//                         uint32 _rand = uint32(uint256(keccak256(abi.encode(_randomNumber, i))) % 1000);
//                         // if both parents have a potential between 0 - 7 for this stat
//                         if (_maleParent.potential[i] <= 7 && _femaleParent.potential[i] <= 7) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 299) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 5 - 20
//                             } else if (_rand <= 699) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 5);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                             _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 0 - 7 and the other parent has a potential between 8 - 15 for this stat
//                         } else if (
//                             (_maleParent.potential[i] <= 7 && _between(_femaleParent.potential[i], 8, 15)) ||
//                             (_femaleParent.potential[i] <= 7 && _between(_maleParent.potential[i], 8, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 324) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 5 - 20
//                                 } else if (_rand <= 624) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 5;
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 8 - 15 for this stat
//                         } else if (_between(_maleParent.potential[i], 8, 15) && _between(_femaleParent.potential[i], 8, 15)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 324) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 5 - 20
//                             } else if (_rand <= 674) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 5);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 16 - 24 and the other parent has a potential between 0 - 15 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 0, 15)) ||
//                             (_between(_femaleParent.potential[i], 16, 24) && _between(_maleParent.potential[i], 0, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 224) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 5 - 20
//                                 } else if (_rand <= 699) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 5);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 16 - 24 for this stat
//                         } else if (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 16, 24)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 224) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 5 - 20
//                             } else if (_rand <= 749) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 5);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 25 - 34 and the other parent has a potential between 0 - 24 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 0, 24)) ||
//                             (_between(_femaleParent.potential[i], 25, 34) && _between(_maleParent.potential[i], 0, 24))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 139) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 5 - 20
//                                 } else if (_rand <= 764) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 5);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 25 - 34 for this stat
//                         } else if (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 25, 34)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 139) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 5 - 20
//                             } else if (_rand <= 839) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 5);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 35 - 45 and the other parent has a potential between 0 - 34 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 0, 34)) ||
//                             (_between(_femaleParent.potential[i], 35, 45) && _between(_maleParent.potential[i], 0, 34))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 69) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 5 - 20
//                                 } else if (_rand <= 869) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 5);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // if both parents have a potential between 35 - 45 for this stat
//                         } else if (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 35, 45)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 69) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 5 - 20
//                             } else if (_rand <= 919) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 5);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             }  
//                         // if one parent has a potential between 46 - 65 and the other parent has a potential between 0 - 45 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 0, 45)) ||
//                             (_between(_femaleParent.potential[i], 46, 65) && _between(_maleParent.potential[i], 0, 45))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 34) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 5 - 20
//                                 } else if (_rand <= 934) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 5);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }  
//                         // if both parents have a potential between 46 - 65 for this stat
//                         } else if (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 46, 65)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 34) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 5 - 20
//                             } else if (_rand <= 964) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 5);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         }
//                     }
//                 // if rarity is rare
//                 } else if (_rarity <= 949) {
//                     //loop through each potential 
//                     for (uint i = 0; i < 7; i++) {
//                         //randomizes a number between 0 - 999 for logic
//                         uint32 _rand = uint32(uint256(keccak256(abi.encode(_randomNumber, i))) % 1000);
//                         // if both parents have a potential between 0 - 7 for this stat
//                         if (_maleParent.potential[i] <= 7 && _femaleParent.potential[i] <= 7) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 249) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 11 - 25
//                             } else if (_rand <= 799) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 11);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                             _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 0 - 7 and the other parent has a potential between 8 - 15 for this stat
//                         } else if (
//                             (_maleParent.potential[i] <= 7 && _between(_femaleParent.potential[i], 8, 15)) ||
//                             (_femaleParent.potential[i] <= 7 && _between(_maleParent.potential[i], 8, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 299) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 11 - 25
//                                 } else if (_rand <= 649) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 11);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 8 - 15 for this stat
//                         } else if (_between(_maleParent.potential[i], 8, 15) && _between(_femaleParent.potential[i], 8, 15)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 324) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 11 - 25
//                             } else if (_rand <= 699) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 11);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 16 - 24 and the other parent has a potential between 0 - 15 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 0, 15)) ||
//                             (_between(_femaleParent.potential[i], 16, 24) && _between(_maleParent.potential[i], 0, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 349) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 11 - 25
//                                 } else if (_rand <= 599) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 11);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 16 - 24 for this stat
//                         } else if (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 16, 24)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 349) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 11 - 25
//                             } else if (_rand <= 574) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 11);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 25 - 34 and the other parent has a potential between 0 - 24 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 0, 24)) ||
//                             (_between(_femaleParent.potential[i], 25, 34) && _between(_maleParent.potential[i], 0, 24))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 249) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 11 - 25
//                                 } else if (_rand <= 649) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 11);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 25 - 34 for this stat
//                         } else if (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 25, 34)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 249) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 11 - 25
//                             } else if (_rand <= 749) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 11);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 35 - 45 and the other parent has a potential between 0 - 34 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 0, 34)) ||
//                             (_between(_femaleParent.potential[i], 35, 45) && _between(_maleParent.potential[i], 0, 34))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 149) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 11 - 25
//                                 } else if (_rand <= 774) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 11);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // if both parents have a potential between 35 - 45 for this stat
//                         } else if (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 35, 45)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 149) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 11 - 25
//                             } else if (_rand <= 849) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 11);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             }  
//                         // if one parent has a potential between 46 - 65 and the other parent has a potential between 0 - 45 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 0, 45)) ||
//                             (_between(_femaleParent.potential[i], 46, 65) && _between(_maleParent.potential[i], 0, 45))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 74) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 11 - 25
//                                 } else if (_rand <= 859) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 11);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }  
//                         // if both parents have a potential between 46 - 65 for this stat
//                         } else if (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 46, 65)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 74) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 11 - 25
//                             } else if (_rand <= 899) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 11);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         }
//                     }
//                 // if rarity is epic
//                 } else if (_rarity <= 989) {
//                     //loop through each potential 
//                     for (uint i = 0; i < 7; i++) {
//                         //randomizes a number between 0 - 999 for logic
//                         uint32 _rand = uint32(uint256(keccak256(abi.encode(_randomNumber, i))) % 1000);
//                         // if both parents have a potential between 0 - 7 for this stat
//                         if (_maleParent.potential[i] <= 7 && _femaleParent.potential[i] <= 7) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 124) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 18 - 30
//                             } else if (_rand <= 874) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 13 + 18);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                             _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 0 - 7 and the other parent has a potential between 8 - 15 for this stat
//                         } else if (
//                             (_maleParent.potential[i] <= 7 && _between(_femaleParent.potential[i], 8, 15)) ||
//                             (_femaleParent.potential[i] <= 7 && _between(_maleParent.potential[i], 8, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 174) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 18 - 30
//                                 } else if (_rand <= 799) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 13 + 18);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 8 - 15 for this stat
//                         } else if (_between(_maleParent.potential[i], 8, 15) && _between(_femaleParent.potential[i], 8, 15)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 174) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 18 - 30
//                             } else if (_rand <= 774) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 13 + 18);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 16 - 24 and the other parent has a potential between 0 - 15 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 0, 15)) ||
//                             (_between(_femaleParent.potential[i], 16, 24) && _between(_maleParent.potential[i], 0, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 249) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 18 - 30
//                                 } else if (_rand <= 749) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 13 + 18);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 16 - 24 for this stat
//                         } else if (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 16, 24)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 249) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 18 - 30
//                             } else if (_rand <= 724) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 13 + 18);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 25 - 34 and the other parent has a potential between 0 - 24 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 0, 24)) ||
//                             (_between(_femaleParent.potential[i], 25, 34) && _between(_maleParent.potential[i], 0, 24))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 289) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 18 - 30
//                                 } else if (_rand <= 689) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 13 + 18);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 25 - 34 for this stat
//                         } else if (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 25, 34)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 289) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 18 - 30
//                             } else if (_rand <= 709) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 13 + 18);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 35 - 45 and the other parent has a potential between 0 - 34 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 0, 34)) ||
//                             (_between(_femaleParent.potential[i], 35, 45) && _between(_maleParent.potential[i], 0, 34))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 249) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 18 - 30
//                                 } else if (_rand <= 719) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 13 + 18);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // if both parents have a potential between 35 - 45 for this stat
//                         } else if (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 35, 45)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 249) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 18 - 30
//                             } else if (_rand <= 749) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 13 + 18);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             }  
//                         // if one parent has a potential between 46 - 65 and the other parent has a potential between 0 - 45 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 0, 45)) ||
//                             (_between(_femaleParent.potential[i], 46, 65) && _between(_maleParent.potential[i], 0, 45))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 124) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 18 - 30
//                                 } else if (_rand <= 849) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 13 + 18);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }  
//                         // if both parents have a potential between 46 - 65 for this stat
//                         } else if (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 46, 65)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 124) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 18 - 30
//                             } else if (_rand <= 874) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 13 + 18);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         }
//                     }
//                 // if rarity is legendary
//                 } else if (_rarity <= 998) {
//                     //loop through each potential 
//                     for (uint i = 0; i < 7; i++) {
//                         //randomizes a number between 0 - 999 for logic
//                         uint32 _rand = uint32(uint256(keccak256(abi.encode(_randomNumber, i))) % 1000);
//                         // if both parents have a potential between 0 - 7 for this stat
//                         if (_maleParent.potential[i] <= 7 && _femaleParent.potential[i] <= 7) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 49) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 26 - 40
//                             } else if (_rand <= 899) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 26);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                             _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 0 - 7 and the other parent has a potential between 8 - 15 for this stat
//                         } else if (
//                             (_maleParent.potential[i] <= 7 && _between(_femaleParent.potential[i], 8, 15)) ||
//                             (_femaleParent.potential[i] <= 7 && _between(_maleParent.potential[i], 8, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 79) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 26 - 40
//                                 } else if (_rand <= 879) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 26);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 8 - 15 for this stat
//                         } else if (_between(_maleParent.potential[i], 8, 15) && _between(_femaleParent.potential[i], 8, 15)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 79) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 26 - 40
//                             } else if (_rand <= 849) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 26);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 16 - 24 and the other parent has a potential between 0 - 15 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 0, 15)) ||
//                             (_between(_femaleParent.potential[i], 16, 24) && _between(_maleParent.potential[i], 0, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 124) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 26 - 40
//                                 } else if (_rand <= 849) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 26);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 16 - 24 for this stat
//                         } else if (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 16, 24)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 124) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 26 - 40
//                             } else if (_rand <= 799) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 26);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 25 - 34 and the other parent has a potential between 0 - 24 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 0, 24)) ||
//                             (_between(_femaleParent.potential[i], 25, 34) && _between(_maleParent.potential[i], 0, 24))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 179) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 26 - 40
//                                 } else if (_rand <= 799) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 26);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 25 - 34 for this stat
//                         } else if (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 25, 34)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 179) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 26 - 40
//                             } else if (_rand <= 749) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 26);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 35 - 45 and the other parent has a potential between 0 - 34 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 0, 34)) ||
//                             (_between(_femaleParent.potential[i], 35, 45) && _between(_maleParent.potential[i], 0, 34))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 249) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 26 - 40
//                                 } else if (_rand <= 749) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 26);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // if both parents have a potential between 35 - 45 for this stat
//                         } else if (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 35, 45)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 249) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 26 - 40
//                             } else if (_rand <= 709) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 26);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             }  
//                         // if one parent has a potential between 46 - 65 and the other parent has a potential between 0 - 45 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 0, 45)) ||
//                             (_between(_femaleParent.potential[i], 46, 65) && _between(_maleParent.potential[i], 0, 45))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 179) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 26 - 40
//                                 } else if (_rand <= 779) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 26);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }  
//                         // if both parents have a potential between 46 - 65 for this stat
//                         } else if (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 46, 65)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 179) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 26 - 40
//                             } else if (_rand <= 819) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 15 + 26);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         }
//                     }
//                 // if rarity is mythical
//                 } else if (_rarity == 999) {
//                     //loop through each potential 
//                     for (uint i = 0; i < 7; i++) {
//                         //randomizes a number between 0 - 999 for logic
//                         uint32 _rand = uint32(uint256(keccak256(abi.encode(_randomNumber, i))) % 1000);
//                         // if both parents have a potential between 0 - 7 for this stat
//                         if (_maleParent.potential[i] <= 7 && _femaleParent.potential[i] <= 7) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 24) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 35 - 50
//                             } else if (_rand <= 949) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 35);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                             _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 0 - 7 and the other parent has a potential between 8 - 15 for this stat
//                         } else if (
//                             (_maleParent.potential[i] <= 7 && _between(_femaleParent.potential[i], 8, 15)) ||
//                             (_femaleParent.potential[i] <= 7 && _between(_maleParent.potential[i], 8, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 49) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 35 - 50
//                                 } else if (_rand <= 924) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 35);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 8 - 15 for this stat
//                         } else if (_between(_maleParent.potential[i], 8, 15) && _between(_femaleParent.potential[i], 8, 15)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 49) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 35 - 50
//                             } else if (_rand <= 909) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 35);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 16 - 24 and the other parent has a potential between 0 - 15 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 0, 15)) ||
//                             (_between(_femaleParent.potential[i], 16, 24) && _between(_maleParent.potential[i], 0, 15))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 89) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 35 - 50
//                                 } else if (_rand <= 889) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 35);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 16 - 24 for this stat
//                         } else if (_between(_maleParent.potential[i], 16, 24) && _between(_femaleParent.potential[i], 16, 24)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 89) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 35 - 50
//                             } else if (_rand <= 864) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 35);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 25 - 34 and the other parent has a potential between 0 - 24 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 0, 24)) ||
//                             (_between(_femaleParent.potential[i], 25, 34) && _between(_maleParent.potential[i], 0, 24))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 129) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 35 - 50
//                                 } else if (_rand <= 849) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 35);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 } 
//                         // if both parents have a potential between 25 - 34 for this stat
//                         } else if (_between(_maleParent.potential[i], 25, 34) && _between(_femaleParent.potential[i], 25, 34)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 129) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 35 - 50
//                             } else if (_rand <= 819) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 35);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         // if one parent has a potential between 35 - 45 and the other parent has a potential between 0 - 34 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 0, 34)) ||
//                             (_between(_femaleParent.potential[i], 35, 45) && _between(_maleParent.potential[i], 0, 34))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 179) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 35 - 50
//                                 } else if (_rand <= 799) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 35);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }
//                         // if both parents have a potential between 35 - 45 for this stat
//                         } else if (_between(_maleParent.potential[i], 35, 45) && _between(_femaleParent.potential[i], 35, 45)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 179) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 35 - 50
//                             } else if (_rand <= 774) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 35);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             }  
//                         // if one parent has a potential between 46 - 65 and the other parent has a potential between 0 - 45 for this stat
//                         } else if (
//                             (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 0, 45)) ||
//                             (_between(_femaleParent.potential[i], 46, 65) && _between(_maleParent.potential[i], 0, 45))
//                             ) {
//                                 // if _rand is within H2P range, it takes highest of 2 parents
//                                 if (_rand <= 249) {
//                                     _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                                 // if _rand is within R range, it randomizes between 35 - 50
//                                 } else if (_rand <= 714) {
//                                     _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 35);
//                                 // if _rand is within A2P range, it takes average of two parents
//                                 } else if (_rand <= 999) {
//                                     _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                                 }  
//                         // if both parents have a potential between 46 - 65 for this stat
//                         } else if (_between(_maleParent.potential[i], 46, 65) && _between(_femaleParent.potential[i], 46, 65)) {
//                             // if _rand is within H2P range, it takes highest of 2 parents
//                             if (_rand <= 249) {
//                                 _offspringPotential[i] = _maleParent.potential[i] > _femaleParent.potential[i] ? _maleParent.potential[i] : _femaleParent.potential[i];
//                             // if _rand is within R range, it randomizes between 35 - 50
//                             } else if (_rand <= 749) {
//                                 _offspringPotential[i] = uint8(uint256(keccak256(abi.encode(_randomNumber, _rand))) % 16 + 35);
//                             // if _rand is within A2P range, it takes average of two parents
//                             } else if (_rand <= 999) {
//                                 _offspringPotential[i] = (_maleParent.potential[i] + _femaleParent.potential[i]) / 2;
//                             } 
//                         }
//                     }
//                 }
//             }    
//     }

//     /**
//      * @dev Used to shorten range logic for calculations
//      */
//     function _between(uint8 _x, uint8 _min, uint8 _max) private pure returns (bool) {
//         return _x >= _min && x <= _max;
//     }

//     /**
//      * @dev Calculates the stats for the offspring based on current breeding logic from male and female parent.
//      * Stats consist of: gender, rarity, mutation, species, baseEvolveDuration, genera, baseFertilityChance.
//      *
//      * Gender is randomized, rarity is randomized, mutation is randomized, species depends on both parents, genus depends on female
//      * fertilityPoints depends on lowest of both parents.
//      *
//      */
//     function _offspringStats(uint256 _randomNumber, uint256 _maleId, uint256 _femaleId) private view returns (uint32[] memory _nbmonStats) {
//         NBMon memory _maleParent = nbmons[_maleId - 1];
//         NBMon memory _femaleParent = nbmons[_femaleId - 1];
        
//         _nbmonStats = new uint32[](6);

//         // randomizing gender
//         _nbmonStats[0] = uint32(uint256(keccak256(abi.encode(_randomNumber, 0))) % _genders + 1);
//         // randomizing rarity
//         _nbmonStats[1]= uint32(uint256(keccak256(abi.encode(_randomNumber, 1))) % _rarityChance);

//         // randomizing mutation 
//         // Note: _mutationChance if none of the parents are mutated is 1/1000.
//         // If one parent is mutated = 1/100, if both parents are mutated = 1/10.
//         uint32 _maleParentMutation = _maleParent.nbmonStats[2];
//         uint32 _femaleParentMutation = _maleParent.nbmonStats[2];

//         // if none of the parents are mutated
//         if (_maleParentMutation == 0 && _femaleParentMutation == 0) {
//             // mutation chance is 1/1000
//             uint32 _randMutationChance = uint32(uint256(keccak256(abi.encode(_randomNumber, 2))) % _mutationChance);
//             // if mutated
//             if (_randMutationChance == 0) {
//                 // choose one of the possible mutation types
//                 _nbmonStats[2] = uint32(uint256(keccak256(abi.encode(_randomNumber, 3))) % _mutationTypes + 1);
//             } else {
//                 // else return 0/not mutated
//                 _nbmonStats[2] = 0;
//             }
//         // if one of the parents are mutated
//         } else if ((_maleParentMutation == 1 && _femaleParentMutation == 0) || (_maleParentMutation == 0 && _femaleParentMutation == 1)) {
//             // mutation chance is 1/100
//             uint32 _randMutationChance = uint32(uint256(keccak256(abi.encode(_randomNumber, 2))) % _oneParentMutationChance);
//             // if mutated
//             if (_randMutationChance == 0) {
//                 // choose one of the possible mutation types
//                 _nbmonStats[2] = uint32(uint256(keccak256(abi.encode(_randomNumber, 3))) % _mutationTypes + 1);
//             } else {
//                 // else return 0/not mutated
//                 _nbmonStats[2] = 0;
//             }
//         // if both parents are mutated
//         } else if (_maleParentMutation == 1 && _femaleParentMutation == 1) {
//             // mutation chance is 1/10
//             uint32 _randMutationChance = uint32(uint256(keccak256(abi.encode(_randomNumber, 2))) % _twoParentsMutationChance);
//             // if mutated
//             if (_randMutationChance == 0) {
//                 // choose one of the possible mutation types
//                 _nbmonStats[2] = uint32(uint256(keccak256(abi.encode(_randomNumber, 3))) % _mutationTypes + 1);
//             } else {
//                 // else return 0/not mutated
//                 _nbmonStats[2] = 0;
//             }
//         }

//         // calculates species
//         _nbmonStats[3] = _calculateOffspringSpecies(_maleId, _femaleId);

//         // calculating genus
//         // takes genus from female parent
//         uint32 _femaleParentGenus = _femaleParent.nbmonStats[4];
//         _nbmonStats[4] = _femaleParentGenus;

//         // calculating fertility
//         _nbmonStats[5] = _calculateOffspringFertility(_maleId, _femaleId);

//         return _nbmonStats;
//     }

//     /**
//      * @dev Calculates the species for _offspringStats (based of current type logic from '../gamestats/species.txt')
//      */
//     function _calculateOffspringSpecies(uint256 _maleId, uint256 _femaleId) private view returns (uint32 _offspringSpecies) {
//         NBMon memory _maleParent = nbmons[_maleId] - 1;
//         NBMon memory _femaleParent = nbmons[_femaleId] - 1;

//         // randomizing species
//         // origin is 1, wild = 2, hybrid = 3
//         uint32 _maleParentSpecies = _maleParent.nbmonStats[3];
//         uint32 _femaleParentSpecies = _femaleParent.nbmonStats[3];
//         // if origin + origin, offspring will be origin
//         if (_maleParentSpecies == 1 && _femaleParentSpecies == 1) {
//             _offspringSpecies = 1;
//         // if origin + hybrid or hybrid + origin, offspring will be hybrid
//         } else if ((_maleParentSpecies == 1 && _femaleParentSpecies == 3) || (_maleParentSpecies == 3 && _femaleParentSpecies == 1)) {
//             _offspringSpecies = 3;
//         // if origin + wild or wild + origin, offspring will be hybrid
//         } else if ((_maleParentSpecies == 1 && _femaleParentSpecies == 2) || (_maleParentSpecies == 2 && _femaleParentSpecies == 1)) {
//             _offspringSpecies = 3;
//         // if hybrid + wild or wild + hybrid, offspring will be hybrid
//         } else if ((_maleParentSpecies == 3 && _femaleParentSpecies == 2) || (_maleParentSpecies == 2 && _femaleParentSpecies == 3)) {
//             _offspringSpecies = 3;
//         // if hybrid + hybrid, offspring will be hybrid
//         } else if (_maleParentSpecies == 3 && _femaleParentSpecies == 3) {
//             _offspringSpecies = 3;
//         // if wild + wild, offspring will be wild
//         } else if (_maleParentSpecies == 2 && _femaleParentSpecies == 2) {
//             _offspringSpecies = 2;
//         }

//         return _offspringSpecies;
//     }

//     /**
//      * @dev Calculates the fertility points of the offspring. 
//      * Will also reduce parents' fertility points depending on rarity (check more on '../gamestats/fertility.txt')
//      * Note: Rarity here is HARD-CODED based on current rarityChance.txt logic. 
//      */
//     function _calculateOffspringFertility(uint256 _maleId, uint256 _femaleId) private returns (uint32 _offspringFertility) {
//         // takes an instance of the parents in storage so we can update their fertility points
//         NBMon storage _maleParent = nbmons[_maleId - 1];
//         NBMon storage _femaleParent = nbmons[_femaleId - 1];

//         uint32 _maleParentFertility = _maleParent.nbmonStats[5];
//         uint32 _femaleParentFertility = _femaleParent.nbmonStats[5];

//         /// checks rarity for male parent and calculates fertility point reduction based on it (current rarity logic is on rarity.txt)
//         uint32 _maleParentRarity = _maleParent.nbmonStats[1];
//         // checks for common rarity, reduces fertility points by 1000
//         if (_maleParentRarity <= 649) {
//             _maleParentFertility = _maleParentFertility - 1000;
//         // checks for uncommon rarity, reduces fertility points by 750
//         } else if (_maleParentRarity <= 849) {
//             _maleParentFertility = _maleParentFertility - 750;
//         // checks for rare rarity, reduces fertility points by 600
//         } else if (_maleParentRarity <= 949) {
//             _maleParentFertility = _maleParentFertility - 600;
//         // checks for epic rarity, reduces fertility points by 500
//         } else if (_maleParentRarity <= 989) {
//             _maleParentFertility = _maleParentFertility - 500;
//         // checks for legendary rarity, reduces fertility points by 375
//         } else if (_maleParentRarity <= 998) {
//             _maleParentFertility = _maleParentFertility - 375;
//         // checks for mythical rarity, reduces fertility points by 300
//         } else if (_maleParentRarity == 999) {
//             _maleParentFertility = _maleParentFertility - 300;
//         }

//         /// doing the same with the female parent 
//         uint32 _femaleParentRarity = _femaleParent.nbmonStats[1];
//         if (_femaleParentRarity <= 649) {
//             _femaleParentFertility = _femaleParentFertility - 1000;
//         } else if (_femaleParentRarity <= 849) {
//             _femaleParentFertility = _femaleParentFertility - 750;
//         } else if (_femaleParentRarity <= 949) {
//             _femaleParentFertility = _femaleParentFertility - 600;
//         } else if (_femaleParentRarity <= 989) {
//             _femaleParentFertility = _femaleParentFertility - 500;
//         } else if (_femaleParentRarity <= 998) {
//             _femaleParentFertility = _femaleParentFertility - 375;
//         } else if (_femaleParentRarity == 999) {
//             _femaleParentFertility = _femaleParentFertility - 300;
//         }

//         /// now gets the parent with the lowest fertility points as offspring's fertility points value
//         if (_maleParentFertility < _femaleParentFertility) {
//             _offspringFertility = _maleParentFertility;
//         // either take female parent's fertility points OR if both are the same, it defaults to female parent's fertility anyway
//         } else {
//             _offspringFertility = _femaleParentFertility;
//         }

//         return _offspringFertility;
//     }

// }