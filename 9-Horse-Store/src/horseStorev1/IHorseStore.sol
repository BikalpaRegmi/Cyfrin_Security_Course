// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

interface IHorseStore {
       function updateHorseNumber(uint256 _horseNum) external ;
    function getHorseNumber() external view returns(uint256) ;

}