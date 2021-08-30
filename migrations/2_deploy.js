const StakingRewardsFactory = artifacts.require("StakingRewardsFactory");

module.exports = function (deployer) {
  deployer.deploy(
    StakingRewardsFactory,
    "0x973c43a98a5f400a708301fd78d49951b5c4187f",
    "1630335632"
  ); // reward token address and genesis block timestamp
};
