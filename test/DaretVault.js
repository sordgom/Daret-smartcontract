const {
    time,
    loadFixture,
  } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("DaretVault",function(){
     // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployFixture() {        

        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();
        
        const recurrence = 2592000 ; //30 days in seconds 
        const amount = 100 ; 

        //Launch token contract from owner address
        const TOKEN = await ethers.getContractFactory("TestToken");
        const token = await TOKEN.connect(owner).deploy();   // 1 prob    
        await token.deployed();

        //Launch vault contract from owner address
        const Vault = await ethers.getContractFactory("DaretVault");
        const vault = await Vault.connect(owner).deploy(recurrence,amount,otherAccount.address);

        await token.transfer(vault.address, 100000000000000000000n);
        
        return { Vault, vault, recurrence, amount, owner, otherAccount ,token};
      }
      //Make sure the token is deployed and has the total 500 ether 
    describe("Token",function(){
        it("Token contract balance should be 500",async function() {
            const { vault, token} = await loadFixture(deployFixture);
            expect(await token.totalSupply()).to.equal(500000000000000000000n);
        });
        it("Owner address's balance should be 500 eth too",async function() {
            const { vault, token, owner} = await loadFixture(deployFixture);
            expect(await token.balanceOf(owner.address)).to.equal(500000000000000000000n);
        });
    });

    //Check if daretVault deployed correctly
    describe("Deployment", function () {
        it("Should set the right recurrence time", async function () {
            const { vault, recurrence } = await loadFixture(deployFixture);
            expect(await vault.recurrence()).to.equal(recurrence);
        }); 
        it("Should get the right amount", async function () {
            const { vault, amount } = await loadFixture(deployFixture);
            expect(await vault.amount()).to.equal(amount);
        });   
        it("Balance should be 500 ether", async function () {
            const { vault, recurrence } = await loadFixture(deployFixture);
      
            expect(await vault.balance()).to.equal(0);
        }); 
    });

    describe("reward",function(){
        it("Check if the user's balance raised after getting the reward",async function(){
            const {vault, token,otherAccount, amount} =  await loadFixture(deployFixture);
            await vault.reward(otherAccount.address);
            expect(await token.balanceOf(otherAccount.address)).to.equal(amount);
            
        });
    })
})