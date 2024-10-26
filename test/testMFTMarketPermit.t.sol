// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/NFTMarket/NFTMarketPermit.sol";
import "../src/ERC20Token/MyToken.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

contract MockNFT is ERC721 {
    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to, uint tokenId) external {
        _mint(to, tokenId);
    }
}

contract NFTMarketTest is Test, EIP712("NFTMarket", "1") {
    using ECDSA for bytes32;

    NFTMarket public market;
    MyToken public payToken;
    MockNFT public nft;

    uint256 tokenId;
    uint256 price;

    uint256 internal ownerPrivateKey;
    uint256 internal buyerPrivateKey;
    address internal owner;
    address internal buyer;

    function setUp() public {
        // 设置测试账户
        ownerPrivateKey = 0xA11CE;
        buyerPrivateKey = 0xB0B;

        owner = vm.addr(ownerPrivateKey);
        buyer = vm.addr(buyerPrivateKey);
        
        // 部署合约
        payToken = new MyToken("MyToken", "MTK", 1000000);
        market = new NFTMarket(address(payToken));
        nft = new MockNFT();

        // 给buyer分配一些测试代币并授权市场合约
        payToken.transfer(buyer, 1000 * 10**payToken.decimals());
        vm.startPrank(buyer);
        payToken.approve(address(market), type(uint256).max);
        vm.stopPrank();

        // mint并上架NFT
        tokenId = 1;
        price = 100; // 设置购买价格
        nft.mint(owner, tokenId);
        vm.prank(owner);
        nft.approve(address(market), tokenId);
        // 在测试中模拟 NFT 拥有者的身份
        vm.startPrank(owner);
        market.list(address(nft), tokenId, price);
    }
    

    function testPermitBuy() public {
        uint256 deadline = block.timestamp + 1 hours;
        bytes32 PERMIT_TYPEHASH = keccak256(
            "Permit(address owner,address buyer,address nftAddress,uint256 tokenId,uint256 deadline)"
        );
        // 构造签名
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                buyer,
                address(nft),
                tokenId,
                deadline
                
            )
        );

        // bytes32 _hash = _hashTypedDataV4(structHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, structHash);

        // 调用 permitBuy
        vm.startPrank(buyer);
        market.permitBuy(owner, address(nft), tokenId, deadline, v, r, s, price);
        vm.stopPrank();

        // 断言测试
        assertEq(nft.ownerOf(tokenId), buyer, unicode"NFT成功转移给买家");
        assertEq(payToken.balanceOf(owner), price * 10**payToken.decimals(), unicode"token成功转移给卖家");
        assertEq(payToken.balanceOf(buyer), (1000 - price) * 10**payToken.decimals(), unicode"买家代币余额正确");
        
    }
}
