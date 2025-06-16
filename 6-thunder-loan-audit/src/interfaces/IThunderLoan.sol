// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

//report-written the Ithunderloan contract should be implemented by thunderloan contract
interface IThunderLoan {
    //report-written the parameters are wrong
    function repay(address token, uint256 amount) external;
}
