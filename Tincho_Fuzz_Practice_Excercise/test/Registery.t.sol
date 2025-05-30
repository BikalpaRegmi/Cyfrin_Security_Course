// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Registry} from "../src/Registry.sol";

contract RegistryTest is Test {
    Registry registry;
    address alice;

    function setUp() public {
        alice = makeAddr("alice");
        
        registry = new Registry();
    }

    function test_register() public {
        uint256 amountToPay = registry.PRICE();
        
        vm.deal(alice, amountToPay);
        vm.startPrank(alice);

        uint256 aliceBalanceBefore = address(alice).balance;

        registry.register{value: amountToPay}();

        uint256 aliceBalanceAfter = address(alice).balance;
        
        assertTrue(registry.isRegistered(alice), "Did not register user");
        assertEq(address(registry).balance, registry.PRICE(), "Unexpected registry balance");
        assertEq(aliceBalanceAfter, aliceBalanceBefore - registry.PRICE(), "Unexpected user balance");
    }



       function test_fuzz_register(uint256 amountToPay) public {
        vm.assume(amountToPay >= 1 ether);
        
        vm.deal(alice, amountToPay);
        vm.startPrank(alice);

        uint256 aliceBalanceBefore = address(alice).balance;

        registry.register{value: amountToPay}();

        uint256 aliceBalanceAfter = address(alice).balance;
        
        assertTrue(registry.isRegistered(alice), "Did not register user");
        assertEq(address(registry).balance, registry.PRICE(), "Unexpected registry balance");
        assertEq(aliceBalanceAfter, aliceBalanceBefore - registry.PRICE(), "Unexpected user balance");
    }

    function test_theUserReRegisterAndLoosesMoney() external {
         uint256 amountToPay = registry.PRICE();
        
        vm.deal(alice, 2*amountToPay);
        vm.startPrank(alice);

        uint256 aliceBalanceBefore = address(alice).balance;

        registry.register{value: amountToPay}();
        registry.register{value: amountToPay}();

        uint256 aliceBalanceAfter = address(alice).balance;
        
        assertTrue(registry.isRegistered(alice), "Did not register user");
        assertEq(address(registry).balance, (2*registry.PRICE()), "Unexpected registry balance");
        assertEq(aliceBalanceAfter, aliceBalanceBefore - (2*registry.PRICE()), "Unexpected user balance");
    }
}