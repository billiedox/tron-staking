var Staking = artifacts.require("./Staking.sol");

module.exports = function(deployer) {
  const usdt_address = "TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t";
  const wbtc_address = "TXpw8XeWYeTUd4quDskoUqeQPowRh4jY65";
  const weth_address = "TNUC9Qb1rRpS5CbWLmNMxXBjyFoydXjWFR";
  deployer.deploy(Staking, usdt_address, wbtc_address, weth_address);
};
