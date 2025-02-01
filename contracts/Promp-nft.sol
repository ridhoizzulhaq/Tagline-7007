// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./interfaces/IAIOracle.sol";
import "./AIOracleCallbackReceiver.sol";
import "./IERC7007.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract Prompt is AIOracleCallbackReceiver {
    event PromptsUpdated(
        uint256 requestId,
        uint256 modelId,
        string input,
        string output,
        bytes callbackData
    );

    event PromptRequest(
        uint256 requestId,
        address sender, 
        uint256 modelId,
        string prompt
    );

    event MintedWithAI(
        address indexed to,
        uint256 indexed tokenId,
        bytes indexed prompt,
        bytes aigcData
    );

    event MintedWithURI(
        address indexed to,
        uint256 indexed tokenId,
        string uri
    );

    struct AIOracleRequest {
        address sender;
        uint256 modelId;
        bytes input;
        bytes output;
    }

    address public owner;
    IERC7007 public erc7007;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    mapping(uint256 => AIOracleRequest) public requests;
    mapping(uint256 => uint64) public callbackGasLimit;
    mapping(uint256 => mapping(string => string)) public prompts;

    constructor(IAIOracle _aiOracle, IERC7007 _erc7007) AIOracleCallbackReceiver(_aiOracle) {
        owner = msg.sender;
        erc7007 = _erc7007;
    }

    function setCallbackGasLimit(uint256 modelId, uint64 gasLimit) external onlyOwner {
        callbackGasLimit[modelId] = gasLimit;
    }

    function getAIResult(uint256 modelId, string calldata prompt) external view returns (string memory) {
        return prompts[modelId][prompt];
    }

    function aiOracleCallback(uint256 requestId, bytes calldata output, bytes calldata callbackData) external override onlyAIOracleCallback() {
        AIOracleRequest storage request = requests[requestId];
        require(request.sender != address(0), "Request not exists");
        request.output = output;
        prompts[request.modelId][string(request.input)] = string(output);
        emit PromptsUpdated(requestId, request.modelId, string(request.input), string(output), callbackData);
    }

    function estimateFee(uint256 modelId) public view returns (uint256) {
        return aiOracle.estimateFee(modelId, callbackGasLimit[modelId]);
    }

    function calculateAIResult(uint256 modelId, string calldata prompt) payable external {
        bytes memory input = bytes(prompt);
        uint256 requestId = aiOracle.requestCallback{value: msg.value}(
            modelId, input, address(this), callbackGasLimit[modelId], ""
        );

        AIOracleRequest storage request = requests[requestId];
        request.input = input;
        request.sender = msg.sender;
        request.modelId = modelId;
        emit PromptRequest(requestId, msg.sender, modelId, prompt);
    }

    function mintWithAIResult(uint256 requestId) external {
        AIOracleRequest storage request = requests[requestId];
        require(request.sender != address(0), "Request not exists");
        require(request.output.length > 0, "AI result not available");

        address to = request.sender;
        bytes memory promptBytes = request.input;
        bytes memory aigcDataBytes = request.output;

        string memory prompt = string(promptBytes);
        string memory aigcData = string(aigcDataBytes);

        // Metadata JSON creation sesuai dengan format yang diminta
        string memory metadata = string(
            abi.encodePacked(
                '{',
                '"title": "AIGC Metadata",',
                '"name": "ERC 7007 Text Based NFT",',
                '"description": "AI Generated Content",',
                '"image": "https://lavender-adorable-hummingbird-774.mypinata.cloud/ipfs/bafkreihygwww4gdwumpuwbni4zvfaa4g2rh5aangppxajh3kybxsrmguzy",',
                '"prompt": "', prompt, '",',
                '"aigc_type": "text",',
                '"aigc_data": "', aigcData, '",',
                '"proof_type": "opML"',
                '}'
            )
        );

        // Encode metadata to Base64
        string memory uri = string(
            abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(metadata)))
        );

        // Mint NFT dengan metadata yang sudah dibuat
        uint256 tokenId = erc7007.mint(to, promptBytes, aigcDataBytes, uri, "");

        emit MintedWithAI(to, tokenId, promptBytes, aigcDataBytes);
        emit MintedWithURI(to, tokenId, uri);
    }
}
