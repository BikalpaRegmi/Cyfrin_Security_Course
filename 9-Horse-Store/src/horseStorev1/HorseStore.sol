// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20 ;

contract HorseStore {

    uint256 public horseNumber ;

   function updateHorseNumber(uint256 _horseNum) external {
    horseNumber = _horseNum ;
   }

   function getHorseNumber() external view returns(uint256){
    return horseNumber ;
   }
}