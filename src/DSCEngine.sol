// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoint.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IREC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/**
 * @tiltle DSCEngine
 * @author PoloStone
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

contract DSCEngine is ReentrancyGuard {
    /////////////////////
    ///// Errors ///////
    ///////////////////
    error DSCEngine_NotAllowedToken();
    error DSCEngine_NeedsMoreThanZero();
    error DSCEngine_TokenAdressesAndPriceFeedAddressesMustBeSameLength();
    error DSCEngine_TransferFailed();
    /////////////////////////////
    ///// State Variables ///////
    ////////////////////////////

    mapping(address token => address priceFeed) private s_priceFeed; //tokenToPriceFeed
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 admountDscMinted) private s_DSCMinted;
    DecentralizedStableCoin private immutable i_dsc;
    /////////////////////
    ///// Events ///////
    ///////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);
    /////////////////////
    ///// Modifier ///////
    ///////////////////

    modifier moreThanZero(uint256 _amount) {
        if (_amount == 0) {
            revert DSCEngine_NeedsMoreThanZero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeed[token] == address(0)) {
            revert DSCEngine_NotAllowedToken();
        }
        _;
    }
    /////////////////////
    ///// Functions ///////
    ///////////////////

    constructor(address[] memory tokenAdresses, address[] memory priceFeedAddresses, address dscAdress) {
        if (tokenAdresses.length != priceFeedAddresses.length) {
            revert DSCEngine_TokenAdressesAndPriceFeedAddressesMustBeSameLength();
        }
        for (uint256 i = 0; i < tokenAdresses.length; i++) {
            s_priceFeed[tokenAdresses[i]] = priceFeedAddresses[i];
        }
        i_dsc = DecentralizedStableCoin(dscAdress);
    }
    /////////////////////
    ///// External ///////
    ///////////////////

    function depositCollateralAndMintDsc() external {}

    function depositCollareal(address tokenCollateralAddress, uint256 amountCollateral)
        external
        moreThanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAdress, amountCollateral);
        bool susscess = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if(!susscess) {
            revert DSCEngine_TransferFailed();
        }
    }

    function redeemCollateralForDsc() external {}

    function redeemCollateral() external {}

    function mintDsc(uint256 amountDscToMint) external moreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDScToMint;
        revertIfHealthFactorIsBroken(msg.sender);

    }

    function burnDsc() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

    /////////////////////////////////
    ///// Private & Internal ///////
    ///////////////////////////////

    function _healthFactor(address user) private view returns(uint256){
        
    }
    function revertIfHealthFactorIsBroken(adress user) internal view {

    }

}
