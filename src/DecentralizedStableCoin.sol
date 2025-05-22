// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {ERC20Burnable, ERC20} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title DecentralizedStableCoin
/// @author Michael
/// @notice Exogenous (ETH)
//This is cthe contract meant to be governed by DSCEngine. This con tract is  just
//the ERC 20 implementaion of our stabblecoin system

// Layout of Contract:
// - version
// - imports
// - errors
// - interfaces, libraries, contracts
// - Type declarations
// - State variables
// - Events
// - Modifiers
// - Functions

// Layout of Functions:
// - constructor
// - receive function (if exists)
// - fallback function (if exists)
// - external
// - public
// - internal
// - private
// - view & pure functions

contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    // 1. State variables

    // 2. Events

    // 3. Errors
    error DecentralizedStableCoin_MustBeMoreThanZero();
    error DecentralizedStableCoin_BurnAmountExceedsBalance();
    error DecentralizedStableCoin_NotZeroAddress();
    // 4. Modifiers

    // 5. Constructor
    constructor(address initialOwner) ERC20("DecentralizeStableCoin", "DSC") Ownable(initialOwner) {}

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralizedStableCoin_MustBeMoreThanZero();
        }
        if (balance < _amount) {
            revert DecentralizedStableCoin_BurnAmountExceedsBalance();
        }
        super.burn(_amount);
    }
    // 6. External functions

    // 7. Public functions
    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_to == address(0)) {
            revert DecentralizedStableCoin_NotZeroAddress();
        }
        if (_amount <= 0) {
            revert DecentralizedStableCoin_MustBeMoreThanZero();
        }
        _mint(_to, _amount);
        return true;
    }
    // 8. Internal functions

    // 9. Private functions

    // 10. View & Pure functions
}
