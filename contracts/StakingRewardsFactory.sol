// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./IStakingRewards.sol";
import "./RewardsDistributionRecipient.sol";
import "./KeeperCompatibleInterface.sol";

contract StakingRewards is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuard, KeeperCompatibleInterface {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public _lockingTimeStamp;
    mapping(address => address) public checkUser;
    address[] public userList;

    uint256 private _actualtotalSupply; //  actual total amount staked
    uint256 private _totalSupply; // weight total Stake amount according to tier
    
    mapping(address => uint256) private _balances; // weight Stake amount
    mapping(address => uint256) private _actualbalances; // actual amount staked
    
    mapping(address => uint256) private _userLockPeriod; // user after 6 month timestamp
    mapping(address => uint256) private _userRewardLockPeriod; // user after 6 month timestamp
    
    uint public lastTimeStamp;
    
    /**
    * Public counter variable
    */
    uint public counter;
    
    uint public interval;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) public {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        
         interval = 300; //15 min chk interval
         lastTimeStamp = block.timestamp;

         counter = 0;
    }

    /* ========== VIEWS ========== */
    function userLockPeriod() external override view returns (uint256) {
        return _userLockPeriod[msg.sender];
    }

    function userRewardLockPeriod() external override view returns (uint256) {
        return _userRewardLockPeriod[msg.sender];
    }
    function totalSupply() external override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external override view returns (uint256) {
        return _balances[account];
    }

     function actualTotalSupply() external view returns (uint256) {
        return _actualtotalSupply;
    }

    function actualBalanceOf(address account) external view returns (uint256) {
        return _actualbalances[account];
    }

    function lastTimeRewardApplicable() public override view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public override view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
            );
    }

    function earned(address account) public override view returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stake(uint256 amount) external override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _actualtotalSupply = _actualtotalSupply.add(amount);
        _actualbalances[msg.sender] = _actualbalances[msg.sender].add(amount);
        
        if(_actualbalances[msg.sender] >= 3000000000) {
            _balances[msg.sender] = _balances[msg.sender].add(amount);
            _totalSupply = _totalSupply.add(amount);
        }
        else if(_actualbalances[msg.sender] >= 1500000000 && _actualbalances[msg.sender] < 3000000000){
            uint256 newamount = amount / 100 * 75;
            _balances[msg.sender] = _balances[msg.sender].add(newamount);
            _totalSupply = _totalSupply.add(newamount);
        } 
        else if(_actualbalances[msg.sender] >= 500000000 && _actualbalances[msg.sender] < 1500000000){
             uint256 newamount = amount / 100 * 63;
            _balances[msg.sender] = _balances[msg.sender].add(newamount);
            _totalSupply = _totalSupply.add(newamount);
        } 
        else if(_actualbalances[msg.sender] < 500000000){
             uint256 newamount = amount / 100 * 50;
            _balances[msg.sender] = _balances[msg.sender].add(newamount);
            _totalSupply = _totalSupply.add(newamount);
        }
        
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        
        // update at inital stake
        if(_userLockPeriod[msg.sender] < 1){
            _userLockPeriod[msg.sender] = block.timestamp + 3 minutes; // for withdraw locking
            _userRewardLockPeriod[msg.sender] = block.timestamp + 10 minutes; // for reward locking
         }
         
        emit Staked(msg.sender, amount);
    }
    
    function stakeComponding(address uaddress) internal nonReentrant updateReward(uaddress) {
       
        uint256 rewardAmt = earned(uaddress);
        require(rewardAmt > 0, "Cannot stake 0");
         if(earned(uaddress) > 0){
        _actualtotalSupply = _actualtotalSupply.add(rewardAmt);
        _actualbalances[uaddress] = _actualbalances[uaddress].add(rewardAmt);
        
        if(_actualbalances[uaddress] >= 3000000000) {
            _balances[uaddress] = _balances[uaddress].add(rewardAmt);
            _totalSupply = _totalSupply.add(rewardAmt);
        }
        else if(_actualbalances[uaddress] >= 1500000000 && _actualbalances[uaddress] < 3000000000){
            uint256 newamount = rewardAmt / 100 * 75;
            _balances[uaddress] = _balances[uaddress].add(newamount);
            _totalSupply = _totalSupply.add(newamount);
        } 
        else if(_actualbalances[uaddress] >= 500000000 && _actualbalances[uaddress] < 1500000000){
             uint256 newamount = rewardAmt / 100 * 63;
            _balances[uaddress] = _balances[uaddress].add(newamount);
            _totalSupply = _totalSupply.add(newamount);
        } 
        else if(_actualbalances[uaddress] < 500000000){
             uint256 newamount = rewardAmt / 100 * 50;
            _balances[uaddress] = _balances[uaddress].add(newamount);
            _totalSupply = _totalSupply.add(newamount);
        }
        
        // stakingToken.safeTransferFrom(uaddress, address(this), amount);
        
        // update at inital stake
        if(_userLockPeriod[uaddress] < 1){
            _userLockPeriod[uaddress] = block.timestamp + 3 minutes; // for withdraw locking
            _userRewardLockPeriod[uaddress] = block.timestamp + 3 minutes; // for reward locking
         }
         
          rewards[uaddress] = 0; // setting user reward to zero since its added to stake
          emit RewardPaid(uaddress, rewardAmt);
         
        emit Staked(uaddress, rewardAmt);
    }
    }

    function stakeTransferWithBalance(
            uint256 amount,
            address useraddress,
            uint256 lockingPeriod
        ) external nonReentrant updateReward(useraddress) {
        require(amount > 0, "Cannot stake 0");
        require(_balances[useraddress] <= 0, "Already staked by user");
            _actualtotalSupply = _actualtotalSupply.add(amount);
            _actualbalances[msg.sender] = _actualbalances[msg.sender].add(amount);
                        
        if(_actualbalances[useraddress] >= 3000000000) {
            _balances[useraddress] = _balances[useraddress].add(amount);
            _totalSupply = _totalSupply.add(amount);
        }
        else if(_actualbalances[useraddress] >= 1500000000 && _actualbalances[useraddress] < 3000000000){
            uint256 newamount = amount / 100 * 75;
            _balances[useraddress] = _balances[useraddress].add(newamount);
            _totalSupply = _totalSupply.add(newamount);
        } 
        else if(_actualbalances[useraddress] >= 500000000 && _actualbalances[useraddress] < 1500000000){
             uint256 newamount = amount / 100 * 63;
            _balances[useraddress] = _balances[useraddress].add(newamount);
            _totalSupply = _totalSupply.add(newamount);
        } 
        else if(_actualbalances[useraddress] < 500000000){
             uint256 newamount = amount / 100 * 50;
            _balances[useraddress] = _balances[useraddress].add(newamount);
            _totalSupply = _totalSupply.add(newamount);
        }

            _lockingTimeStamp[useraddress] = lockingPeriod; // setting user locking ts
            
            stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(useraddress, amount);
  }

    function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        require(block.timestamp > _userLockPeriod[msg.sender], "Cannot withdraw before 6 month from inital stake");
        require(block.timestamp >= _lockingTimeStamp[msg.sender], "Unable to withdraw in locking period");
        
        _actualtotalSupply = _actualtotalSupply.sub(amount);
        _actualbalances[msg.sender] = _actualbalances[msg.sender].sub(amount);
        
       // _totalSupply = _totalSupply.sub(amount);
        //_balances[msg.sender] = _balances[msg.sender].sub(amount);
        
        if(_actualbalances[msg.sender] >= 3000000000) {
            _totalSupply = _totalSupply.sub(amount);
            _balances[msg.sender] = _balances[msg.sender].sub(amount);
        }
        else if(_actualbalances[msg.sender] >= 1500000000 && _actualbalances[msg.sender] < 3000000000){
            uint256 newamount = amount / 100 * 75;
            _totalSupply = _totalSupply.sub(newamount);
            _balances[msg.sender] = _balances[msg.sender].sub(newamount);
        } 
        else if(_actualbalances[msg.sender] >= 500000000 && _actualbalances[msg.sender] < 1500000000){
             uint256 newamount = amount / 100 * 63;
            _totalSupply = _totalSupply.sub(newamount);
            _balances[msg.sender] = _balances[msg.sender].sub(newamount);
        } 
        else if(_actualbalances[msg.sender] < 500000000){
            uint256 newamount = amount / 100 * 50;
            _totalSupply = _totalSupply.sub(newamount);
            _balances[msg.sender] = _balances[msg.sender].sub(newamount);
        }
        
        
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public override nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
         require(block.timestamp > _userRewardLockPeriod[msg.sender], "Cannot withdraw before locking reward period");
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            _userRewardLockPeriod[msg.sender] = block.timestamp + 10 minutes; // reward lock timestamp
            emit RewardPaid(msg.sender, reward);
        }
    }

    function enrollComponding() public nonReentrant {
        require(_balances[msg.sender] > 0, "Not a staker");
        require(checkUser[msg.sender] != msg.sender, "Already added in compounding");
        
        checkUser[msg.sender]= msg.sender;
        userList.push(msg.sender);
    }
    
    function leaveComponding() public nonReentrant {
        require(_balances[msg.sender] > 0, "Not a staker");
        require(checkUser[msg.sender] == msg.sender, "Already added in compounding");
        
        for (uint i = 0; i < userList.length; i++) {
            if(userList[i] == msg.sender) {
            userList[i] = userList[userList.length - 1];
            checkUser[msg.sender]= address(0);
            userList.pop();
            break;
            }
        }
    }
    
    function exit() external override {
        withdraw(_actualbalances[msg.sender]);
        getReward();
    }
    
    function checkUpkeep(bytes calldata checkData) external override view returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;

        // We don't use the checkData in this example
        // checkData was defined when the Upkeep was registered
        performData = checkData;
    }

    function performUpkeep(bytes calldata performData) external override {
        lastTimeStamp = block.timestamp;
        counter = counter + 1;
        
         for (uint i = 0; i < userList.length; i++) {
             if(earned(userList[i]) > 0){
                 stakeComponding(userList[i]);
             }
        }
        // We don't use the performData in this example
        // performData is generated by the Keeper's call to your `checkUpkeep` function
        performData;
    }
        

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 reward, uint256 rewardsDuration) external override onlyRewardsDistribution updateReward(address(0)) {
        require(block.timestamp.add(rewardsDuration) >= periodFinish, "Cannot reduce existing period");
        
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward, periodFinish);
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward, uint256 periodFinish);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}
interface IUniswapV2ERC20 {
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
}

