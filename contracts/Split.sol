//SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

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

    // TODO: Reeplace members version and member history with a list of debtors 
    // TODO: Remove history of members and replace it with a mapping mto manage access and array to keep track of all the addresses

    struct Expense {
        Status status; //uint8
        uint32 membersVersion;
        uint128 creditorID;
        uint32 yesCount;
        uint32 noCount;
    }

    // Maps: groupID => expenseID => memberId => vote
    mapping(uint128 =>  mapping (uint128 => mapping(address => bool))) votes;
    // Maps: groupID => expenseID => memberId => debt
    mapping(uint128 =>  mapping (uint128 => mapping(address => uint256))) debts;

    /**
     * Events
     **/
    event GroupCreated(uint128 groupID, address creator, string[3] info);

    event ExpenseCreated(
        uint128 groupId,
        uint128 expensesId,
        uint256 amount,
        address creator,
        string[3] info,
        uint[] debts
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

    function getGroupMembers(uint128 _groupId)
        public
        view
        returns (address[] memory)
    {
        return getGroupMembersHistorical(_groupId, getMembersVersion(_groupId));
    }

    function getExpenseMembers(uint128 _groupdId, uint128 _expenseId) external view returns (address [] memory) {
        uint expenseMembersVersion = groupExpenses[_groupdId][_expenseId - 1].membersVersion;
        return groupMemberHistorical[_groupdId][expenseMembersVersion - 1];

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
        require(_debtors.length == _debts.length, "The arrays must have the same size");

        // Add the expense to the expense list
        groupExpenses[_groupId].push(
            Expense({
                status: Status.CREATED, //uint8
                membersVersion: getMembersVersion(_groupId),
                creditorID: groupMembers[_groupId][msg.sender],
                yesCount: 0,
                noCount: 0
            })
        );
        // Add the debt for each member
        uint128 expensesId = uint128(groupExpenses[_groupId].length);
        uint256 _amount = 0;
        for (uint256 pos = 0; pos < _debtors.length; pos++) {
            uint256 debt = _debts[pos];
            _amount += debt;
            debts[_groupId][expensesId][_debtors[pos]] = debt;
        }

        // Create a new event
        emit ExpenseCreated(_groupId, expensesId, _amount, msg.sender, _info, _debts);
    }
}
