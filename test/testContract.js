const testContract = artifacts.require("StakingRewards");

contract('testContract', function(accounts) {
    it("Test gas", async () => {
      const test = await testContract.deployed();
  
      // Obtain gas used from the receipt
      const receipt = await test.enrollComponding();
      const gasUsed = receipt.receipt.gasUsed;
      console.log(`GasUsed: ${gasUsed}`);
  
      // Obtain gasPrice from the transaction
      const tx = await web3.eth.getTransaction(receipt.tx);
      const gasPrice = tx.gasPrice;
      console.log(`GasPrice: ${gasPrice}`);
    });
  });