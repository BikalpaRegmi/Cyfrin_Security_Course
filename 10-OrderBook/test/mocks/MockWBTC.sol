// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.26;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockWBTC is ERC20 {
    uint8 tokenDecimals;

    constructor(uint8 _tokenDecimals) ERC20("MockWBTC", "mWBTC") {
        tokenDecimals = _tokenDecimals;
    }

    function decimals() public view override returns (uint8) {
        return tokenDecimals;
    }

    function mint(address to, uint256 value) public {
        uint256 updateDecimals = uint256(tokenDecimals);
        _mint(to, (value * 10 ** updateDecimals));
    }
}
