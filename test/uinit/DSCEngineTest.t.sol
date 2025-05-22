// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {Test, console} from "forge-std/Test.sol";
import{StdInvariant} from "forge-std/StdInvariant.sol";

contract DSCEngineTest is StdInvariant, Test {
    DeployDSC deployer;
    DSCEngine dsce;
    DecentralizedStableCoin dsc;
    HelperConfig config;

    address weth;
    address wbtc;
    address ethUsdPriceFeed;
    address btcUsdPriceFeed;
    address public USER = makeAddr("user");
    uint256 public constant AMOUNT_COLLATERAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;
    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        dsce.depositCollareal(weth, AMOUNT_COLLATERAL);
        vm.stopPrank();
        _;

    }


    function setUp() public {
        deployer = new DeployDSC();
        
        (dsce, dsc, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed , weth, wbtc,) = config.activeNeworkConfig();
        ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
    }



    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 actualUsd = dsce.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, actualUsd);
    }

     function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(dsce), AMOUNT_COLLATERAL);
        vm.expectRevert(DSCEngine.DSCEngine_NeedsMoreThanZero.selector);
        dsce.depositCollareal(weth, 0);
        vm.stopPrank();
     }

     function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        tokenAddresses.push(wbtc);
        priceFeedAddresses.push(ethUsdPriceFeed);
        // priceFeedAddresses.push(btcUsdPriceFeed);
        vm.expectRevert(DSCEngine.DSCEngine_TokenAdressesAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
     }

     function testGetTokenAmountFromUsd() public {
        uint256 AmountValueUsd = 10000 ether;
        uint256 ExpectToken = 5 ether;
        uint256 ActualToken = dsce.getTokenAmountFromUsd(weth, AmountValueUsd);
        assertEq(ExpectToken, ActualToken);
     }

    //Kiem tra xem co loai token nay trong list khong
     function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock tokener20 = new ERC20Mock();
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine_NotAllowedToken.selector);
        dsce.depositCollareal(address(tokener20), AMOUNT_COLLATERAL);
        vm.stopPrank();
     }

     function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral{
        (uint256 totalDsaMinted, uint256 collateralValueInUsd) = dsce.getAccountInformation(USER);
        assertEq(totalDsaMinted, 0);
        assertEq(collateralValueInUsd, 0);
     }

}