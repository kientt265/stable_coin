// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DecentralizedStableCoin} from "./DecentralizedStableCoint.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IREC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
/*
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
    error DSCEngine_BreaksHealthFactor(uint256 userHealthFactor);
    error DSCEngine_Failed();
    /////////////////////////////
    ///// State Variables ///////
    ////////////////////////////
    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MINT_HEALTH_FACTOR = 1e18;
    mapping(address token => address priceFeed) private s_priceFeed; //tokenToPriceFeed
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited;
    mapping(address user => uint256 amountDscMinted) private s_DSCMinted;
    address[] private s_collateralTokens;
    DecentralizedStableCoin private immutable i_dsc;
    /////////////////////
    ///// Events ///////
    ///////////////////
    event CollateralDeposited(address indexed user, address indexed token, uint256 amount);
    event CollateralRedeemed(address indexed user, address indexed token, uint256 amount);
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
    ////////////////////////
    ///// Functions ///////
    ///////////////////////

    constructor(address[] memory tokenAdresses, address[] memory priceFeedAddresses, address dscAdress) {
        if (tokenAdresses.length != priceFeedAddresses.length) {
            revert DSCEngine_TokenAdressesAndPriceFeedAddressesMustBeSameLength();
        }
        for (uint256 i = 0; i < tokenAdresses.length; i++) {
            s_priceFeed[tokenAdresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAdresses[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAdress);
    }
    //////////////////////
    ///// External ///////
    ////////////////////

    function depositCollateralAndMintDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToMint) external {

        depositCollareal(tokenCollateralAddress, amountCollateral);
        mintDsc(amountDscToMint);
    }

    function depositCollareal(address tokenCollateralAddress, uint256 amountCollateral)
        public
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

    function redeemCollateralForDsc(address tokenCollateralAddress, uint256 amountCollateral, uint256 amountDscToBurn) external {
        burnDsc(amountDscToBurn);
        redeemCollateral((tokenCollateralAddress), amountCollateral);

    }

    function redeemCollateral(address tokenCollateralAddress, uint256 amountCollateral) public moreThanZero(amountCollateral) nonReentrant {

        s_collateralDeposited[msg.sender][tokenCollateralAddress] -= amountCollateral;
        emit CollateralRedeemed(msg.sender, tokenCollateralAddress, amountCollateral);
        //_calculateHealthFactorAfter()
        bool success = IERC20(tokenCollateralAddress).transfer(msg.sender, amountCollateral);
        if(!success) {
            revert DSCEngine_TransferFailed();
        }
        _revertIfHealthFactorIsBroken(msg.sender);


    }

    function mintDsc(uint256 amountDscToMint) public moreThanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDScToMint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if(!minted) {
            revert DSCEngine_Failed();
        }
    }

    function burnDsc(uint256 amount) public moreThanZero(amount) {
        s_DSCMinted[msg.sender] -= amount;
        bool success = i_dsc.transferFrom(msg.sender, address(this), amount);
        if(!success) {
            revert DSCEngine_TransferFailed();
        }
        i_dsc.burn(amount);
        _revertIfHealthFactorIsBroken(msg.sender);
    }

    function liquidate() external {}

    function getHealthFactor() external view {}

    /////////////////////////////////
    ///// Private & Internal ///////
    ///////////////////////////////

    function _getAccountInformation(address user) private view returns(uint256 totalDscMinted, uint256 collateralValueInUsd){
        totalDscMinted = s_DSCMinted[user];
        collateralValueInUsd = getAccountCollateralValue(user);
    }
    function _healthFactor(address user) private view returns(uint256){
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = _getAccountInformation(user);
        uint256 collateralAdjustedForThreshold = (collateralValueInUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateralAdjustedForThreshold * PRECISION) / totalDscMinted;
        //1000 ETH * 50 = 50.000 / 100 = 500
        //$150 ETH / 100 DSC = 1.5
        // return (collateralValueInUsd/ totalDscMinted); //150 / 100
    }
    function _revertIfHealthFactorIsBroken(adress user) internal view {
        uint256 userHealthFactor =  _healthFactor(user);
        if(userHealthFactor < MINT_HEALTH_FACTOR){
            revert DSCEngine_BreaksHealthFactor(userHealthFactor);
        }
    }

    /////////////////////////////////////////////
    ///// Public & Internal View Function ///////
    ////////////////////////////////////////////

    function getAccountCollateralValue(address user) public view returns(uint256 ) {
        for(uint256 i = 0; i< s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[user][token];
            uint256 totalCollateralValueInUsd +=  getUsdValue(token, amount);
        }
        return totalCollateralValueInUsd;
    }

    function getUsdValue(address token, uint256 amount) public view returns(uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (,int256 price,,,) = priceFeed.lastestRoundData();
        return (uint256(price)* ADDITIONAL_FEED_PRECISION * amount) / PRECISION; //(1000*1e8)* 1000 * 1e18
    }
}
