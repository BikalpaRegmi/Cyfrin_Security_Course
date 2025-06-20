// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol" ;
contract ERC20Mock is ERC20{
    constructor() ERC20("Mock" , "MOCK"){}

    function mint(address _to , uint _amount) external {
     _mint(_to,_amount);
    }
    
}