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
    mapping(uint128 => mapping(address => bool)) public groupMembers;

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
        address creditor;
        uint32 yesCount;
        uint32 noCount;
        address[] debtors;
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
        address[] debtors,
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
    function isMember(uint128 _groupId, address member) public view returns (bool) {
        return groupMembers[_groupId][member];
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
        for (
            uint32 memberId = 1;
            memberId <= _groupMembers.length;
            memberId++
        ) {
            groupMembers[groupCount][_groupMembers[memberId - 1]] = true;
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
        // Check _debtors and _debts format
        require(_debtors.length == _debts.length, "The arrays must have the same size");
        for (uint256 pos = 0; pos < _debtors.length; pos++) {
            // Check that the sender is not one of the debtors
            require(_debtors[pos] != msg.sender, "You can't be a debtor in one of your expenses");
            // Check that all debtors are members in the group
            require(isMember(_groupId, _debtors[pos]), "All the debtors must be members of the group");
            // Check that all the debts are greater than 0 
            require(_debts[pos] > 0);
        }
        // Add the expense to the expense list
        groupExpenses[_groupId].push(
            Expense({
                status: Status.CREATED, //uint8
                creditor: msg.sender,
                yesCount: 0,
                noCount: 0,
                debtors: _debtors
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
        emit ExpenseCreated(_groupId, expensesId, _amount, msg.sender, _info, _debtors, _debts);
    }
}
