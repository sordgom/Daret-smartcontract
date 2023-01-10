const {time, loadFixture} = require("@nomicfoundation/hardhat-network-helpers");
const {anyValue} = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const {expect} = require("chai");
const hre = require("hardhat");

describe("DaretVault", function () {
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployFixture() { // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();

        const recurrence = 2592000; // 30 days in seconds
        const amount = 100;

        // Launch token contract from owner address
        const TOKEN = await ethers.getContractFactory("TestToken");
        const token = await TOKEN.connect(owner).deploy(); // 500 ether prob
        await token.deployed();
        // Launch vault contract from owner address
        const Vault = await ethers.getContractFactory("DaretVault");
        const vault = await Vault.connect(owner).deploy(
            recurrence,
            amount,
            [
                "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2",
                "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db"
            ],
            token.address,
            {gasLimit: 30000000}
        );

        // Transfer 100 ether to the vault
        await token.transfer(vault.address, 100000000000000000000n);
        // Transfer 10 ether to the other account
        await token.transfer(otherAccount.address, 10000000000000000000n);

        return {
            Vault,
            vault,
            recurrence,
            amount,
            owner,
            otherAccount,
            token
        };
    }
    // Make sure the token is deployed and has the total 500 ether
    describe("Token", function () {
        it("Owner address balance should be 390 eth", async function () {
            const {vault, token, owner} = await loadFixture(deployFixture);
            expect(await token.balanceOf(owner.address)).to.equal(390000000000000000000n);
        });
        it("Vault address balance should be 100eth+100000", async function () {
            const {vault, token} = await loadFixture(deployFixture);
            expect(await token.balanceOf(vault.address)).to.equal(100000000000001000000n);
        });
        it("OtherAccount address balance should be 10 eth", async function () {
            const {token, otherAccount} = await loadFixture(deployFixture);
            expect(await token.balanceOf(otherAccount.address)).to.equal(10000000000000000000n);
        });
    });

    // Check if daretVault deployed correctly
    describe("Deployment", function () {
        it("Should set the right recurrence time", async function () {
            const {vault, recurrence} = await loadFixture(deployFixture);
            expect(await vault.recurrence()).to.equal(recurrence);
        });
        it("Should get the right amount", async function () {
            const {vault, amount} = await loadFixture(deployFixture);
            expect(await vault.amount()).to.equal(amount);
        });
        it("Should get the right wallet", async function () {
            const {vault, otherAccount} = await loadFixture(deployFixture);
            expect(await vault.users(0)).to.equal(otherAccount.address);
        });
        it("Should get the right total", async function () {
            const {vault, amount} = await loadFixture(deployFixture);
            expect(await vault.total()).to.equal(amount);
        });
    });

    describe("Reward", function () {
        it("Check if the user's balance raised after getting the reward", async function () {
            const {Vault, vault, token, owner, otherAccount, amount} = await loadFixture(deployFixture);
            await vault.connect(owner).reward(otherAccount.address);

            expect(await token.balanceOf(otherAccount.address)).to.equal(amount);
        });
    })
})
