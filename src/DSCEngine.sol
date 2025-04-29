// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {DecentralizedStableCoin} from "./DecentralizedStableCoint.sol";
/**
*@tiltle DSCEngine
@author PoloStone
 */

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

contract DSCEngine{
    /////////////////////
    ///// Errors ///////
    ///////////////////
    error DSCEngine_NeedsMoreThanZero();
    error DSCEngine_TokenAdressesAndPriceFeedAddressesMustBeSameLength();
    /////////////////////////////
    ///// State Variables ///////
    ////////////////////////////
    mapping(address token => address priceFeed) private s_priceFeed; //tokenToPriceFeed
    DecentralizedStableCoin private immutable i_dsc;

    /////////////////////
    ///// Modifier ///////
    ///////////////////

    modifier moreThanZero(uint256 _amount){
        if(_amount == 0) {
            revert DSCEngine_NeedsMoreThanZero();
        }
    }

    modifier isAllowedToken(address token) {

    }
    /////////////////////
    ///// Functions ///////
    ///////////////////
    constructor(
        address[] memory tokenAdresses,
        address[] memory priceFeedAddresses,
        address dscAdress) {
            if(tokenAdresses.length != priceFeedAddresses.length){
                revert DSCEngine_TokenAdressesAndPriceFeedAddressesMustBeSameLength();
            }
            for (uint256 i = 0; i <tokenAdresses.length; i++){
                s_priceFeed[tokenAdresses[i]] = priceFeedAddresses[i];
            }
    }
    /////////////////////
    ///// External ///////
    ///////////////////
    function depositCollateralAndMintDsc() external{}

    function depositCollareal(
        address tokenCollateral,
        uint256 amountCollateral
        ) external moreThanZero(amountCollateral) {}

    function redeemCollateralForDsc() external{}

    function redeemCollateral() external{}

    function mintDsa() external{}

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}