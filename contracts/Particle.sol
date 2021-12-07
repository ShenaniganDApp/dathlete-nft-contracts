// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Particle {
    uint256 constant MAX_UINT = type(uint256).max;
    mapping(address => mapping(address => uint256)) allowances;
    mapping(address => uint256) balances;
    address[] _approvedContracts;
    mapping(address => uint256) approvedContractIndexes;
    bytes32[1000] emptyMapSlots;
    address contractOwner;
    uint96 _totalSupply;

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initOwner) {
        setContractOwner(initOwner);
    }

    function name() external pure returns (string memory) {
        return "PRTCLE";
    }

    function symbol() external pure returns (string memory) {
        return "PRTCLE";
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        balance = balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        uint256 frombalances = balances[msg.sender];
        require(frombalances >= _value, "GHST: Not enough GHST to transfer");
        balances[msg.sender] = frombalances - _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        success = true;
    }

    function addApprovedContract(address _contract) external {
        require(contractOwner == msg.sender);
        require(approvedContractIndexes[_contract] == 0, "GHSTFacet: Approved contract already exists");
        _approvedContracts.push(_contract);
        approvedContractIndexes[_contract] = _approvedContracts.length;
    }

    function removeApprovedContract(address _contract) external {
        require(contractOwner == msg.sender);

        uint256 index = approvedContractIndexes[_contract];
        require(index > 0, "GHSTFacet: Approved contract does not exist");
        uint256 lastIndex = _approvedContracts.length;
        if (index != lastIndex) {
            address lastContract = _approvedContracts[lastIndex - 1];
            _approvedContracts[index - 1] = lastContract;
            approvedContractIndexes[lastContract] = index;
        }
        _approvedContracts.pop();
        delete approvedContractIndexes[_contract];
    }

    function approvedContracts() external view returns (address[] memory contracts_) {
        contracts_ = _approvedContracts;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        uint256 fromBalance = balances[_from];
        if (msg.sender == _from || approvedContractIndexes[msg.sender] > 0) {
            // pass
        } else {
            uint256 l_allowance = allowances[_from][msg.sender];
            require(l_allowance >= _value, "GHST: Not allowed to transfer");
            if (l_allowance != MAX_UINT) {
                allowances[_from][msg.sender] = l_allowance - _value;
                emit Approval(_from, msg.sender, l_allowance - _value);
            }
        }
        require(fromBalance >= _value, "GHST: Not enough GHST to transfer");
        balances[_from] = fromBalance - _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        success = true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        success = true;
    }

    function increaseAllowance(address _spender, uint256 _value) external returns (bool success) {
        uint256 l_allowance = allowances[msg.sender][_spender];
        uint256 newAllowance = l_allowance + _value;
        require(newAllowance >= l_allowance, "GHSTFacet: Allowance increase overflowed");
        allowances[msg.sender][_spender] = newAllowance;
        emit Approval(msg.sender, _spender, newAllowance);
        success = true;
    }

    function decreaseAllowance(address _spender, uint256 _value) external returns (bool success) {
        uint256 l_allowance = allowances[msg.sender][_spender];
        require(l_allowance >= _value, "GHSTFacet: Allowance decreased below 0");
        l_allowance -= _value;
        allowances[msg.sender][_spender] = l_allowance;
        emit Approval(msg.sender, _spender, l_allowance);
        success = true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining_) {
        remaining_ = allowances[_owner][_spender];
    }

    function mint() external {
        uint256 amount = 10000000e18;
        balances[msg.sender] += amount;
        _totalSupply += uint96(amount);
        emit Transfer(address(0), msg.sender, amount);
    }

    function mintTo(address _user) external {
        uint256 amount = 10000000e18;
        balances[_user] += amount;
        _totalSupply += uint96(amount);
        emit Transfer(address(0), _user, amount);
    }

    function setContractOwner(address _newOwner) internal {
        address previousOwner = contractOwner;
        contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function transferOwnership(address _newOwner) external {
        require(msg.sender == contractOwner, "LibDiamond: Must be contract owner");
        setContractOwner(_newOwner);
    }

    function owner() external view returns (address owner_) {
        owner_ = contractOwner;
    }
}
