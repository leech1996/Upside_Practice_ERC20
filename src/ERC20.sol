// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";

contract ERC20 is IERC20{
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
    bool public paused;
    address public owner;

    // fixed parameters
    bytes32 private immutable _DOMAIN_SEPARATOR;
    bytes32 private immutable _PERMIT_TYPEHASH;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;
    mapping(address => uint) public nonces;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        decimals = 18;
        totalSupply = 0;
        owner = msg.sender;
        paused = false;

        // initial supply
        mint(msg.sender, 1000 ether);

        _DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(name)),
                keccak256("1"),
                block.chainid,
                address(this)
            )
        );

        _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you're not owner");
        _;
    }

    modifier InPause() {
        require(paused, "sorry");
        _;
    }

    modifier notInPause() {
        require(!paused, "sorry");
        _;
    }

    function mint(address _to, uint256 _value) private onlyOwner {        
        totalSupply += _value;
        balances[_to] += _value;
    }

    function transfer(address _to, uint256 _value) public notInPause returns (bool success) {
        require(balances[msg.sender] >= _value, "not enough balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public notInPause returns (bool success) {
        require(allowances[_from][_to] >= 0, "not enough allowance");
        allowances[_from][_to] -= _value;
        balances[_from] -= _value;
        balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

    function permit(address _owner, address _spender, uint256 _value, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) public {

        require(block.timestamp <= _deadline, "too late");

        bytes32 _permitHashStruct = keccak256(
            abi.encode(
                _PERMIT_TYPEHASH,
                _owner,
                _spender,
                _value,
                nonces[_owner],
                _deadline
            )
        );

        bytes32 _permitTypedDataHash = _toTypedDataHash(_permitHashStruct);
        address recoveredOwner = ecrecover(_permitTypedDataHash, _v, _r, _s);

        if (recoveredOwner == address(0)) revert("INVALID_SIGNER");
        if (recoveredOwner != _owner) revert("INVALID_SIGNER");
        else{
            nonces[_owner] += 1;
            allowances[_owner][_spender] = _value;
            emit Approval(_owner, _spender, _value);
        }
    }

    function _toTypedDataHash (bytes32 _hashStruct) public returns (bytes32 _TypedDataHash){
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                _DOMAIN_SEPARATOR,
                _hashStruct
            )
        );
    }

    function pause() public onlyOwner{
        paused = true;
    }

    function resume() public onlyOwner{
        paused = false;
    }
}
