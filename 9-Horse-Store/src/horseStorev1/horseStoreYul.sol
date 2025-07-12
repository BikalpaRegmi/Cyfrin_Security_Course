// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20 ;

contract HorseStoreYul {

    uint256 public horseNumber ;

   function updateHorseNumber(uint256 _horseNum) external {
    // horseNumber = _horseNum ;
    assembly{
        sstore(horseNumber.slot , _horseNum)
    }
   }

   function getHorseNumber() external view returns(uint256){
    // return horseNumber ;
    assembly{
        let res := sload(horseNumber.slot)
        mstore(0,res)
        return(0,0x20)
    }
   }
}