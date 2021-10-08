// const StakingRewards = artifacts.require("StakingRewards");
const BasicMetaTransaction = artifacts.require("BasicMetaTransaction");

module.exports = function (deployer) {
  // deployer.deploy(
  //   StakingRewards,
  //   "0xcE98Fa9EdBDc77e02c341456E119d3829AE40eBf",
  //   "0x973c43a98a5f400a708301fd78d49951b5c4187f",
  //   "0x973c43a98a5f400a708301fd78d49951b5c4187f"
  // ); // reward token address and genesis block timestamp
  deployer.deploy(
    BasicMetaTransaction
  );
};
