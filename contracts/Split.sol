//SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

contract Split {
  /**
   * Contract Data
   **/
  // Balances
  mapping(address => uint) public balances;

  // Groups
  struct Group {
    address creator;
  }

  uint public groupCount;
  mapping(uint => Group) public groups;
  mapping(uint => mapping(address => bool)) public groupMembers;

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
  }

  // Maps: groupID => expenseID => memberId => vote
  mapping(uint => mapping(uint => mapping(address => bool))) public votes;
  // Maps: groupID => expenseID => memberId => debt
  mapping(uint => mapping(uint => mapping(address => uint))) public debts;
  // Maps: groupID => expenseID => memberId => debtor
  mapping(uint => mapping(uint => address[])) public debtors;

  mapping(uint => Expense[]) groupExpenses;
  /**
   * Events
   **/
  event GroupCreated(uint groupID, address creator, string[3] info);

  event ExpenseCreated(
    uint groupId,
    uint expensesId,
    uint amount,
    address creator,
    string[3] info,
    address[] debtors,
    uint[] debts
  );


  /**
   * Modifiers
   **/
  modifier onlyMember(uint _groupId) {
    require(isMember(_groupId, msg.sender), "You are not a member of the group");
    _;
  }

  /**
   * Functions
   **/

  constructor() {}

  /**
   * View Functions
   **/
  function isMember(uint _groupId, address _member) public view returns (bool) {
    return groupMembers[_groupId][_member];
  }

  function getDebtors(uint _groupId, uint _expenseId) public view returns (address[] memory) {
    return debtors[_groupId][_expenseId];
  }

  function getExpense(uint _groupId, uint _expenseId) public view returns (Expense memory) {
    return groupExpenses[_groupId][_expenseId - 1];
  }

  function getExpenseCount(uint _groupId) public view returns (uint) {
    return groupExpenses[_groupId].length;
  }

  function getExpenses(uint _groupId) public view returns (Expense[] memory) {
    return groupExpenses[_groupId];
  }

  function getExpensesFrom(uint _groupId, uint _from) public view returns (Expense[] memory) {
    return getExpensesFromTo(_groupId, _from, getExpenseCount(_groupId));
  }

  function getLastExpenses(uint _groupId, uint _last) public view returns (Expense[] memory) {
    return getExpensesFromTo(_groupId, getExpenseCount(_groupId) - _last + 1 , getExpenseCount(_groupId));
  }

  function getExpensesFromTo(uint _groupId, uint _from, uint _to) public view returns (Expense[] memory) {
    require(_from >= 1, "From parameter must be at least 1");
    require(_from <= getExpenseCount(_groupId), "To parameter must be equal or less than the expese count");
    require(_from <= _to, "From parameter must be equal or less than To parameter");
    
    return this.sliceExpenses(_from, _to, groupExpenses[_groupId]);
  }

  // This functions allows to slice a memory array
  function sliceExpenses(uint _from, uint _to, Expense[] calldata expenses) public pure returns (Expense[] memory) {
    return expenses[_from - 1: _to];
  }



  
  /**
   * Change state
   **/
  // Groups
  function createGroup(address[] calldata _groupMembers, string[3] calldata _info) external {
    // Groups Id range from 1 to group count
    groupCount++;
    groups[groupCount] = Group(msg.sender);
    for (uint32 memberId = 1; memberId <= _groupMembers.length; memberId++) {
      groupMembers[groupCount][_groupMembers[memberId - 1]] = true;
    }
    emit GroupCreated(groupCount, msg.sender, _info);
  }

  //Expenses
  function addExpense(
    uint _groupId,
    address[] calldata _debtors,
    uint[] calldata _debts,
    string[3] calldata _info
  ) external onlyMember(_groupId) {
    // Check _debtors and _debts format
    require(_debtors.length == _debts.length, "The lists of debtors and debts must be of the same length");
    require(_debtors.length > 0, "You must record at least 1 debt");
    for (uint pos = 0; pos < _debtors.length; pos++) {
      // Check that the sender is not one of the debtors
      require(_debtors[pos] != msg.sender, "You can't be a debtor in one of your expenses");
      // Check that all debtors are members in the group
      require(isMember(_groupId, _debtors[pos]), "All the debtors must be members of the group");
      // Check that all the debts are greater than 0
      require(_debts[pos] > 0, "The amount of the debts must be greater than 0");
    }
    // Add the expense to the expense list
    groupExpenses[_groupId].push(
      Expense({
        status: Status.CREATED, //uint8
        creditor: msg.sender,
        yesCount: 0,
        noCount: 0
      })
    );
    uint expensesId = uint(groupExpenses[_groupId].length);
    
    // Add the debt for each member
    uint _amount = 0;
    for (uint pos = 0; pos < _debtors.length; pos++) {
      uint debt = _debts[pos];
      _amount += debt;
      debts[_groupId][expensesId][_debtors[pos]] = debt;
    }
    // Add debtors
    debtors[_groupId][expensesId] = _debtors;

    // Create a new event
    emit ExpenseCreated(_groupId, expensesId, _amount, msg.sender, _info, _debtors, _debts);
  }

  // Add pay method 
  // Add retieve method
  // Add dispute method (later)
}
