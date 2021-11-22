const Migrations = artifacts.require("debtorProfile");
const Migrations = artifacts.require("Pawnshop");
const Migrations = artifacts.require("p2pLoan");
const Migrations = artifacts.require("TokenLockable");



module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(Migrations);
  deployer.deploy(Migrations);
  deployer.deploy(Migrations);
};
