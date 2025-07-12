// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import {Base_Testv1} from "./BaseTest_v1.t.sol" ; 
import {HorseStoreYul } from "../../src/horseStorev1/HorseStoreYul.sol" ;
import { IHorseStore} from "../../src/horseStorev1/IHorseStore.sol" ;

contract HorseStoreSolc is Base_Testv1 {
    function setUp() external override{
     horseStore = IHorseStore(address(new HorseStoreYul())) ;
    }
 }