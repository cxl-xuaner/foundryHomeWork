// SPDX-License-Identifier:GPL-3.0
pragma solidity ^0.8.0;

// 实现ERC20 扩展 Token 所要求的接收者方法 tokensReceived  ，在 tokensReceived 中实现NFT 购买功能。
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "../ERC20Token/MyToken.sol";
import {Test, console} from "forge-std/Test.sol";

// import "hardhat/console.sol";
interface ITokenReceiver {
    function tokensReceived( 
        address buyer, 
        uint256 value, 
        bytes calldata data
    ) external returns(bool);
}


contract NFTMarket is IERC721Receiver, EIP712  {
    // using ECDSA for bytes32;
    address public admin;
    MyToken public payToken;
    mapping(address => mapping(uint => uint)) public listed; //nft address -> tokenid ->price
    mapping(address => mapping(uint => address)) public listedOwner; //nft address -> tokenid ->owner

    event _list(address indexed _from, address indexed _to, uint _tokenId);
    event _transfer(address indexed _from, address indexed _to, uint _tokenId);


    mapping(address => mapping(uint => uint)) public buyNonce; //nft address -> tokenid ->1

    // struct listedNft {
    //     uint tokenId;
    //     uint priceETH;
    // }

    constructor (address payTokenAddress) EIP712("NFTMarket", "1"){
        admin = msg.sender;
        payToken = MyToken(payTokenAddress);
    }
    //实现上架功能，NFT 持有者可以设定一个价格（需要多少个 Token 购买该 NFT）并上架 NFT 到 NFTMarket，上架之后，其他人才可以购买
    function list(address nftAddress, uint tokenId,  uint priceETH) external returns (bool) {
        // 1、验证调用者是否是该NFT的持有者
        address _owner = IERC721(nftAddress).ownerOf(tokenId);
        require(_owner == msg.sender, "not the owner");
        // 2、将检查是否获取授权
        bool isApproved = IERC721(nftAddress).getApproved(tokenId) == address(this) || IERC721(nftAddress).isApprovedForAll(msg.sender, address(this));
        require(isApproved, "not approved");
        // 3、检查是否已经重复上架
        require(listed[nftAddress][tokenId]==0 || listedOwner[nftAddress][tokenId]==address(0), "already listed");
        // 4、将用户 NFT转移到NFT市场
        IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId, "");
        // 5、更新listed 和listedOwner信息
        listed[nftAddress][tokenId] = priceETH;
        listedOwner[nftAddress][tokenId] = msg.sender;
        emit _list(msg.sender, address(this), tokenId);
        return true;

    }

    //普通的购买 NFT 功能，用户转入所定价的 ETH 数量，获得对应的 NFT
    function buyNFTbyETH(address nftAddress, uint tokenId) external payable returns (bool){
        // 1、查询NFT的价格
        uint priceETH = listed[nftAddress][tokenId];
        // 2、判断输入的价格是否满足要求
        require(msg.value / 1 ether == priceETH, "Insufficient amount");
        // 3、将资金转给卖家
        require(address(this).balance >= msg.value);
        address _owner = listedOwner[nftAddress][tokenId];
        (bool success,) = payable(_owner).call{value: msg.value}("");
        require(success, "transfer failed");
        // 4、将NFT发送给买家
        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId, "");
        // 5、更新listed 和 listedOwner信息
        delete listed[nftAddress][tokenId];
        delete listedOwner[nftAddress][tokenId];
        // listed[nftAddress][tokenId] = priceETH;
        // listedOwner[nftAddress][tokenId] = msg.sender;
        emit _transfer(address(this), msg.sender, tokenId);
        return true;

    }
    // 100000000000000000000
    // 0xB302F922B24420f3A3048ddDC4E2761CE37Ea098  NFTMarket
    // 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8  NFT
   //普通的购买 NFT 功能，用户转入所定价的 token 数量，获得对应的 NFT
   // 存在问题，执行报错：Error provided by the contract: ERC721InvalidApprover
    function buyNFTByToken(address nftAddress, uint tokenId, uint value) public returns (bool){
        // 1、数值单位转换和查询NFT的价格
        // uint priceToken = listed[nftAddress][tokenId];
        console.log("buyNFTByToken(NFTAddress, tokenId, tokenPrice);",msg.sender);
        uint8 _decimals = payToken.decimals();
        uint priceToken = listed[nftAddress][tokenId] * 10 ** uint(_decimals);
        uint _value = value * 10 ** uint(_decimals);
        // 2、判断购买者是否有足够的Token
        // uint balance = token.balanceOf(msg.sender); //单位是wei
        require(_value >=priceToken, "Insufficient value");
        // 3、将token转给卖家
        address _owner = listedOwner[nftAddress][tokenId];
        bool successPayToken = payToken.transferFrom(msg.sender, _owner, priceToken);
        require(successPayToken, "pay token failed");
        // 4、将NFT发送给买家
        IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId, "");
        // 5、更新listed 和 listedOwner信息
        delete listed[nftAddress][tokenId];
        delete listedOwner[nftAddress][tokenId];

        emit _transfer(address(this), msg.sender, tokenId);
        return true;
    }


    // //钩子函数
    // // to is NFTMarket
    // tokensReceived(msg.sender, _to, _value, data)
    // ITokenReceiver(_to).tokensReceived(NFTAddress, tokenId, _value, data)
    // tokensReceived(NFTAddress, tokenId, value, data);
    function tokensReceived(address buyer,  uint value, bytes calldata data) public returns (bool){
        (address nftAddress, uint tokenId) = abi.decode(data, (address, uint));
        require(msg.sender == address(payToken) , "invald payToken sender");  
        // 1、数值单位转换和查询NFT的价格
        uint8 _decimals = payToken.decimals();
        uint priceToken = listed[nftAddress][tokenId] * 10 ** uint(_decimals);
        uint _value = value * 10 ** uint(_decimals);
        // 2、判断购买者是否有足够的Token
        // uint balance = token.balanceOf(msg.sender); //单位是wei
        require(_value >= priceToken, "Insufficient value");
        // 3、将token转给卖家
        address _owner = listedOwner[nftAddress][tokenId];
        // 从NFT市场转给_owner
        bool successToOwner = payToken.transfer(_owner, priceToken);
        require(successToOwner,"tranfer failed to _owner");
        IERC721(nftAddress).safeTransferFrom(address(this), buyer, tokenId, "");
        // 5、更新listed 和 listedOwner信息
        delete listed[nftAddress][tokenId];
        delete listedOwner[nftAddress][tokenId];

        emit _transfer(address(this), buyer, tokenId);
        return true;

    }


    // 实现 onERC721Received 方法
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}

    function permitBuy(
        address owner,
        address NFTAddress,
        uint256 tokenId,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 tokenPrice
    ) external {

        bytes32 PERMIT_TYPEHASH = keccak256(
            "Permit(address owner,address buyer,address nftAddress,uint256 tokenId,uint256 deadline)"
        );
  
        require(block.timestamp < deadline, "Exceeding the expected time");
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                owner,
                msg.sender,
                NFTAddress,
                tokenId,
                deadline
                
            )
        );

        bytes32 _hash = _hashTypedDataV4(structHash); //注意需要同一个环境才能编译成功，调用测试时不能使用该方法生成hash数据        
        address signer = ECDSA.recover(_hash, v, r, s);
        require(signer == owner, "Invalid signature: Not whitelisted");
        buyNFTByToken(NFTAddress, tokenId, tokenPrice);
    }

}