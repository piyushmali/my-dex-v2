// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract MyDex {
    IUniswapV2Router02 public uniswapRouter;
    IUniswapV2Factory public uniswapFactory;
    address public tokenA;
    address public tokenB;

    constructor(
        address _uniswapRouterAddress,
        address _uniswapFactoryAddress,
        address _tokenA,
        address _tokenB
    ) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
        uniswapFactory = IUniswapV2Factory(_uniswapFactoryAddress);
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    // Add liquidity function
    function addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external {
        require(
            IERC20(tokenA).allowance(msg.sender, address(this)) >=
                amountADesired,
            "Insufficient allowance for token A"
        );
        require(
            IERC20(tokenB).allowance(msg.sender, address(this)) >=
                amountBDesired,
            "Insufficient allowance for token B"
        );

        deadline = block.timestamp + deadline;
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountADesired);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountBDesired);

        // Approve the router to spend tokens
        IERC20(tokenA).approve(address(uniswapRouter), amountADesired);
        IERC20(tokenB).approve(address(uniswapRouter), amountBDesired);

        uniswapRouter.addLiquidity(
            tokenA,
            tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    // Swap tokens function
    function swapTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external {
        deadline = block.timestamp + deadline;
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);

        // Approve the router to spend tokens
        IERC20(path[0]).approve(address(uniswapRouter), amountIn);

        uniswapRouter.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            to,
            deadline
        );
    }

    // Remove liquidity function
    function removeLiquidity(
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external {
        deadline = block.timestamp + deadline;
        // Call removeLiquidity from the router
        uniswapRouter.removeLiquidity(
            tokenA,
            tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            deadline
        );
    }

    // Create pair function
    function createPair() external returns (address pair) {
        return uniswapFactory.createPair(tokenA, tokenB);
    }

    // Get pair function
    function getPair() external view returns (address pair) {
        return uniswapFactory.getPair(tokenA, tokenB);
    }
}
