// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC7007.sol";

contract ERC7007 is ERC721URIStorage, Ownable, IERC7007 {
    uint256 private tokenCounter;

    struct TokenData {
        bytes prompt;
        bytes aigcData;
        bytes proof;
    }

    mapping(uint256 => TokenData) public tokenMetadata;

    constructor() ERC721("AI Generated Content NFT", "AIGCNFT") Ownable(msg.sender) {
        tokenCounter = 1; 
    }

    function mint(
        address to,
        bytes calldata prompt,
        bytes calldata aigcData,
        string calldata uri,
        bytes calldata proof
    ) external override returns (uint256 tokenId) {
        require(to != address(0), "Invalid address");

        tokenId = tokenCounter;
        _mint(to, tokenId);

        
        _setTokenURI(tokenId, uri);

        
        tokenMetadata[tokenId] = TokenData(prompt, aigcData, proof);

        emit Mint(to, tokenId, prompt, aigcData, uri, proof);

        tokenCounter++;
    }

    function verify(
        bytes calldata prompt,
        bytes calldata aigcData,
        bytes calldata proof
    ) external pure override returns (bool success) {
        return true; // Sementara validasi otomatis
    }
}
