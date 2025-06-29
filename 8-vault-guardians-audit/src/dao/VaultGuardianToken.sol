// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit, Nonces} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {ERC20Votes} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract VaultGuardianToken is ERC20, ERC20Permit, ERC20Votes, Ownable {
    constructor() ERC20("VaultGuardianToken", "VGT") ERC20Permit("VaultGuardianToken") Ownable(msg.sender) {}

    // The following functions are overrides required by Solidity.This function is to resolve muliple inheritance conflicts.
    function _update(address from, address to, uint256 value) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    //This function is to resolve muliple inheritance conflicts.
    function nonces(address ownerOfNonce) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(ownerOfNonce);
    }

//e This contract mints the DAO tokens to the vault guardians i.e stake tokens.
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
