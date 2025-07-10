// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import {Base_Testv1 , HorseStore} from "./BaseTest_v1.t.sol" ; 
import {HuffDeployer} from "foundry-huff/HuffDeployer.sol" ;

contract HorseStoreSolc is Base_Testv1 { 
string public constant HorseStore_Huff_Location = "horseStorev1/HorseStore" ;

    function setUp() external override{
horseStore = HorseStore(HuffDeployer.config().deploy(HorseStore_Huff_Location)) ;
// on terminal -: forge test --match-path *Huff* -vvv 
    }
}