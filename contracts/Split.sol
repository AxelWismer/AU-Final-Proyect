//SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract Split {
    /**
     * Contract Data
     **/
    // Balances
    mapping(address => uint256) public balances;

    // Groups
    struct Group {
        address creator;
    }

    uint128 public groupCount;
    mapping(uint128 => Group) public groups;
    mapping(uint128 => mapping(address => uint128)) public groupMembers;
    mapping(uint128 => address[][]) public groupMemberHistorical;

    // Expenses
    enum Status {
        CREATED,
        DISPUTED,
        CANCELED,
        PAYED
    }

    struct Expense {
        Status status; //uint8
        uint32 membersVersion;
        uint128 creditorID;
        uint32 yesCount;
        uint32 noCount;
        uint256 amount;
    }

    mapping(uint256 => mapping(address => bool)) votes;
    mapping(uint256 => mapping(address => uint256)) debts;

    /**
     * Events
     **/
    event GroupCreated(uint128 groupID, address creator, string[3] info);

    event ExpenseCreated(
        uint128 groupId,
        uint128 expensesId,
        address creator,
        string[3] info
    );

    mapping(uint128 => Expense[]) groupExpenses;

    /**
     * Modifiers
     **/
    modifier onlyMember(uint128 _groupId) {
        require(
            isMember(_groupId, msg.sender),
            "You are not a member of the group"
        );
        _;
    }

    /**
     * Functions
     **/

    constructor() {}

    // Utilities
    function getExpensesUId(uint128 _groupId, uint128 _expensePosition)
        internal
        pure
        returns (uint256)
    {
        return uint256(_groupId)**128 + _expensePosition;
    }

    /**
     * View functions
     **/
    function getMembersVersion(uint128 _groupId) public view returns (uint32) {
        return uint32(groupMemberHistorical[_groupId].length);
    }

    function getGroupMembersHistorical(uint128 _groupId, uint256 _version)
        public
        view
        returns (address[] memory)
    {
        return groupMemberHistorical[_groupId][_version - 1];
    }

    function isMember(uint128 _groupId, address member) public view returns (bool) {
        return groupMembers[_groupId][member] > 0;
    }

    /**
     * Change state
     **/
    // Groups
    function createGroup(
        address[] calldata _groupMembers,
        string[3] calldata _info
    ) external {
        // Groups Id range from 1 to group count
        groupCount++;
        groups[groupCount] = Group(msg.sender);
        groupMemberHistorical[groupCount] = [_groupMembers];
        // Members Id range from 1 to members array length
        for (
            uint32 memberId = 1;
            memberId <= _groupMembers.length;
            memberId++
        ) {
            groupMembers[groupCount][_groupMembers[memberId - 1]] = memberId;
        }
        emit GroupCreated(groupCount, msg.sender, _info);
    }

    //Expenses
    function addExpense(
        uint128 _groupId,
        address[] calldata _debtors,
        uint256[] calldata _debts,
        string[3] calldata _info
    ) external onlyMember(_groupId) {
        require(_debtors.length == _debts.length);

        // Add the debt for each member
        uint128 expensesId = uint128(groupExpenses[_groupId].length);
        uint256 _amount = 0;
        uint256 expensesUId = getExpensesUId(_groupId, expensesId);
        for (uint256 pos = 0; pos < _debtors.length; pos++) {
            uint256 debt = _debts[pos];
            _amount += debt;
            debts[expensesUId][_debtors[pos]] = debt;
        }

        // Add the expense to the expense list
        groupExpenses[_groupId].push(
            Expense({
                status: Status.CREATED, //uint8
                membersVersion: getMembersVersion(_groupId),
                creditorID: groupMembers[_groupId][msg.sender],
                yesCount: 0,
                noCount: 0,
                amount: _amount
            })
        );

        // Create a new event
        emit ExpenseCreated(_groupId, expensesId, msg.sender, _info);
    }
}
