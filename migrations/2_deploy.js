const StakingRewardsFactory = artifacts.require("StakingRewardsFactory");

module.exports = function (deployer) {
  deployer.deploy(
    StakingRewardsFactory,
    "0xc813EA5e3b48BEbeedb796ab42A30C5599b01740",
    "1632755000"
  ); // reward token address and genesis block timestamp
};
