// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console } from "forge-std/Test.sol";
import { TSwapPool } from "../../src/PoolFactory.sol";
import { ERC20Mock } from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

contract TSwapPoolTest is Test {
    TSwapPool pool;
    ERC20Mock poolToken;
    ERC20Mock weth;

    address liquidityProvider = makeAddr("liquidityProvider");
    address user = makeAddr("user");

    function setUp() public {
        poolToken = new ERC20Mock();
        weth = new ERC20Mock();
        pool = new TSwapPool(address(poolToken), address(weth), "LTokenA", "LA");

        weth.mint(liquidityProvider, 200e18);
        poolToken.mint(liquidityProvider, 200e18);

        weth.mint(user, 10e18);
        poolToken.mint(user, 10e18);
    }

    function testDeposit() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));

        assertEq(pool.balanceOf(liquidityProvider), 100e18);
        assertEq(weth.balanceOf(liquidityProvider), 100e18);
        assertEq(poolToken.balanceOf(liquidityProvider), 100e18);

        assertEq(weth.balanceOf(address(pool)), 100e18);
        assertEq(poolToken.balanceOf(address(pool)), 100e18);
    }

    function testDepositSwap() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(user);
        poolToken.approve(address(pool), 10e18);
        // After we swap, there will be ~110 tokenA, and ~91 WETH
        // 100 * 100 = 10,000
        // 110 * ~91 = 10,000
        uint256 expected = 9e18;

        pool.swapExactInput(poolToken, 10e18, weth, expected, uint64(block.timestamp));
        assert(weth.balanceOf(user) >= expected);
    }

    function testWithdraw() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));

        pool.approve(address(pool), 100e18);
        pool.withdraw(100e18, 100e18, 100e18, uint64(block.timestamp));

        assertEq(pool.totalSupply(), 0);
        assertEq(weth.balanceOf(liquidityProvider), 200e18);
        assertEq(poolToken.balanceOf(liquidityProvider), 200e18);
    }

    function testCollectFees() public {
        vm.startPrank(liquidityProvider);
        weth.approve(address(pool), 100e18);
        poolToken.approve(address(pool), 100e18);
        pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(user);
        uint256 expected = 9e18;
        poolToken.approve(address(pool), 10e18);
        pool.swapExactInput(poolToken, 10e18, weth, expected, uint64(block.timestamp));
        vm.stopPrank();

        vm.startPrank(liquidityProvider);
        pool.approve(address(pool), 100e18);
        pool.withdraw(100e18, 90e18, 100e18, uint64(block.timestamp));
        assertEq(pool.totalSupply(), 0);
        assert(weth.balanceOf(liquidityProvider) + poolToken.balanceOf(liquidityProvider) > 400e18);
    }

   function test_getInputAmountBasedOnOutput() external {
    uint inputReserves = 1000 ;
    uint outputReserves = 2000 ;
    uint outputAmount = 100 ;

    uint expected = ((inputReserves * outputAmount) * 1000) / ((outputReserves - outputAmount) * 997) ;
    uint reality = pool.getInputAmountBasedOnOutput(outputAmount , inputReserves , outputReserves);

    assertEq(expected , reality  , "Calculation doesnt match expected output") ;
}

function test_H4_sellPoolTokens_shouldUseSwapExactInput() external {
  vm.startPrank(liquidityProvider) ;
  weth.approve(address(pool) , type(uint256).max) ;
  poolToken.approve(address(pool) , type(uint256).max) ;
  pool.deposit(100e18 , 100e18 , 100e18 , uint64(block.timestamp));  
  vm.stopPrank() ;

  vm.startPrank(user) ;
  weth.approve(address(pool) , type(uint256).max) ;
  poolToken.approve(address(pool) , type(uint256).max) ;

  uint expected = pool.swapExactInput(poolToken , 2e18 , weth , 16e17, uint64(block.timestamp)) ; //Note :This is called after solvving the return output params in swapExactInput function
console.log("User weth balance:", weth.balanceOf(user));
console.log("User poolToken balance:", poolToken.balanceOf(user));
uint reality = pool.sellPoolTokens(2e18) ;
assertEq(expected , reality );
  vm.stopPrank() ;
  
}

function test_SwapExactInputReturnMistake() external {
    vm.startPrank(liquidityProvider) ;
    poolToken.approve(address(pool) , type(uint256).max);
    weth.approve(address(pool) , type(uint256).max);
    pool.deposit(100e18 , 100e18, 100e18 , uint64(block.timestamp)) ;
    vm.stopPrank();

    vm.startPrank(user) ;
       poolToken.approve(address(pool) , type(uint256).max);
    weth.approve(address(pool) , type(uint256).max);

    uint result = pool.swapExactInput(poolToken , 2e18 , weth , 16e17 , uint64(block.timestamp)) ;

    assertEq(result , 0) ;
    vm.stopPrank();
}

function testInvariantBroken() public {
    vm.startPrank(liquidityProvider);
    weth.approve(address(pool), 100e18);
    poolToken.approve(address(pool), 100e18);
    pool.deposit(100e18, 100e18, 100e18, uint64(block.timestamp));
    vm.stopPrank();

    uint256 outputWeth = 1e17;

    vm.startPrank(user);
    poolToken.approve(address(pool), type(uint256).max);
    poolToken.mint(user, 10e18);
    pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
    pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
    pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
    pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
    pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
    pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
    pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
    pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));
    pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));

    int256 startingY = int256(weth.balanceOf(address(pool))) ;
    int256 expectedDeltaY = int256(-1) * int256(outputWeth) ;
  
      pool.swapExactOutput(poolToken, weth, outputWeth, uint64(block.timestamp));

    int256 endingY = int256(weth.balanceOf(address(pool))) ;
        int256 actualDeltaY = endingY - startingY ;

        assertEq(expectedDeltaY , actualDeltaY) ;

}

}
