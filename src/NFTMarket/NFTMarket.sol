// // SPDX-License-Identifier:GPL-3.0
// pragma solidity ^0.8.0;

// // 实现ERC20 扩展 Token 所要求的接收者方法 tokensReceived  ，在 tokensReceived 中实现NFT 购买功能。
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
// import "@openzeppelin/contracts/access/Ownable.sol";
// import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
// import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
// // import "hardhat/console.sol";
// interface ITokenReceiver {
//     function tokensReceived( 
//         address buyer, 
//         uint256 value, 
//         bytes calldata data
//     ) external returns(bool);
// }

// //实现ERC20 扩展 Token 所要求的接收者方法 tokensReceived  ，在 tokensReceived 中实现NFT 购买功能。
// contract BaseERC20{
//     string public name; 
//     string public symbol; 
//     uint8 public decimals; 
//     uint256 public totalSupply; 
//     mapping (address => uint256) balances; 
//     mapping (address => mapping (address => uint256)) allowances; 
//     event Transfer(address indexed from, address indexed to, uint256 value);
//     event Approval(address indexed owner, address indexed spender, uint256 value);

//     constructor() {
//         // write your code here
//         // set name,symbol,decimals,totalSupply
//         name = "BaseERC20";
//         symbol = "BERC20";
//         decimals = 18;
//         totalSupply = 100000000 * 10 ** decimals;
//         balances[msg.sender] = totalSupply;  
//     }



//     function balanceOf(address _owner) public view returns (uint256 balance) {
//         // write your code here
//         return balances[_owner];

//     }

//     function transfer(address _to, uint256 _value) public returns (bool success) {
//         // write your code here
//         require(balances[msg.sender] >= _value,"ERC20: transfer amount exceeds balance");
//         balances[msg.sender] -= _value;
//         balances[_to] += _value;
//         emit Transfer(msg.sender, _to, _value);  
//         return true;   
//     }

//     function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
//         // write your code here
//         uint balances_amount = balances[_from];
//         require(_value <= balances_amount, "ERC20: transfer amount exceeds balance");
//         uint allowance_amount = allowances[_from][msg.sender];
//         require(_value <= allowance_amount, "ERC20: transfer amount exceeds allowance");
//         balances[_from] -= _value;
//         balances[_to] += _value;
//         allowances[_from][msg.sender] -= _value;
//         emit Transfer(_from, _to, _value); 
//         return true; 
//     }

//     function approve(address _spender, uint256 _value) public returns (bool success) {
//         // write your code here
//         allowances[msg.sender][_spender] = _value;
//         emit Approval(msg.sender, _spender, _value); 
//         return true; 
//     }

//     function allowance(address _owner, address _spender) public view returns (uint256 remaining) {   
//         // write your code here
//         return  allowances[_owner][_spender];

//     }

//     //判断address是否合约账户
//     function isContract(address _addr) public view returns (bool) {
//         return _addr.code.length > 0;
//     }

//     //带hook的transfer(EOA调用）
//     //问题1： 能否使用transferFrom
//     //问题2：ITokenReceiver(_to).tokensReceived(msg.sender, msg.sender, _to, _value, data)调用者为什么是token合约而不是EOA账户
//     // 0xcCbE7717e986CCb546E50d16143757Aff9CEd4e4
//     //实现NTF购买
//     // function tokensReceived(address from, address to, uint value, bytes calldata data) public returns (bool){
//     // (address nftAddress, uint tokenId) = abi.decode(data, (address, uint));
    
//     function transferWithCallback(address nftMarketAddress, address nftAddress, uint tokenId, uint256 value) public returns (bool success) {
//         uint _value = value * 10 ** uint(decimals);
//         success = transfer(nftMarketAddress, _value); 
//         if(success && isContract(nftMarketAddress)){    
//             bytes memory data = abi.encode(nftAddress, tokenId);
//             bool rv = ITokenReceiver(nftMarketAddress).tokensReceived(msg.sender, value, data);
//             require(rv, "no tokensReceived");
//         }
//         return success;
//     }


// }

// // TestSender合约地址：0x96Ac225AcfEeeB7628DF5d46Ae60ff23437a1605

// // contract TestSender {
// //     BaseERC20 public payToken;
// //     constructor(address tokenAddress){
// //         payToken = BaseERC20(tokenAddress);

// //     }

