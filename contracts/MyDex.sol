// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract Dex is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Router and factory interfaces
    IUniswapV2Router02 public uniswapRouter;
    IUniswapV2Factory public uniswapFactory;

    // Mapping to track liquidity providers
    mapping(address => mapping(address => uint256)) public liquidityProviders;

    // Whitelist for tokens
    mapping(address => bool) public whitelistedTokens;

    // Staking rewards for liquidity providers
    mapping(address => mapping(address => uint256)) public stakingRewards;

    // Supported token pairs
    struct TokenPair {
        address tokenA;
        address tokenB;
        address pairAddress;
    }
    TokenPair[] public supportedPairs;

    // Price oracle to prevent manipulation
    mapping(address => mapping(address => uint256)) public lastCheckedPrice;

    // Governance token for protocol
    IERC20 public governanceToken;

    // Fee structure
    uint256 public FEE_PERCENTAGE = 3; // 0.3% fee
    uint256 public constant REWARD_RATE = 10; // 0.1% of liquidity as reward
    uint256 public constant PRICE_CHECK_COOLDOWN = 1 hours;

    address public feeCollector;

    // Circuit breaker for emergency situations
    bool public paused = false;

    // Events
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
    event TokenWhitelisted(address indexed token, bool status);
    event StakingRewardClaimed(
        address indexed user,
        address tokenA,
        address tokenB,
        uint256 amount
    );
    event PriceUpdated(
        address indexed tokenA,
        address indexed tokenB,
        uint256 price
    );
    event ContractPaused(address indexed pauser);
    event ContractUnpaused(address indexed unpauser);
    event FeeCollectorUpdated(address indexed newFeeCollector);

    // Modifiers
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor(
        address _uniswapRouterAddress,
        address _uniswapFactoryAddress,
        address _feeCollector,
        address _governanceToken
    ) Ownable(msg.sender) {
        uniswapRouter = IUniswapV2Router02(_uniswapRouterAddress);
        uniswapFactory = IUniswapV2Factory(_uniswapFactoryAddress);
        feeCollector = _feeCollector;
        governanceToken = IERC20(_governanceToken);
    }

    // Whitelist tokens for trading
    function whitelistToken(address _token, bool _status) external onlyOwner {
        whitelistedTokens[_token] = _status;
        emit TokenWhitelisted(_token, _status);
    }

    // Add liquidity function with tracking and enhanced features
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
        whenNotPaused
        returns (uint256 amountA, uint256 amountB, uint256 liquidity)
    {
        // Check token whitelist
        require(
            whitelistedTokens[_tokenA] && whitelistedTokens[_tokenB],
            "Token not whitelisted"
        );

        // Transfer tokens to contract
        IERC20(_tokenA).safeTransferFrom(
            msg.sender,
            address(this),
            amountADesired
        );
        IERC20(_tokenB).safeTransferFrom(
            msg.sender,
            address(this),
            amountBDesired
        );

        // Approve router to spend tokens
        IERC20(_tokenA).safeIncreaseAllowance(
            address(uniswapRouter),
            amountADesired
        );
        IERC20(_tokenB).safeIncreaseAllowance(
            address(uniswapRouter),
            amountBDesired
        );

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

        // Calculate and track staking rewards
        uint256 rewardAmount = (liquidity * REWARD_RATE) / 1000;
        stakingRewards[_tokenA][_tokenB] += rewardAmount;

        // Emit event
        emit LiquidityAdded(msg.sender, _tokenA, _tokenB, amountA, amountB);

        return (amountA, amountB, liquidity);
    }

    // Swap tokens with fee mechanism
    function swapTokensWithFee(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external nonReentrant whenNotPaused {
        // Verify token whitelist
        require(
            whitelistedTokens[path[0]] &&
                whitelistedTokens[path[path.length - 1]],
            "Token not whitelisted"
        );

        // Calculate fee
        uint256 feeAmount = (amountIn * FEE_PERCENTAGE) / 1000;
        uint256 amountAfterFee = amountIn - feeAmount;

        // Transfer tokens to contract
        IERC20(path[0]).safeTransferFrom(msg.sender, address(this), amountIn);

        // Transfer fee to fee collector
        IERC20(path[0]).safeTransfer(feeCollector, feeAmount);

        // Approve router to spend tokens
        IERC20(path[0]).safeIncreaseAllowance(
            address(uniswapRouter),
            amountAfterFee
        );

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

    // Remove liquidity with tracking
    function removeLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        nonReentrant
        whenNotPaused
        returns (uint256 amountA, uint256 amountB)
    {
        // Get pair address
        address pair = uniswapFactory.getPair(_tokenA, _tokenB);

        // Approve the router to spend LP tokens
        IERC20(pair).safeTransferFrom(msg.sender, address(this), liquidity);
        IERC20(pair).safeIncreaseAllowance(address(uniswapRouter), liquidity);

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

    // Claim staking rewards
    function claimStakingRewards(
        address _tokenA,
        address _tokenB
    ) external nonReentrant whenNotPaused {
        uint256 reward = stakingRewards[_tokenA][_tokenB];
        require(reward > 0, "No rewards available");

        stakingRewards[_tokenA][_tokenB] = 0;
        IERC20(_tokenA).safeTransfer(msg.sender, reward);

        emit StakingRewardClaimed(msg.sender, _tokenA, _tokenB, reward);
    }

    // Price oracle to prevent price manipulation
    function updateTokenPrice(
        address _tokenA,
        address _tokenB
    ) external whenNotPaused {
        require(
            block.timestamp >=
                lastCheckedPrice[_tokenA][_tokenB] + PRICE_CHECK_COOLDOWN,
            "Price can only be updated once per hour"
        );

        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = _tokenB;

        uint[] memory amounts = uniswapRouter.getAmountsOut(1e18, path);
        uint256 price = amounts[1];

        lastCheckedPrice[_tokenA][_tokenB] = block.timestamp;
        emit PriceUpdated(_tokenA, _tokenB, price);
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

    // Emergency pause functionality
    function pauseContract() external onlyOwner {
        paused = true;
        emit ContractPaused(msg.sender);
    }

    function unpauseContract() external onlyOwner {
        paused = false;
        emit ContractUnpaused(msg.sender);
    }

    // Governance function to update fee collector
    function updateFeeCollector(address _newFeeCollector) external onlyOwner {
        require(
            _newFeeCollector != address(0),
            "Invalid fee collector address"
        );
        feeCollector = _newFeeCollector;
        emit FeeCollectorUpdated(_newFeeCollector);
    }

    // Governance function to update fee percentage (requires governance token)
    function updateFeePercentage(uint256 _newFeePercentage) external {
        // Check governance token balance
        require(
            governanceToken.balanceOf(msg.sender) >= 1000 * 1e18,
            "Insufficient governance tokens"
        );

        // Add access control for fee updates
        require(
            msg.sender == owner() ||
                governanceToken.balanceOf(msg.sender) >= 10000 * 1e18,
            "Not authorized"
        );

        // Validate fee percentage
        require(_newFeePercentage <= 10, "Fee cannot exceed 1%");

        // Actual fee update logic
        FEE_PERCENTAGE = _newFeePercentage;
    }

    // Emergency withdraw in case of contract issues
    function emergencyWithdraw(address token) external nonReentrant {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No balance to withdraw");

        IERC20(token).safeTransfer(msg.sender, balance);

        emit EmergencyWithdraw(msg.sender, token, balance);
    }

    // View functions for transparency
    function getSupportedPairs() external view returns (TokenPair[] memory) {
        return supportedPairs;
    }

    function getStakingRewards(
        address _tokenA,
        address _tokenB
    ) external view returns (uint256) {
        return stakingRewards[_tokenA][_tokenB];
    }

    function getTokenPrice(
        address _tokenA,
        address _tokenB
    ) external view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = _tokenB;

        uint[] memory amounts = uniswapRouter.getAmountsOut(1e18, path);
        return amounts[1];
    }

    // Fallback function to receive ETH
    receive() external payable {}
}
