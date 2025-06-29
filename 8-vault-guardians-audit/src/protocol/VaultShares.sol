// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC4626, ERC20, IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {IVaultShares, IERC4626} from "../interfaces/IVaultShares.sol";
import {AaveAdapter, IPool} from "./investableUniverseAdapters/AaveAdapter.sol";
import {UniswapAdapter} from "./investableUniverseAdapters/UniswapAdapter.sol";
import {DataTypes} from "../vendor/DataTypes.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract VaultShares is ERC4626, IVaultShares, AaveAdapter, UniswapAdapter, ReentrancyGuard {
    error VaultShares__DepositMoreThanMax(uint256 amount, uint256 max);
    error VaultShares__NotGuardian();
    error VaultShares__NotVaultGuardianContract();
    error VaultShares__AllocationNot100Percent(uint256 totalAllocation);
    error VaultShares__NotActive();

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    IERC20 internal immutable i_uniswapLiquidityToken; //e LP token of uniswap
    IERC20 internal immutable i_aaveAToken; //e returns aToken in return of underlying token example : ram invested 10 Usdc he gest 10 aUsdc that increase overtime as more intrest earned.
    address private immutable i_guardian; //e The owner of the protocol
    address private immutable i_vaultGuardians; //e guardian of the vault
    uint256 private immutable i_guardianAndDaoCut; //e dao cut when depositing
    bool private s_isActive; //e may be to resolve re-entrancy

    AllocationData private s_allocationData;

    uint256 private constant ALLOCATION_PRECISION = 1_000;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event UpdatedAllocation(AllocationData allocationData);
    event NoLongerActive();
    event FundsInvested();

    /*//////////////////////////////////////////////////////////////
                               MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier onlyGuardian() { //e modifier that only allows owner of the contract
        if (msg.sender != i_guardian) {
            revert VaultShares__NotGuardian();
        }
        _;
    }

    modifier onlyVaultGuardians() { //e modifier that only alows vault guardians
        if (msg.sender != i_vaultGuardians) {
            revert VaultShares__NotVaultGuardianContract();
        }
        _;
    }

    modifier isActive() { //e modifier that check if active or not to resolve re-entrancy may be
        if (!s_isActive) {
            revert VaultShares__NotActive();
        }
        _;
    }

    // slither-disable-start reentrancy-eth
    /**
     * @notice removes all supplied liquidity from Uniswap and supplied lending amount from Aave and then re-invests it back into them only if the vault is active
     */
    modifier divestThenInvest() { //e to take out the funds from pools and run the function , make some changes and then re-invest those funds.
        uint256 uniswapLiquidityTokensBalance = i_uniswapLiquidityToken.balanceOf(address(this));
        uint256 aaveAtokensBalance = i_aaveAToken.balanceOf(address(this));

        // Divest
        if (uniswapLiquidityTokensBalance > 0) {
            _uniswapDivest(IERC20(asset()), uniswapLiquidityTokensBalance);
        }
        if (aaveAtokensBalance > 0) {
            _aaveDivest(IERC20(asset()), aaveAtokensBalance);
        }

        _;

        // Reinvest
        if (s_isActive) {
            _investFunds(IERC20(asset()).balanceOf(address(this)));
        }
    }
    // slither-disable-end reentrancy-eth

    /*//////////////////////////////////////////////////////////////
                               FUNCTIONS
    //////////////////////////////////////////////////////////////*/
    // We use a struct to avoid stack too deep errors. Thanks Solidity
    constructor(ConstructorData memory constructorData)
        ERC4626(constructorData.asset)
        ERC20(constructorData.vaultName, constructorData.vaultSymbol)
        AaveAdapter(constructorData.aavePool)
        UniswapAdapter(constructorData.uniswapRouter, constructorData.weth, constructorData.usdc)
    {
        i_guardian = constructorData.guardian; //e owner of the contract
        i_guardianAndDaoCut = constructorData.guardianAndDaoCut; //e fees
        i_vaultGuardians = constructorData.vaultGuardians; //e vault guardians
        s_isActive = true; //e is Active vault or not
        updateHoldingAllocation(constructorData.allocationData); //e holding allocation modify

      //@FollowUp Reentrancy
        // External calls
        i_aaveAToken =
            IERC20(IPool(constructorData.aavePool).getReserveData(address(constructorData.asset)).aTokenAddress); // Gives the address of asset token contract
        i_uniswapLiquidityToken = IERC20(i_uniswapFactory.getPair(address(constructorData.asset), address(i_weth))); // Gives the pair of the pool with corresponding to the weth. example USDC/weth
    }

    /**
     * @notice Sets the vault as not active, which means that the vault guardian has quit
     * @notice Users will not be able to invest in this vault, however, they will be able to withdraw their deposited assets
     */

    function setNotActive() public onlyVaultGuardians isActive {
        s_isActive = false;
        emit NoLongerActive();
    }//e To set active or not

    /**
     * @notice Allows Vault Guardians to update their allocation ratio (and thus, their strategy of investment)
     * @param tokenAllocationData The new allocation data
     */

    
    function updateHoldingAllocation(AllocationData memory tokenAllocationData) public onlyVaultGuardians isActive {
        uint256 totalAllocation = tokenAllocationData.holdAllocation + tokenAllocationData.uniswapAllocation
            + tokenAllocationData.aaveAllocation; 

        if (totalAllocation != ALLOCATION_PRECISION) {
            revert VaultShares__AllocationNot100Percent(totalAllocation);
        }

        s_allocationData = tokenAllocationData;
        emit UpdatedAllocation(tokenAllocationData);
    } //e updates the holding of allocation by 1000 precision


    /**
     * @dev See {IERC4626-deposit}. Overrides the Openzeppelin implementation.
     *
     * @notice Mints shares to the DAO and the guardian as a fee
     */
    // slither-disable-start reentrancy-eth
    function deposit(uint256 assets, address receiver)
        public
        override(ERC4626, IERC4626)
        isActive
        nonReentrant
        returns (uint256)
    {
        if (assets > maxDeposit(receiver)) {
            revert VaultShares__DepositMoreThanMax(assets, maxDeposit(receiver));
        }//e max deposit is uint256.max

        uint256 shares = previewDeposit(assets); //e provides how much share to give based on asset amount

        _deposit(_msgSender(), receiver, assets, shares); // deposits the amount of assets and shares

        _mint(i_guardian, shares / i_guardianAndDaoCut);
        _mint(i_vaultGuardians, shares / i_guardianAndDaoCut);

        _investFunds(assets);
        return shares;
    }

    /**
     * @notice Invests user deposited assets into the investable universe (hold, Uniswap, or Aave) based on the allocation data set by the vault guardian
     * @param assets The amount of assets to invest
     */
    function _investFunds(uint256 assets) private {
        
        //@audit-info slight precision loss by truncate
        uint256 uniswapAllocation = (assets * s_allocationData.uniswapAllocation) / ALLOCATION_PRECISION; 
        uint256 aaveAllocation = (assets * s_allocationData.aaveAllocation) / ALLOCATION_PRECISION;

        emit FundsInvested();

        _uniswapInvest(IERC20(asset()), uniswapAllocation);
        _aaveInvest(IERC20(asset()), aaveAllocation);
    }

    // slither-disable-start reentrancy-benign
    /* 
     * @notice Unintelligently just withdraws everything, and then reinvests it all. 
     * @notice Anyone can call this and pay the gas costs to rebalance the portfolio at any time. 
     * @dev We understand that this is horrible for gas costs. 
     */
    function rebalanceFunds() public isActive divestThenInvest nonReentrant {} //e to be called after updateHoldingAllocation()

    /**
     * @dev See {IERC4626-withdraw}.
     *
     * We first divest our assets so we get a good idea of how many assets we hold.
     * Then, we redeem for the user, and automatically reinvest.
     */
    function withdraw(uint256 assets, address receiver, address owner)
        public
        override(IERC4626, ERC4626)
        divestThenInvest
        nonReentrant
        returns (uint256)
    {
        uint256 shares = super.withdraw(assets, receiver, owner);
        return shares;
    } //e withdraw the funds by burning the share and get underlying tokens

    /**
     * @dev See {IERC4626-redeem}.
     *
     * We first divest our assets so we get a good idea of how many assets we hold.
     * Then, we redeem for the user, and automatically reinvest.
     */
    function redeem(uint256 shares, address receiver, address owner)
        public
        override(IERC4626, ERC4626)
        divestThenInvest
        nonReentrant
        returns (uint256)
    {
        uint256 assets = super.redeem(shares, receiver, owner);
        return assets;
    }
    // slither-disable-end reentrancy-eth
    // slither-disable-end reentrancy-benign

    /*//////////////////////////////////////////////////////////////
                             VIEW AND PURE
    //////////////////////////////////////////////////////////////*/
    /**
     * @return The guardian of the vault
     */
    function getGuardian() external view returns (address) {
        return i_guardian;
    }

    /**
     * @return The ratio of the amount in vaults that goes to the vault guardians and the DAO
     */
    function getGuardianAndDaoCut() external view returns (uint256) {
        return i_guardianAndDaoCut;
    }

    /**
     * @return Gets the address of the Vault Guardians protocol
     */
    function getVaultGuardians() external view returns (address) {
        return i_vaultGuardians;
    }

    /**
     * @return A bool indicating if the vault is active (has an active vault guardian and is accepting deposits) or not
     */
    function getIsActive() external view returns (bool) {
        return s_isActive;
    }

    /**
     * @return The Aave aToken for the vault's underlying asset
     */
    function getAaveAToken() external view returns (address) {
        return address(i_aaveAToken);
    }

    /**
     * @return Uniswap's LP token
     */
    function getUniswapLiquidtyToken() external view returns (address) {
        return address(i_uniswapLiquidityToken);
    }

    /**
     * @return The allocation data set by the vault guardian
     */
    function getAllocationData() external view returns (AllocationData memory) {
        return s_allocationData;
    }
}
