//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {MyTokenPermit} from "../src/ERC20Token/MyTokenPermit.sol";
import {TokenBank} from "../src/bank/TokenBankPermit.sol";
import "forge-std/Test.sol";

contract TokenBankTest is Test {
    MyTokenPermit internal token;
    TokenBank internal bank;
    // SigUtils internal sigUtils;

    uint256 internal ownerPrivateKey;
    uint256 internal spenderPrivateKey;

    address internal owner;
    address internal spender;

    function setUp() public {
        ownerPrivateKey = 0xA11CE;
        spenderPrivateKey = 0xB0B;

        owner = vm.addr(ownerPrivateKey);
        spender = vm.addr(spenderPrivateKey);

        token = new MyTokenPermit("Mock Token", "MTK", owner);
        bank = new TokenBank(address(token));
    }

    function testPermitDeposit() public {
        // 设定截止时间
        uint256 deadline = block.timestamp + 1 hours;
        // 获取当前 nonce
        // uint256 nonce = token.nonces(spender);
                // 调用 permitDeposit
        uint amountToDeposit = token.balanceOf(owner);
        console.log("amountToDeposit",amountToDeposit);
        // 生成 permitHash
        bytes32 permitHash = keccak256(
            
                // "\x19\x01",
                // token.DOMAIN_SEPARATOR(),
                
                    abi.encode(
                        keccak256("Permit(address owner,address spender,uint256 value,uint256 deadline)"),
                        owner,
                        address(bank),
                        amountToDeposit,
                        // nonce++,
                        deadline
                    )
                
            
        );

    //  bytes32 PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 deadline)");
    //     bytes32 structHash = keccak256(
    //         abi.encode(
    //             PERMIT_TYPEHASH, 
    //             owner, 
    //             spender, 
    //             value, 
    //             deadline
    //         )
    //     );





        console.log("test-bankADDRESS:",address(bank));
        console.log("test-permitHash", uint256(permitHash));

        // 使用当前调用者的私钥签名生成 (v, r, s)
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, permitHash); 


        vm.prank(spender); 
        bool success = bank.permitDeposit(owner, amountToDeposit, deadline, v, r, s, amountToDeposit);
        // 确保 permitDeposit 成功
        require(success, "permitDeposit failed");

        // 验证存款是否成功
        assertEq(token.balanceOf(address(bank)), amountToDeposit);
        assertEq(bank.deposited(spender), amountToDeposit); // 验证 owner 的余额
    }

}

