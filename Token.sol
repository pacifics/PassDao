pragma solidity ^0.4.2;

/*
Token contract with no "premine". Defines the functions to
check token balances, send tokens, send tokens on behalf of a 3rd party and the
corresponding approval process.
*/

contract Token {

    /* Array with all balances */
    mapping (address => uint256) balances;
    
    /* Array with all allowances */
    mapping (address => mapping (address => uint256)) allowed;

    /* Total amount of tokens */
    uint256 public totalSupply;

    /* Amount of decimals for token display purposes */
    uint8 public decimals;
 
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);

    /* Send coins */
    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value
            && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
           return false;
        }
    }

    /* A contract attempts to get the coins */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) returns (bool success) {
        if (balances[_from] >= _value
            && allowed[_from][msg.sender] >= _value
            && balances[_to] + _value > balances[_to]) {

            balances[_from] -= _value;
            balances[_to] += _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    /// its behalf
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Quantity of remaining tokens of _owner that _spender is allowed
    /// to spend
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
     function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
     }
     
}
