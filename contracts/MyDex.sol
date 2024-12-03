// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract Dex is Ownable, ReentrancyGuard {
    // Router and factory interfaces
    IUniswapV2Router02 public uniswapRouter;
    IUniswapV2Factory public uniswapFactory;

    // Mapping to track liquidity providers
    mapping(address => mapping(address => uint256)) public liquidityProviders;

    // Events for better tracking
    event LiquidityAdded(
        address indexed provider,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event LiquidityRemoved(
        address indexed provider,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event TokensSwapped(
        address indexed sender,
        address[] path,
        uint256 amountIn,
        uint256 amountOut
    );
    event EmergencyWithdraw(
        address indexed user,
        address token,
        uint256 amount
    );

    // Supported token pairs
    struct TokenPair {
        address tokenA;
        address tokenB;
        address pairAddress;
    }
    TokenPair[] public supportedPairs;

    // Fee structure
    uint256 public constant FEE_PERCENTAGE = 3; // 0.3% fee
    address public feeCollector;

    constructor(
        address _uniswapRouterAddress,
        address _uniswapFactoryAddress,
        address _feeCollector
    ) Ownable(msg.sender) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
        uniswapFactory = IUniswapV2Factory(_uniswapFactoryAddress);
        feeCollector = _feeCollector;
    }

    // add liquidity function with tracking
    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        nonReentrant
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        // Transfer tokens to contract
        IERC20(_tokenA).transferFrom(msg.sender, address(this), amountADesired);
        IERC20(_tokenB).transferFrom(msg.sender, address(this), amountBDesired);

        // Approve router to spend tokens
        IERC20(_tokenA).approve(address(uniswapRouter), amountADesired);
        IERC20(_tokenB).approve(address(uniswapRouter), amountBDesired);

        // Add liquidity
        (amountA, amountB, liquidity) = uniswapRouter.addLiquidity(
            _tokenA,
            _tokenB,
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            to,
            block.timestamp + deadline
        );

        // Track liquidity providers
        liquidityProviders[_tokenA][_tokenB] += liquidity;

        // Emit event
        emit LiquidityAdded(msg.sender, _tokenA, _tokenB, amountA, amountB);

        return (amountA, amountB, liquidity);
    }

    // swap function with fee mechanism
    function swapTokensWithFee(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external nonReentrant {
        // Calculate fee
        uint256 feeAmount = (amountIn * FEE_PERCENTAGE) / 1000;
        uint256 amountAfterFee = amountIn - feeAmount;

        // Transfer tokens to contract
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);

        // Transfer fee to fee collector
        IERC20(path[0]).transfer(feeCollector, feeAmount);

        // Approve router to spend tokens
        IERC20(path[0]).approve(address(uniswapRouter), amountAfterFee);

        // Perform swap
        uint[] memory amounts = uniswapRouter.swapExactTokensForTokens(
            amountAfterFee,
            amountOutMin,
            path,
            to,
            block.timestamp + deadline
        );

        // Emit swap event
        emit TokensSwapped(
            msg.sender,
            path,
            amountIn,
            amounts[amounts.length - 1]
        );
    }

    // remove liquidity with tracking
    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        // Get pair address
        address pair = uniswapFactory.getPair(_tokenA, _tokenB);

        // Approve the router to spend LP tokens
        IERC20(pair).transferFrom(msg.sender, address(this), liquidity);
        IERC20(pair).approve(address(uniswapRouter), liquidity);

        // Remove liquidity
        (amountA, amountB) = uniswapRouter.removeLiquidity(
            _tokenA,
            _tokenB,
            liquidity,
            amountAMin,
            amountBMin,
            to,
            block.timestamp + deadline
        );

        // Update liquidity tracking
        liquidityProviders[_tokenA][_tokenB] -= liquidity;

        // Emit event
        emit LiquidityRemoved(msg.sender, _tokenA, _tokenB, amountA, amountB);

        return (amountA, amountB);
    }

    // Add supported token pair
    function addSupportedPair(
        address _tokenA,
        address _tokenB
    ) external onlyOwner {
        address pairAddress = uniswapFactory.getPair(_tokenA, _tokenB);

        // If pair doesn't exist, create it
        if (pairAddress == address(0)) {
            pairAddress = uniswapFactory.createPair(_tokenA, _tokenB);
        }

        supportedPairs.push(
            TokenPair({
                tokenA: _tokenA,
                tokenB: _tokenB,
                pairAddress: pairAddress
            })
        );
    }

    // Emergency withdraw in case of contract issues
    function emergencyWithdraw(address token) external nonReentrant {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No balance to withdraw");

        IERC20(token).transfer(msg.sender, balance);

        emit EmergencyWithdraw(msg.sender, token, balance);
    }

    // Get all supported pairs
    function getSupportedPairs() external view returns (TokenPair[] memory) {
        return supportedPairs;
    }

    // Update fee collector address (only owner)
    function updateFeeCollector(address _newFeeCollector) external onlyOwner {
        feeCollector = _newFeeCollector;
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
