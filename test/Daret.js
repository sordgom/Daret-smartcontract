// test/Rosca.js
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Rosca contract", function () {
  let owner, feeAccount, member1, member2, member3, round1, round2, rosca;

  const MIN_CONTRIBUTION = ethers.utils.parseEther("1");
  const MAX_CONTRIBUTION = ethers.utils.parseEther("10");
  const MIN_ROUNDS = 2;
  const MAX_ROUNDS = 50;
  const FEE_PERCENTAGE = 1;
  const SECONDS_IN_DAY = 86400;
  const GRACE_PERIOD = 3 * SECONDS_IN_DAY;
  const MAX_ADMIN_FEE = 10;
  const MAX_WINNER_FEE = 2;

  before(async function () {
    [owner, feeAccount, member1, member2, member3] = await ethers.getSigners();
    const Rosca = await ethers.getContractFactory("Rosca");
    rosca = await Rosca.connect(owner).deploy(
      MAX_ROUNDS,
      3, // max members set to 3 for testing purposes
      FEE_PERCENTAGE,
      feeAccount.address
    );
    await rosca.deployed();
  });

  beforeEach(async function () {
    await rosca.connect(owner).startRound();
    round1 = await rosca.rounds(1);
    await rosca.connect(member1).joinRound({ value: MIN_CONTRIBUTION });
    await rosca.connect(member2).joinRound({ value: MIN_CONTRIBUTION });
    await rosca.connect(member3).joinRound({ value: MIN_CONTRIBUTION });
  });

  describe("constructor", function () {
    it("sets the max rounds, max members, fee percentage, and fee account", async function () {
      expect(await rosca.maxRounds()).to.equal(MAX_ROUNDS);
      expect(await rosca.maxMembers()).to.equal(3);
      expect(await rosca.currentFeePercentage()).to.equal(FEE_PERCENTAGE);
      expect(await rosca.feeAccount()).to.equal(feeAccount.address);
    });

    it("sets the contract state to Setup", async function () {
      expect(await rosca.state()).to.equal(0);
    });

    it("reverts if any of the input parameters are invalid", async function () {
      const Rosca = await ethers.getContractFactory("Rosca");
      await expect(Rosca.connect(owner).deploy(1, 2, 11, feeAccount.address)).to.be.revertedWith("Invalid fee percentage");
      await expect(Rosca.connect(owner).deploy(1, 51, 1, feeAccount.address)).to.be.revertedWith("Invalid number of members");
      await expect(Rosca.connect(owner).deploy(1, 2, 1, ethers.constants.AddressZero)).to.be.revertedWith("Invalid fee account");
    });
  });

  describe("startRound()", function () {
    it("Should not allow non-owner to start round", async function () {
      await expect(rosca.connect(alice).startRound()).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should not allow starting round with less than two participants", async function () {
      const Rosca = await ethers.getContractFactory("Rosca");
      const roscaWithOneParticipant = await Rosca.deploy(owner.address, 2, 100, [alice.address]);
      await roscaWithOneParticipant.deployed();

      await expect(roscaWithOneParticipant.startRound()).to.be.revertedWith("Insufficient number of participants");
    });

    it("Should not allow starting round with payment amount that is not a multiple of the number of participants", async function () {
      const Rosca = await ethers.getContractFactory("Rosca");
      const roscaWithWrongPaymentAmount = await Rosca.deploy(owner.address, 3, 100, [alice.address, bob.address, owner.address]);
      await roscaWithWrongPaymentAmount.deployed();

      await expect(roscaWithWrongPaymentAmount.startRound()).to.be.revertedWith("Payment amount is not a multiple of the number of participants");
    });

    it("Should start round with correct state", async function () {
      await rosca.startRound();

      expect(await rosca.currentRound()).to.equal(1);
      expect(await rosca.currentParticipant()).to.equal(0);
      expect(await rosca.totalPot()).to.equal(200);
      expect(await rosca.getBalance()).to.equal(0);
    });
  });
});