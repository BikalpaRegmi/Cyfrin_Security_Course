// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

//@audit-info the Ithunderloan contract should be implemented by thunderloan contract
interface IThunderLoan {
    //@audit-low the parameters are wrong
    function repay(address token, uint256 amount) external;
}
