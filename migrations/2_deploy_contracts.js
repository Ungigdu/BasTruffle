const BasToken = artifacts.require("BasToken");
const BasOwnership = artifacts.require("BasOwnership");
const BasRule = artifacts.require("BasRule");
const BasAsset = artifacts.require("BasAsset");
const BasDNS = artifacts.require("BasDNS");
const BasMiner = artifacts.require("BasMiner");
const BasOANN = artifacts.require("BasOANN");
const BasMarket = artifacts.require("BasMarket");


module.exports = function(deployer,network,accounts) {
    //deploy BasToken
  deployer.deploy(BasToken).then(function(instance){
    t = instance;
    //deploy BasOwnership
    return deployer.deploy(BasOwnership)
  }).then(function(instance){
    o = instance;
    //deploy BasAsset
    return deployer.deploy(BasAsset,o.address);
  }).then(function(instance){
    a = instance;
    //deploy BasDNS
    return deployer.deploy(BasDNS,o.address);
  }).then(function(instance){
    d = instance;
    //deploy BasRule
    return deployer.deploy(BasRule);
  }).then(function(instance){
    r = instance;
    const admin = accounts[0];
    //deploy BasMiner
    return deployer.deploy(BasMiner,t.address,admin);
  }).then(function(instance){
    m = instance;
    //deploy BasOANN
    return deployer.deploy(BasOANN,t.address,o.address,a.address,d.address,m.address,r.address);
  }).then(function(instance){
    oann = instance;
    //deploy BasMarket
    return deployer.deploy(BasMarket,t.address,o.address);
  }).then(function(instance){
    market = instance;
  }).then(function(){
    o._a_changeContract(oann.address);
    m._a_changeContract(oann.address);
  })
};
