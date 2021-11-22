const Migrations = artifacts.require(" ");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
};

