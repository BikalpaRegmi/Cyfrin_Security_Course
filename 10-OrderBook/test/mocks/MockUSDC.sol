// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUSDC is ERC20 {
    uint8 tokenDecimals;

    constructor(uint8 _tokenDecimals) ERC20("MockUSDC", "mUSDC") {
        tokenDecimals = _tokenDecimals;
    }

    /*e
    Decimals defines how many decimal places does token uses.
    If decimal = 18, then : 1 Token = 1*10^18 or 1e19 (Just like ethers i.e 1 ether = 1e19 wei).
    If decimals = 6, then : 1 Token = 1*10^6 or 1e7.
     */

    function decimals() public view override returns (uint8) {
        return tokenDecimals;
    }

    function mint(address to, uint256 value) public {
        uint256 updateDecimals = uint256(tokenDecimals);
        _mint(to, (value * 10 ** updateDecimals));
    }
}
