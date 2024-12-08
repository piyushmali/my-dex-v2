// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/extensions/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract ImprovedDex is AccessControlEnumerable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // Role definitions
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

    // Immutable router and factory
    IUniswapV2Router02 public immutable uniswapRouter;
    IUniswapV2Factory public immutable uniswapFactory;

    // Enhanced token information structure
    struct TokenInfo {
        bool isWhitelisted;
        uint256 securityScore;
        uint256 lastSecurityCheck;
    }

    // Advanced fee configuration
    struct FeeConfiguration {
        uint256 percentage;
        uint256 lastUpdateTimestamp;
        address feeCollector;
    }

    // Supported token pairs
    struct TokenPair {
        address tokenA;
        address tokenB;
        address pairAddress;
    }

    // Mappings with enhanced tracking
    mapping(address => TokenInfo) public tokenRegistry;
    mapping(address => mapping(address => uint256)) public liquidityProviders;
    mapping(address => mapping(address => uint256)) public stakingRewards;
    mapping(address => mapping(address => AggregatorV3Interface))
        public priceFeeds;
    mapping(address => mapping(address => uint256)) public lastCheckedPrice;

    // State variables
    FeeConfiguration public feeConfig;
    TokenPair[] public supportedPairs;
    IERC20 public governanceToken;
    bool public paused;

    // Constants
    uint256 public constant MAX_FEE_PERCENTAGE = 10; // 1% max fee
    uint256 public constant REWARD_RATE = 10; // 0.1% of liquidity as reward
    uint256 public constant PRICE_CHECK_COOLDOWN = 1 hours;
    uint256 public constant MIN_GOVERNANCE_TOKENS_FOR_UPDATE = 1000 * 1e18;
    uint256 public constant GOVERNANCE_TOKENS_FOR_FEE_UPDATE = 10000 * 1e18;

    // Comprehensive event logging
    event LiquidityAdded(
        address indexed provider,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );
    event LiquidityRemoved(
        address indexed provider,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event TokenWhitelistUpdated(
        address indexed token,
        bool status,
        uint256 securityScore,
        uint256 timestamp
    );
    event FeeConfigurationUpdated(
        uint256 newFeePercentage,
        address updatedBy,
        uint256 timestamp
    );
    event EmergencyWithdraw(
        address indexed user,
        address token,
        uint256 amount
    );

    // Modifiers
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    constructor(
        address _uniswapRouter,
        address _uniswapFactory,
        address _governanceToken,
        address _initialFeeCollector
    ) {
        // Initialize core components
        uniswapRouter = IUniswapV2Router02(_uniswapRouter);
        uniswapFactory = IUniswapV2Factory(_uniswapFactory);
        governanceToken = IERC20(_governanceToken);

        // Set initial fee configuration
        feeConfig = FeeConfiguration({
            percentage: 3, // 0.3% initial fee
            lastUpdateTimestamp: block.timestamp,
            feeCollector: _initialFeeCollector
        });

        // Setup roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GOVERNANCE_ROLE, msg.sender);
        _setupRole(EMERGENCY_ROLE, msg.sender);
    }

    // Enhanced token whitelisting with security scoring
    function whitelistToken(
        address _token,
        bool _status,
        uint256 _securityScore
    ) external onlyRole(GOVERNANCE_ROLE) {
        require(_securityScore <= 100, "Invalid security score");

        tokenRegistry[_token] = TokenInfo({
            isWhitelisted: _status,
            securityScore: _securityScore,
            lastSecurityCheck: block.timestamp
        });

        emit TokenWhitelistUpdated(
            _token,
            _status,
            _securityScore,
            block.timestamp
        );
    }

    // Advanced liquidity addition with enhanced tracking
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
        // Enhanced token validation
        require(
            tokenRegistry[_tokenA].isWhitelisted &&
                tokenRegistry[_tokenB].isWhitelisted,
            "Token not whitelisted or failed security check"
        );

        // Transfer and approval logic remains similar to original
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

        // Enhanced tracking with security score consideration
        liquidityProviders[_tokenA][_tokenB] += liquidity;
        uint256 rewardMultiplier = tokenRegistry[_tokenA].securityScore / 10;
        uint256 rewardAmount = (liquidity * REWARD_RATE * rewardMultiplier) /
            1000;
        stakingRewards[_tokenA][_tokenB] += rewardAmount;

        emit LiquidityAdded(
            msg.sender,
            _tokenA,
            _tokenB,
            amountA,
            amountB,
            liquidity
        );
        return (amountA, amountB, liquidity);
    }

    // Governance function with enhanced access control
    function updateFeeConfiguration(
        uint256 _newFeePercentage
    ) external onlyRole(GOVERNANCE_ROLE) {
        require(_newFeePercentage <= MAX_FEE_PERCENTAGE, "Exceeds max fee");
        require(
            block.timestamp >= feeConfig.lastUpdateTimestamp + 1 weeks,
            "Timelock period not elapsed"
        );

        // Require substantial governance token holdings
        require(
            governanceToken.balanceOf(msg.sender) >=
                GOVERNANCE_TOKENS_FOR_FEE_UPDATE,
            "Insufficient governance tokens"
        );

        feeConfig.percentage = _newFeePercentage;
        feeConfig.lastUpdateTimestamp = block.timestamp;

        emit FeeConfigurationUpdated(
            _newFeePercentage,
            msg.sender,
            block.timestamp
        );
    }

    // Enhanced emergency mechanisms
    function emergencyTokenRecovery(
        address _token,
        uint256 _amount
    ) external onlyRole(EMERGENCY_ROLE) nonReentrant {
        IERC20(_token).safeTransfer(msg.sender, _amount);

        emit EmergencyWithdraw(msg.sender, _token, _amount);
    }

    // Additional view and utility functions can be added as needed
}