contract StakingRewardsFactory is Ownable {
    // immutables
    address public rewardsToken;
    uint public stakingRewardsGenesis;

    // the staking tokens for which the rewards contract has been deployed
    address[] public stakingTokens;

    // info about rewards for a particular staking token
    struct StakingRewardsInfo {
        address stakingRewards;
        uint rewardAmount;
        uint duration;
    }

    // rewards info by staking token
    mapping(address => StakingRewardsInfo) public stakingRewardsInfoByStakingToken;

    constructor(
        address _rewardsToken,
        uint _stakingRewardsGenesis
    ) Ownable() public {
        require(_stakingRewardsGenesis >= block.timestamp, 'StakingRewardsFactory::constructor: genesis too soon');

        rewardsToken = _rewardsToken;
        stakingRewardsGenesis = _stakingRewardsGenesis;
    }

    ///// permissioned functions

    // deploy a staking reward contract for the staking token, and store the reward amount
    // the reward will be distributed to the staking reward contract no sooner than the genesis
    function deploy(address stakingToken, uint rewardAmount, uint256 rewardsDuration) public onlyOwner {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        require(info.stakingRewards == address(0), 'StakingRewardsFactory::deploy: already deployed');

        info.stakingRewards = address(new StakingRewards(/*_rewardsDistribution=*/ address(this), rewardsToken, stakingToken));
        info.rewardAmount = rewardAmount;
        info.duration = rewardsDuration;
        stakingTokens.push(stakingToken);
    }

    function update(address stakingToken, uint rewardAmount, uint256 rewardsDuration) public onlyOwner {
        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        require(info.stakingRewards != address(0), 'StakingRewardsFactory::update: not deployed');

        info.rewardAmount = rewardAmount;
        info.duration = rewardsDuration;
    }



    ///// permissionless functions

    // call notifyRewardAmount for all staking tokens.
    function notifyRewardAmounts() public {
        require(stakingTokens.length > 0, 'StakingRewardsFactory::notifyRewardAmounts: called before any deploys');
        for (uint i = 0; i < stakingTokens.length; i++) {
            notifyRewardAmount(stakingTokens[i]);
        }
    }

    // notify reward amount for an individual staking token.
    // this is a fallback in case the notifyRewardAmounts costs too much gas to call for all contracts
    function notifyRewardAmount(address stakingToken) public {
        require(block.timestamp >= stakingRewardsGenesis, 'StakingRewardsFactory::notifyRewardAmount: not ready');

        StakingRewardsInfo storage info = stakingRewardsInfoByStakingToken[stakingToken];
        require(info.stakingRewards != address(0), 'StakingRewardsFactory::notifyRewardAmount: not deployed');

        if (info.rewardAmount > 0 && info.duration > 0) {
            uint rewardAmount = info.rewardAmount;
            uint256 duration = info.duration;
            info.rewardAmount = 0;
            info.duration = 0;

            require(
                IERC20(rewardsToken).transfer(info.stakingRewards, rewardAmount),
                'StakingRewardsFactory::notifyRewardAmount: transfer failed'
            );
            StakingRewards(info.stakingRewards).notifyRewardAmount(rewardAmount, duration);
        }
    }

    function pullExtraTokens(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }
    

}