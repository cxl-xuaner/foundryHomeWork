pragma solidity 0.8.10;

import {Test,console} from "forge-std/Test.sol";

contract Safe {
    receive() external payable {}

    function withdraw() external {
        console.log(msg.sender);
        payable(msg.sender).transfer(address(this).balance);
    }
}

contract SafeTest is Test {
    Safe safe;

    // Needed so the test contract itself can receive ether
    // when withdrawing
    receive() external payable {}

    function setUp() public {
        safe = new Safe();
    }

    function test_Withdraw() public {
        console.log(address(this));
        payable(address(safe)).transfer(1 ether);
        uint256 preBalance = address(this).balance;
        console.log(preBalance);
        safe.withdraw();

        uint256 postBalance = address(this).balance;
        console.log(postBalance);
        assertEq(preBalance + 1 ether, postBalance);
    }
}
