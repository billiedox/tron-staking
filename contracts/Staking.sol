// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Staking is Ownable {
  using SafeERC20 for IERC20;
  
  // Struct for staking information
  struct StakeInfo {
    uint256 stakedAmount;
    uint256 stakedAt;
    uint256 stakeEnd;
    uint256 rewards;
  }

  // Tokens to be staked
  IERC20 public USDT;
  IERC20 public WETH;
  IERC20 public WBTC;
  // Total stake amount for tokens
  mapping(address => uint256) public totalStakedAmount;
  // Reward rate for stakers who stake for 1 months between 1 and 100. (1 => 1%, 100 => 100%)
  uint256 rewardRateFor1 = 15; // 15%
  // Reward rate for stakers who stake for 6 months between 1 and 100. (1 => 1%, 100 => 100%)
  uint256 rewardRateFor6 = 24; // 24%
  // Reward rate for stakers who stake for 12 months between 1 and 100. (1 => 1%, 100 => 100%)
  uint256 rewardRateFor12 = 36; // 36%
  // stakerAddress => tokenAddress => StakeInfo
  mapping(address => mapping(address=>StakeInfo)) public userStakeInfos;

  event Staked(address indexed stakerAddress, address tokenAddress, uint256 amount);
  event Unstaked(address indexed stakerAddress, address tokenAddress, uint256 amount);
  event Withdrawn(address stakerAddress, address tokenAddress, uint256 amount);

  constructor(
    address _usdtAddress,
    address _wethAddress,
    address _wbtcAddress
  ) {
    USDT = IERC20(_usdtAddress);
    WETH = IERC20(_wethAddress);
    WBTC = IERC20(_wbtcAddress);
  }

  // @desc
  // function for stake ERC20 tokens. only accept USDT, WBTC and WETH. Staker address will be msg.sender
  // @params
  // address tokenAddress : address of token to be staked 
  // uint8 durationInMonths : 1, 6, 12
  // uint amount : amount of token to be staked
  function stake(
    address tokenAddress,
    uint8 durationInMonths,
    uint256 amount
  ) external {
    require(tokenAddress == address(USDT) || tokenAddress == address(WBTC) || tokenAddress == address(WETH), "Invalid token address");
    require(
      durationInMonths == 1 ||
      durationInMonths == 6 ||
      durationInMonths == 12,
      "Invalid staking duration"
    );
    require(userStakeInfos[msg.sender][tokenAddress].stakedAmount == 0, "You have already staked this token");
    IERC20(tokenAddress).safeTransferFrom(msg.sender, address(this), amount);
    _stake(msg.sender, tokenAddress, durationInMonths, amount);
  }

  // @desc
  // function for unstake tokens.
  // @params
  // address tokenAddress : address of staked token
  function unstake(
    address tokenAddress
  ) external {
    require(tokenAddress == address(USDT) || tokenAddress == address(WBTC) || tokenAddress == address(WETH), "Invalid token address");
    require(userStakeInfos[msg.sender][tokenAddress].stakedAmount > 0, "No staked token");
    uint256 currentTimestamp = block.timestamp;
    require(userStakeInfos[msg.sender][tokenAddress].stakeEnd >= currentTimestamp, "No time yet");
    _unstake(msg.sender, tokenAddress);
  }

  function withdraw(
    address tokenAddress,
    uint256 amount
  ) external onlyOwner {
    require(IERC20(tokenAddress).balanceOf(address(this)) >= amount, "Insufficient balance");
    IERC20(tokenAddress).safeTransfer(owner(), amount);
    emit Withdrawn(owner(), tokenAddress, amount);
  }

  function _stake(
    address stakerAddress,
    address tokenAddress,
    uint256 durationInMonths,
    uint256 amount
  ) internal {    
    uint256 currentTimestamp = block.timestamp;
    userStakeInfos[stakerAddress][tokenAddress].stakedAmount = amount;
    userStakeInfos[stakerAddress][tokenAddress].stakedAt = currentTimestamp;
    userStakeInfos[stakerAddress][tokenAddress].stakeEnd = currentTimestamp + (durationInMonths * 30 days);
    userStakeInfos[stakerAddress][tokenAddress].rewards = _calculateRewards(durationInMonths, amount);
    totalStakedAmount[tokenAddress] = totalStakedAmount[tokenAddress] + amount;
    emit Staked(stakerAddress, tokenAddress, amount);
  }

  function _unstake(
    address stakerAddress,
    address tokenAddress
  ) internal {
    uint256 amount = userStakeInfos[stakerAddress][tokenAddress].stakedAmount + userStakeInfos[stakerAddress][tokenAddress].rewards;
    require(amount >= IERC20(tokenAddress).balanceOf(address(this)), "Insufficient amount of token");
    IERC20(tokenAddress).safeTransfer(stakerAddress, amount);
    totalStakedAmount[tokenAddress] = totalStakedAmount[tokenAddress] - amount;
    emit Unstaked(stakerAddress, tokenAddress, amount);
  }

  function _calculateRewards(
    uint256 durationInMonths,
    uint256 amount
  ) internal view returns (uint256 rewards) {
    uint256 rewardRate;
    if (durationInMonths == 1) {
      rewardRate = rewardRateFor1;
    } else if (durationInMonths == 6) {
      rewardRate = rewardRateFor6;
    } else {
      rewardRate = rewardRateFor12;
    }
    rewards = amount * rewardRate / 100;
  }
}