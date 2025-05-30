// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Registry {
    error PaymentNotEnough(uint256 expected, uint256 actual);

    uint256 public constant PRICE = 1 ether;

    mapping(address account => bool registered) private registry;

    function register() external payable {
        if(msg.value < PRICE) {
            revert PaymentNotEnough(PRICE, msg.value);
        }
   require(!registry[msg.sender] , "User Already Registered") ;

   uint refundAmt = msg.value - PRICE ;

        registry[msg.sender] = true;

   if (refundAmt > 0){
     (bool success , ) = msg.sender.call{value:refundAmt}("");
     require(success , "Transaction failed") ; 
   }

    }

    function isRegistered(address account) external view returns (bool) {
        return registry[account];
    }
}