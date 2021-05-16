// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @notice - This is the DGVC Token (that is mock token) contract
 */
contract DGVCToken is ERC20 {
    constructor() public ERC20("DGVC Token (Mock)", "DGVC") {
        uint initialSupply = 1e8 * 1e18;   // 1 milion
        _mint(msg.sender, initialSupply);
    }
}