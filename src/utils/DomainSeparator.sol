// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract DomainSeparator {
        // 定义 EIP-712 域信息
    address verifyContratAddress;
    string NAME;
    string VERSION;
    bytes32 public immutable DOMAIN_SEPARATOR = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    constructor(string memory name, string memory version, address _verifyContratAddress) {
        NAME = name;
        VERSION = version;
        verifyContratAddress = _verifyContratAddress;

        
    }

    function _buildDomainSeparator() internal view returns (bytes32) {
        return keccak256(
            abi.encode(
                domain_separator(),
                keccak256(bytes(NAME)),
                keccak256(bytes(VERSION)),
                block.chainid,
                verifyContratAddress
            )
        );
    }

    function domain_separator() public view returns (bytes32) {
        return DOMAIN_SEPARATOR;
    }

} 