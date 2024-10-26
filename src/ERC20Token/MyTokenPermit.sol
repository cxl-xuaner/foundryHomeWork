//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {Test,console} from "forge-std/Test.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
// import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

interface IERC777Recipient {
    function tokensReceived( // 允许 接收者 在接收代币时执行自定义逻辑 这个函数在 ERC777 代币合约调用 send 或 transfer 后自动触发，确保代币接收者可以处理接收到的代币
        address from,
        address to,
        uint256 amount
    ) external;
}

contract MyTokenPermit is ERC20{
    mapping(address=>uint) public nonces;
    
    
    constructor (
        string memory _name, 
        string memory _symbol,
        address to
    ) ERC20(_name, _symbol) {
        _mint(to, 1e18);

    
    }
    // isContract函数，判断地址是否为合约地址
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly { // 使用内联汇编检查地址的代码大小
            size := extcodesize(account) // 获取地址关联的代码大小，extcodesize可区分 合约地址>0 和 EOA=0
        }
        return  size > 0; // 如果代码大小大于0，则为合约地址
    }
    // deposit token to bank
    function transferWithCallback(address recipient, uint amount) external returns (bool)  {
        transferFrom(msg.sender, recipient, amount);
        // 检查接收者是否为合约
        if(isContract(recipient)) {
            IERC777Recipient(recipient).tokensReceived( msg.sender, recipient, amount);
        }
        return true;
    }

 function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        require(block.timestamp < deadline, "Exceeding the expected time");    //nonces[spender]++,  
        bytes32 PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 deadline)");
        // bytes32 structHash = keccak256(
        //     abi.encode(
        //         PERMIT_TYPEHASH, 
        //         owner, 
        //         spender, 
        //         value, 
        //         deadline
        //     )
        // );

        bytes32 structHash = keccak256(

            abi.encode(
                PERMIT_TYPEHASH, 
                owner, 
                spender, 
                value, 
                deadline
            )
        );


        address signer = ECDSA.recover(structHash, v, r, s);
        require(signer == owner, "ERC2612InvalidSigner");     
        _approve(owner, spender, value);
    }

    

}
