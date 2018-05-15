var TokenContract = artifacts.require("./TokenContract.sol");

module.exports = function(deployer) {
  deployer.deploy(TokenContract);
};
