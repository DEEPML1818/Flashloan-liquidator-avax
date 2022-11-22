// SPDX-License-Identifier: MIT
interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface WrappedEth {
    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address guy, uint256 wad) external returns (bool);
}

pragma solidity ^0.8;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import "hardhat/console.sol";
import './interfaces/traderjoe/ERC3156FlashBorrowerInterface.sol';
import './interfaces/traderjoe/JCollateralCapErc20.sol';
import './interfaces/traderjoe/JTokenInterface.sol';
import './interfaces/traderjoe/Joetroller.sol';
import './interfaces/traderjoe/JoeRouter02.sol';

contract TraderJoeLiquidator is ERC3156FlashBorrowerInterface {
    using SafeMath for uint256;
address wEthAddress = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address private WAVAX;
    address private JAVAX;
    address private USDC;
    address private JUSDC;
    address private JUSDT;
    address private JOETROLLER;
    address private JOEROUTER02;

    address public owner;

    constructor(
        address joetroller,
        address joeRouter02,
        address wavax,
        address usdc,
        address javax,
        address jusdc,
        address jusdt
    ) {
        owner = msg.sender;

        JOETROLLER = joetroller;
        JOEROUTER02 = joeRouter02;
        WAVAX = wavax;
        JAVAX = javax;
        JUSDC = jusdc;
        JUSDT = jusdt;
        USDC = usdc;
    }

    function withdraw(address asset) external {
        require(msg.sender == owner, 'not owner');

        uint256 balance = IERC20(asset).balanceOf(address(this));
        require(balance > 0, 'not enough balance');

        IERC20(asset).approve(address(this), balance);
        IERC20(asset).transfer(owner, balance);
    }

    
    
    function Arb(
        IJoeRouter01 router,
        uint256 amountOutMin,
        uint256 amountIn,
        address[] calldata path ,
        address Jtoken,
        address borrower 
    ) external {
        require(msg.sender == owner, 'not owner');
        PriceOracle priceOracle = PriceOracle(Joetroller(JOETROLLER).oracle());

        uint256 borrowBalance = JCollateralCapErc20(Jtoken).borrowBalanceCurrent(borrower);
        uint256 collateralBalance = JCollateralCapErc20(Jtoken).balanceOfUnderlying(borrower);
        bytes memory data = abi.encode(router, amountIn, path ,Jtoken );
        console.log("1");
        (address borrowAsset, uint256 borrowAmount) = getBorrowAssetAndAmount(Jtoken, borrower ,amountIn);
        console.log("2");
        JCollateralCapErc20(Jtoken).flashLoan(this, address(this), borrowAmount, data);
         console.log("got loan ");
        
         
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            address(this),
            block.timestamp + 100 
            
        );
        console.log("eye of the tiger ");

       //JCollateralCapErc20(borrowAsset).flashLoan(this, address(this), borrowAmount, data);
        // JoeRouter02(JOEROUTER02).swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), block.timestamp + 100);
    }
     //console.log("i am here start");
    // JoeRouter02(JOEROUTER02).swapExactTokensForTokens(amountIn, amountOutMin, path, address(this), block.timestamp + 100);


    function getBorrowAssetAndAmount(
        address Jtoken,
        address borrower,
        uint256 amountIn
    ) private view returns (address, uint256) {
        address borrowAsset;
        uint256 borrowAmount;
        PriceOracle priceOracle = PriceOracle(Joetroller(JOETROLLER).oracle());

        if (borrower == JAVAX || Jtoken == JAVAX) {
            if (borrower != JUSDT && Jtoken != JUSDT) {
                Jtoken = JUSDT;
            } else {
                Jtoken = JUSDC;
            }
            amountIn = (priceOracle.getUnderlyingPrice(JToken(Jtoken)) * amountIn) / 10**18 / 10**12;
        } else {
            Jtoken = JAVAX;
            amountIn =
                (priceOracle.getUnderlyingPrice(JToken(Jtoken)) * amountIn) /
                priceOracle.getUnderlyingPrice(JToken(JAVAX));
        }

        return (Jtoken, amountIn);
    }
   

    
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns (bytes32) {
        uint256 amountOwing = amount.add(fee);
        IERC20(token).approve(msg.sender, amountOwing);

        (address Router, address path, address Jtoken) = abi.decode(data, (address, address, address));

        

        
        return keccak256('ERC3156FlashBorrowerInterface.onFlashLoan');
    }

     function approveRouter(address router) external  {
        WrappedEth(wEthAddress).approve(router, type(uint256).max);
    }

    function simulateSwap(
        IJoeRouter01 router,
        uint256 amountIn,
        address[] memory path
    ) external view returns (uint256[] memory amounts) {
        return router.getAmountsOut(amountIn, path);
    }
    

    
}
