const StakingRewardsFactory = artifacts.require("StakingRewardsFactory");

module.exports = function(deployer) {
  deployer.deploy(StakingRewardsFactory, '', ''); // reward token address and genesis block timestamp
};
