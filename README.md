### Install

```
$ npm install -g truffle
```

### Quick Usage

For a default set of contracts and tests, run the following within an empty project directory:

```
$ truffle init
```

From there, you can run `truffle compile`, `truffle migrate` and `truffle test` to compile your contracts, deploy those contracts to the network, and run their associated unit tests.

Truffle comes bundled with a local development blockchain server that launches automatically when you invoke the commands  above. If you'd like to [configure a more advanced development environment](https://trufflesuite.com/docs/advanced/configuration) we recommend you install the blockchain server separately by running `npm install -g ganache-cli` at the command line.

+  [ganache-cli](https://github.com/trufflesuite/ganache-cli): a command-line version of Truffle's blockchain server.
+  [ganache](https://trufflesuite.com/ganache/): A GUI for the server that displays your transaction history and chain state.


### Documentation

Please see the [Official Truffle Documentation](https://trufflesuite.com/docs/) for guides, tips, and examples.

### Development

We welcome pull requests. To get started, just fork this repo, clone it locally, and run:

```shell
# Install
npm install -g yarn
yarn bootstrap

# Test
yarn test

# Adding dependencies to a package
cd packages/<truffle-package>
yarn add <npm-package> [--dev] # Use yarn
```
### Deployment

- Create contracts
- Edit migrations/deploy.js (specify constructor arguments if you have)
- Migration ``` $ truffle migrate --develop $network ``` 
- Verification
  - ``` npm install -D truffle-plugin-verify ```
  - ``` yarn add -D truffle-plugin-verify ```
  - Add the following to "module.exports" of truffle-config.js
  - plugins: [
    'truffle-plugin-verify'
      ]
- Add the following to "module.exports" of truffle-config.js (get your etherscan API key from etherscan.io)
  ```
  api_keys: {
    etherscan: 'MY_API_KEY'
  }
  ```
- ``` truffle migrate --network $network ```
- ``` truffle run verify StakingRewardsFactory --network $network ```
