// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {MyTokenPermit} from "../ERC20Token/MyTokenPermit.sol"; 
import {Test,console} from "forge-std/Test.sol";

contract TokenBank{
    mapping (address=>uint) public deposited;
    address public owner;
    MyTokenPermit public token;
    constructor (address _tokenAddress){
        owner = msg.sender;
        token = MyTokenPermit(_tokenAddress);

    }
    modifier onlyOwner(){
        require(owner==msg.sender, "only owner");
        _;
    }

    function deposit(uint amount) external virtual returns(bool){
        require(token.balanceOf(msg.sender) >= amount, "deposit amount exceeds balance");
        bool success = token.transferFrom(msg.sender, address(this), amount);
        require(success, "transferFrom Failed");
        deposited[msg.sender] += amount;
        return success;
    }

    function withdraw(uint amount) external virtual onlyOwner returns(bool){
        require(deposited[msg.sender]>=amount, "withdraw amount exceeds balance");
        token.transfer(msg.sender, amount);
        deposited[msg.sender] -= amount;
        return true;
    }

    function tokensReceived(address from, uint _value) external returns (bool) {
        // tokensReceived 中需要添加判断: 
        require(msg.sender == address(token) , "invald token sender");  
        deposited[from] += _value;
        return true;
    }

    // offline permit
    function permitDeposit(
        address _owner,
        uint _value,
        uint _deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint amountDeposit
    ) external returns(bool){
        console.log("bankADDRESS:",address(this));
        token.permit(_owner, address(this), _value, _deadline, v, r, s);
        require(token.allowance(_owner, address(this))>=amountDeposit, "insuficient");
        bool successDeposit =  token.transferFrom(_owner, address(this), _value);
        require(successDeposit, "successTransferFrom failed");
        deposited[msg.sender] += _value;
        return true;

    }
}