// //     function tokensReceived(address operatotr, address buyer, address to, uint value, bytes calldata data) public returns (bool){
// //         require(msg.sender == address(payToken) , "invald payToken sender");  
// //         return true;
// //     }
// //     function test(uint value) public returns (bool){
// //         bytes memory data = abi.encode(msg.sender);
// //         payToken.transferWithCallback(address(this), value, data);

// //     }
// // }


// contract MyNFT is ERC721URIStorage, Ownable {
//     uint256 public tokenCounter;
//     // 需要显式传递初始所有者
//     constructor(string memory name, string memory symbol) ERC721(name, symbol) Ownable(msg.sender) {
//         tokenCounter = 0;
//     }

//     function createNFT(string memory tokenURI) public onlyOwner returns (uint256) {
//         uint256 newItemId = tokenCounter;
//         _safeMint(msg.sender, newItemId); // 安全铸造新 NFT
//         _setTokenURI(newItemId, tokenURI); // 设置 token 的元数据 URI
//         tokenCounter++;
//         return newItemId;
//     }

  
// }

// contract NFTMarket is IERC721Receiver, EIP712  {
//     // using ECDSA for bytes32;
//     address public admin;
//     BaseERC20 public payToken;
//     mapping(address => mapping(uint => uint)) public listed; //nft address -> tokenid ->price
//     mapping(address => mapping(uint => address)) public listedOwner; //nft address -> tokenid ->owner

//     event _list(address indexed _from, address indexed _to, uint _tokenId);
//     event _transfer(address indexed _from, address indexed _to, uint _tokenId);

//     // struct listedNft {
//     //     uint tokenId;
//     //     uint priceETH;
//     // }

//     constructor (address payTokenAddress) EIP712("NFTMarket", "1"){
//         admin = msg.sender;
//         payToken = BaseERC20(payTokenAddress);
//     }
//     //实现上架功能，NFT 持有者可以设定一个价格（需要多少个 Token 购买该 NFT）并上架 NFT 到 NFTMarket，上架之后，其他人才可以购买
//     function list(address nftAddress, uint tokenId,  uint priceETH) external returns (bool) {
//         // 1、验证调用者是否是该NFT的持有者
//         address _owner = IERC721(nftAddress).ownerOf(tokenId);
//         require(_owner == msg.sender, "not the owner");
//         // 2、将检查是否获取授权
//         bool isApproved = IERC721(nftAddress).getApproved(tokenId) == address(this) || IERC721(nftAddress).isApprovedForAll(msg.sender, address(this));
//         require(isApproved, "not approved");
//         // 3、检查是否已经重复上架
//         require(listed[nftAddress][tokenId]==0 || listedOwner[nftAddress][tokenId]==address(0), "already listed");
//         // 4、将用户 NFT转移到NFT市场
//         IERC721(nftAddress).safeTransferFrom(msg.sender, address(this), tokenId, "");
//         // 5、更新listed 和listedOwner信息
//         listed[nftAddress][tokenId] = priceETH;
//         listedOwner[nftAddress][tokenId] = msg.sender;
//         emit _list(msg.sender, address(this), tokenId);
//         return true;

//     }

//     //普通的购买 NFT 功能，用户转入所定价的 ETH 数量，获得对应的 NFT
//     function buyNFTbyETH(address nftAddress, uint tokenId) external payable returns (bool){
//         // 1、查询NFT的价格
//         uint priceETH = listed[nftAddress][tokenId];
//         // 2、判断输入的价格是否满足要求
//         require(msg.value / 1 ether == priceETH, "Insufficient amount");
//         // 3、将资金转给卖家
//         require(address(this).balance >= msg.value);
//         address _owner = listedOwner[nftAddress][tokenId];
//         (bool success,) = payable(_owner).call{value: msg.value}("");
//         require(success, "transfer failed");
//         // 4、将NFT发送给买家
//         IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId, "");
//         // 5、更新listed 和 listedOwner信息
//         delete listed[nftAddress][tokenId];
//         delete listedOwner[nftAddress][tokenId];
//         // listed[nftAddress][tokenId] = priceETH;
//         // listedOwner[nftAddress][tokenId] = msg.sender;
//         emit _transfer(address(this), msg.sender, tokenId);
//         return true;

