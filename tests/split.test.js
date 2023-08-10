// Right click on the script name and hit "Run" to execute
const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Split", function () {
  let Split;
  let split;
  let signers;
  beforeEach(async function () {
    Split = await ethers.getContractFactory("Split");
    split = await Split.deploy();
    await split.deployed();
    signers = await ethers.getSigners();
  })
  it("test constructor", async function () {
    console.log('split deployed at:'+ split.address)
  });
   it("test creating a group", async function () {
        const [owner, addr1, addr2] = signers;

        const members1 = [owner.address, addr2.address];
        const members2 = [owner.address, addr1.address];
        const info1 = ["First Group", "A description", "img1"];
        const info2 = ["Second Group", "A description", "img2"];
        const creator1 = owner;
        const creator1addr = owner.address;
        const creator2 = addr1; 
        const creator2addr = addr1.address; 


        // Create Groups
        expect(await split.createGroup(members1, info1))
            .to.emit(split, "GroupCreated").withArgs(1, creator1addr, info1);
        expect(await split.connect(creator2).createGroup(members2, info2))
            .to.emit(split, "GroupCreated").withArgs(1, creator2addr, info2);
        /**
         uint128 groupID, address creator, string[3] info
         */
        // Check group count
        expect(await split.groupCount()).to.equal(2);
        // Check Creators
        expect(await split.groups(1)).to.equal(creator1addr);
        expect(await split.groups(2)).to.equal(creator2addr);
        // Check Members
        expect(await split.groupMembers(1, owner.address)).to.equal(1);
        expect(await split.groupMembers(2, addr1.address)).to.equal(2);

        expect(await split.isMember(1, owner.address)).to.equal(true);

        // Look for members directly
        expect(await split.groupMemberHistorical(1, 0, 0)).to.equal(creator1addr);
        expect(await split.groupMemberHistorical(2, 0, 1)).to.equal(creator2addr);
        
        expect(await split.getMembersVersion(1)).to.equal(1);
        
        // Get entire member collection
        expect(await split.getGroupMembersHistorical(1, 1)).to.eql(members1);
        expect(await split.getGroupMembersHistorical(1, 1)).to.eql(members1);
        //A
  });
});