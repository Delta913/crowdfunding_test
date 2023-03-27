//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20TestToken is ERC20{

    constructor() ERC20("Test_Token", "TST") {
        _mint(msg.sender, 1000000000000000000000);
    }
}