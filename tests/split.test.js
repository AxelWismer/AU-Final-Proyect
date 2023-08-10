// Right click on the script name and hit "Run" to execute
const {expect} = require('chai')
const {ethers} = require('hardhat')

describe('Split', function () {
    let Split
    let split
    let signers
    beforeEach(async function () {
        Split = await ethers.getContractFactory('Split')
        split = await Split.deploy()
        await split.deployed()
        signers = await ethers.getSigners()
    })
    it('should create the contract', async function () {
        console.log('split deployed at:' + split.address)
    })
    it('should create a group', async function () {
        const [owner, addr1, addr2] = signers

        const members1 = [owner.address, addr2.address]
        const members2 = [owner.address, addr1.address]
        const info1 = ['First Group', 'A description', 'img1']
        const info2 = ['Second Group', 'A description', 'img2']
        const creator1 = owner
        const creator1addr = owner.address
        const creator2 = addr1
        const creator2addr = addr1.address

        // Create Groups
        await expect(split.createGroup(members1, info1))
            .to.emit(split, 'GroupCreated')
            .withArgs(1, creator1addr, info1)
        await expect(split.connect(creator2).createGroup(members2, info2))
            .to.emit(split, 'GroupCreated')
            .withArgs(2, creator2addr, info2)
        /**
         uint128 groupID, address creator, string[3] info
         */
        // Check group count
        expect(await split.groupCount()).to.equal(2)
        // Check Creators
        expect(await split.groups(1)).to.equal(creator1addr)
        expect(await split.groups(2)).to.equal(creator2addr)
        // Check Members
        expect(await split.groupMembers(1, owner.address)).to.equal(1)
        expect(await split.groupMembers(2, addr1.address)).to.equal(2)

        expect(await split.isMember(1, owner.address)).to.equal(true)

        // Look for members directly
        expect(await split.groupMemberHistorical(1, 0, 0)).to.equal(
            creator1addr
        )
        expect(await split.groupMemberHistorical(2, 0, 1)).to.equal(
            creator2addr
        )

        expect(await split.getMembersVersion(1)).to.equal(1)

        // Get entire member collection
        expect(await split.getGroupMembersHistorical(1, 1)).to.eql(members1)
        expect(await split.getGroupMembersHistorical(1, 1)).to.eql(members1)
    })
    it('should add new expenses', async function () {
        const [owner, addr1, addr2] = signers

        const members1 = [owner.address, addr1.address, addr2.address];
        const debtors1 = [addr1.address, addr2.address];
        const debtors2 = [owner.address];
        
        const debts1 = [15, 7];
        const debts2 = [4];

        const info1 = ['First Expense', 'A description', 'img1'];
        const info2 = ['Second Expense', 'A description', 'img2'];

        const creator1 = owner
        const creator1addr = owner.address
        const creator2 = addr1
        const creator2addr = addr1.address

        // Create Groups
        expect(await split.createGroup(members1, info1))
            .to.emit(split, 'GroupCreated')
            .withArgs(1, creator1addr, info1);
        
        // Create expenses
        await expect(split.addExpense(1, debtors1, debts1, info1))
          .to.emit(split, 'ExpenseCreated')
          .withArgs(1, 1, 22, creator1addr, info1, debts1);
        await expect(split.connect(creator2).addExpense(1, debtors2, debts2, info2))
          .to.emit(split, 'ExpenseCreated')
          .withArgs(1, 2, 4, creator2addr, info2, debts2);

          // Get expenses members
        expect(await split.getExpenseMembers(1, 1)).to.eql(members1);

    })
})
