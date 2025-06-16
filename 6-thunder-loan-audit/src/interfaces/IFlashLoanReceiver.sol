// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.20;

//report-written this is not used 
//This is bad practice to edit live code for mock tests, We must remove the 'MockFlashLoan'
import { IThunderLoan } from "./IThunderLoan.sol";

/**
 * @dev Inspired by Aave:
 * https://github.com/aave/aave-v3-core/blob/master/contracts/flashloan/interfaces/IFlashLoanReceiver.sol
 */
interface IFlashLoanReceiver {
    function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        address initiator,
        bytes calldata params
    )
        external
        returns (bool);
}
