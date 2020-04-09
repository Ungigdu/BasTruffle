// const MetaCoin = artifacts.require("MetaCoin");

// contract('MetaCoin', (accounts) => {
//   it('should put 10000 MetaCoin in the first account', async () => {
//     const metaCoinInstance = await MetaCoin.deployed();
//     const balance = await metaCoinInstance.getBalance.call(accounts[0]);

//     assert.equal(balance.valueOf(), 10000, "10000 wasn't in the first account");
//   });
//   it('should call a function that depends on a linked library', async () => {
//     const metaCoinInstance = await MetaCoin.deployed();
//     const metaCoinBalance = (await metaCoinInstance.getBalance.call(accounts[0])).toNumber();
//     const metaCoinEthBalance = (await metaCoinInstance.getBalanceInEth.call(accounts[0])).toNumber();

//     assert.equal(metaCoinEthBalance, 2 * metaCoinBalance, 'Library function returned unexpected function, linkage may be broken');
//   });
//   it('should send coin correctly', async () => {
//     const metaCoinInstance = await MetaCoin.deployed();

//     // Setup 2 accounts.
//     const accountOne = accounts[0];
//     const accountTwo = accounts[1];

//     // Get initial balances of first and second account.
//     const accountOneStartingBalance = (await metaCoinInstance.getBalance.call(accountOne)).toNumber();
//     const accountTwoStartingBalance = (await metaCoinInstance.getBalance.call(accountTwo)).toNumber();

//     // Make transaction from first account to second.
//     const amount = 10;
//     await metaCoinInstance.sendCoin(accountTwo, amount, { from: accountOne });

//     // Get balances of first and second account after the transactions.
//     const accountOneEndingBalance = (await metaCoinInstance.getBalance.call(accountOne)).toNumber();
//     const accountTwoEndingBalance = (await metaCoinInstance.getBalance.call(accountTwo)).toNumber();


//     assert.equal(accountOneEndingBalance, accountOneStartingBalance - amount, "Amount wasn't correctly taken from the sender");
//     assert.equal(accountTwoEndingBalance, accountTwoStartingBalance + amount, "Amount wasn't correctly sent to the receiver");
//   });
// });


const BasToken = artifacts.require("BasToken");
const BasOwnership = artifacts.require("BasOwnership");
const BasRule = artifacts.require("BasRule");
const BasAsset = artifacts.require("BasAsset");
const BasDNS = artifacts.require("BasDNS");
const BasMiner = artifacts.require("BasMiner");
const BasOANN = artifacts.require("BasOANN");
const BasMarket = artifacts.require("BasMarket");

//utils
function hash(str){
  return web3.utils.keccak256(str);
}

function ascii(str){
  if(str.length==0){
    return "0x00"
  }else{
    return str.split("").map(e=>e.charCodeAt()).reduce((a,b)=>a+b.toString(16),"0x");
  }
}

function ToString(ascii){
  charCode = [];
  for (i=2;i<ascii.length-1;i+=2){
      charCode.push("0x"+ascii[i]+ascii[i+1]);
  }
  return charCode.map((e)=>String.fromCharCode(e)).reduce((a,b)=>a+b);
}


contract("BasToken",(accounts)=>{
  it("check mint token amount", async () => {
    const Token = await BasToken.deployed();
    const TotalTokenForged = await Token.balanceOf(accounts[0]);

    console.log(hash("aaa"));
    assert.equal(TotalTokenForged.toString(), '420000000000000000000000000',"forge number mismatch");
  });

  






});