//     }
//     // 100000000000000000000
//     // 0xB302F922B24420f3A3048ddDC4E2761CE37Ea098  NFTMarket
//     // 0xd8b934580fcE35a11B58C6D73aDeE468a2833fa8  NFT
//    //普通的购买 NFT 功能，用户转入所定价的 token 数量，获得对应的 NFT
//    // 存在问题，执行报错：Error provided by the contract: ERC721InvalidApprover
//     function buyNFTByToken(address nftAddress, uint tokenId, uint value) public returns (bool){
//         // 1、数值单位转换和查询NFT的价格
//         // uint priceToken = listed[nftAddress][tokenId];

//         uint8 _decimals = payToken.decimals();
//         uint priceToken = listed[nftAddress][tokenId] * 10 ** uint(_decimals);
//         uint _value = value * 10 ** uint(_decimals);
//         // 2、判断购买者是否有足够的Token
//         // uint balance = token.balanceOf(msg.sender); //单位是wei
//         require(_value >=priceToken, "Insufficient value");
//         // 3、将token转给卖家
//         address _owner = listedOwner[nftAddress][tokenId];
//         bool successPayToken = payToken.transferFrom(msg.sender, _owner, priceToken);
//         require(successPayToken, "pay token failed");
//         // 4、将NFT发送给买家
//         IERC721(nftAddress).safeTransferFrom(address(this), msg.sender, tokenId, "");
//         // 5、更新listed 和 listedOwner信息
//         delete listed[nftAddress][tokenId];
//         delete listedOwner[nftAddress][tokenId];

//         emit _transfer(address(this), msg.sender, tokenId);
//         return true;
//     }


//     // //钩子函数
//     // // to is NFTMarket
//     // tokensReceived(msg.sender, _to, _value, data)
//     // ITokenReceiver(_to).tokensReceived(NFTAddress, tokenId, _value, data)
//     // tokensReceived(NFTAddress, tokenId, value, data);
//     function tokensReceived(address buyer,  uint value, bytes calldata data) public returns (bool){
//         (address nftAddress, uint tokenId) = abi.decode(data, (address, uint));
//         require(msg.sender == address(payToken) , "invald payToken sender");  
//         // 1、数值单位转换和查询NFT的价格
//         uint8 _decimals = payToken.decimals();
//         uint priceToken = listed[nftAddress][tokenId] * 10 ** uint(_decimals);
//         uint _value = value * 10 ** uint(_decimals);
//         // 2、判断购买者是否有足够的Token
//         // uint balance = token.balanceOf(msg.sender); //单位是wei
//         require(_value >= priceToken, "Insufficient value");
//         // 3、将token转给卖家
//         address _owner = listedOwner[nftAddress][tokenId];
//         // 从NFT市场转给_owner
//         bool successToOwner = payToken.transfer(_owner, priceToken);
//         require(successToOwner,"tranfer failed to _owner");
//         IERC721(nftAddress).safeTransferFrom(address(this), buyer, tokenId, "");
//         // 5、更新listed 和 listedOwner信息
//         delete listed[nftAddress][tokenId];
//         delete listedOwner[nftAddress][tokenId];

//         emit _transfer(address(this), buyer, tokenId);
//         return true;

//     }


//     // 实现 onERC721Received 方法
//     function onERC721Received(
//         address operator,
//         address from,
//         uint256 tokenId,
//         bytes calldata data
//     ) external pure override returns (bytes4) {
//         return IERC721Receiver.onERC721Received.selector;
//     }

//     receive() external payable {}

//     bytes32 private constant PERMIT_TYPEHASH = keccak256(
//         "Permit(address owner, address buyer, address nftAddress, uint256 tokenId, uint deadline, uint buyNonce)"
//     );
//     mapping(address => mapping(uint => uint)) public buyNonce; //nft address -> tokenid ->1

//     function permitBuy(
//         address owner,
//         address NFTAddress,
//         uint256 tokenId,
//         uint256 deadline,
//         uint8 v,
//         bytes32 r,
//         bytes32 s,
//         uint256 tokenPrice
//     ) external {
//         require(block.timestamp > deadline, "Exceeding the expected time");
//         bytes32 structHash = keccak256(
//             abi.encode(
//                 PERMIT_TYPEHASH,
//                 owner,
//                 msg.sender,
//                 NFTAddress,
//                 tokenId,
//                 deadline,
//                 buyNonce[NFTAddress][tokenId] ++
//             )
//         );
//         bytes32 hash = _hashTypedDataV4(structHash);
//         address signer = ECDSA.recover(hash, v, r, s);
//         require(signer == owner, "Invalid signature: Not whitelisted");
//         buyNFTByToken(NFTAddress, tokenId, tokenPrice);
//     }

// }