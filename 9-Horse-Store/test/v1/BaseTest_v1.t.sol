// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.27;

import {HorseStore} from "../../src/horseStorev1/HorseStore.sol" ;
import {Test} from "forge-std/Test.sol" ;

abstract contract Base_Testv1 is Test {
  HorseStore public horseStore ;

  function setUp() external virtual{
  horseStore = new HorseStore() ;
  }

  function test_readValue() external {
uint256 initialValue = horseStore.getHorseNumber() ;
assertEq(initialValue , 0);
  } 

  function test_writeValue() external {
    uint256 numberOfHorses = 777 ;
    horseStore.updateHorseNumber(numberOfHorses) ;
    assertEq(horseStore.getHorseNumber() , numberOfHorses) ;
  } //
}