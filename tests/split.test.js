// Right click on the script name and hit "Run" to execute
const {expect} = require("chai")
const {ethers} = require("hardhat")

describe("Split", function () {
  let Split
  let split
  let signers

  beforeEach(async function () {
    Split = await ethers.getContractFactory("Split")
    split = await Split.deploy()
    await split.deployed()
    signers = await ethers.getSigners()
  })
  it("should create the contract", async function () {
    console.log("split deployed at:" + split.address)
  })

  describe("createGroup()", function () {
    async function data() {
      const [owner, addr1, addr2] = signers
      return {
        members1: [owner.address, addr2.address],
        members2: [owner.address, addr1.address],
        info1: ["First Group", "A description", "img1"],
        info2: ["Second Group", "A description", "img2"],
        creator1: owner,
        creator1addr: owner.address,
        creator2: addr1,
        creator2addr: addr1.address,
      }
    }
    async function createGroups() {
      const {members1, members2, info1, info2, creator2} = await data()
      await split.createGroup(members1, info1)
      await split.connect(creator2).createGroup(members2, info2)
    }
    it("should emit GroupCreated event", async function () {
      const {members1, members2, info1, info2, creator2, creator1addr, creator2addr} = await data()
      // Create Groups
      await expect(split.createGroup(members1, info1))
        .to.emit(split, "GroupCreated")
        .withArgs(1, creator1addr, info1)
      await expect(split.connect(creator2).createGroup(members2, info2))
        .to.emit(split, "GroupCreated")
        .withArgs(2, creator2addr, info2)
    })
    it("should increase the groupcount", async function () {
      expect(await split.groupCount()).to.equal(0)
      await createGroups()
      expect(await split.groupCount()).to.equal(2)
    })
    it("should store the msg sender as the creator", async function () {
      await createGroups()
      const {creator1addr, creator2addr} = await data()
      expect(await split.groups(1)).to.equal(creator1addr)
      expect(await split.groups(2)).to.equal(creator2addr)
    })
    it("should store the members selected", async function () {
      await createGroups()
      const [owner, addr1, addr2] = signers
      expect(await split.isMember(1, owner.address)).to.equal(true)
      expect(await split.isMember(1, addr1.address)).to.equal(false)
      expect(await split.isMember(1, addr2.address)).to.equal(true)
      expect(await split.isMember(2, owner.address)).to.equal(true)
      expect(await split.isMember(2, addr1.address)).to.equal(true)
      expect(await split.isMember(2, addr2.address)).to.equal(false)
    })
  })
  describe("addExpense()", function () {
    async function data() {
      const [owner, addr1, addr2] = signers
      return {
        members1: [owner.address, addr1.address, addr2.address],
        debtors1: [addr1.address, addr2.address],
        debtors2: [owner.address],
        debts1: [15, 7],
        debts2: [4],
        info1: ["First Expense", "A description", "img1"],
        info2: ["Second Expense", "A description", "img2"],
        creator1: owner,
        creator1addr: owner.address,
        creator2: addr1,
        creator2addr: addr1.address,
      }
    }

    async function addExpenses() {
      await split.createGroup(members1, info1)
      split.addExpense(1, debtors1, debts1, info1)
      split.connect(creator2).addExpense(1, debtors2, debts2, info2)
    }
    it("should emit ExpenseCreated", async function () {
      const {
        members1,
        debtors1,
        debtors2,
        debts1,
        debts2,
        info1,
        info2,
        creator2,
        creator1addr,
        creator2addr,
      } = await data()

      await split.createGroup(members1, info1)
      await expect(split.addExpense(1, debtors1, debts1, info1))
        .to.emit(split, "ExpenseCreated")
        .withArgs(1, 1, 22, creator1addr, info1, debtors1, debts1)
      await expect(split.connect(creator2).addExpense(1, debtors2, debts2, info2))
        .to.emit(split, "ExpenseCreated")
        .withArgs(1, 2, 4, creator2addr, info2, debtors2, debts2)
    })
    it("should add new expenses", async function () {})
  })
})
