import React, { useState } from "react";
import Web3 from "web3";
import "bootstrap/dist/css/bootstrap.min.css";
import contractABI from "./abi/PromptABI.json";

const contractAddress = "0x0831b0B193FB2b771566c30bc65BAD8c9E62afa3";
const modelId = 11;

const App = () => {
  const [prompt, setPrompt] = useState("");
  const [web3, setWeb3] = useState(null);
  const [contract, setContract] = useState(null);
  const [account, setAccount] = useState(null);
  const [requestId, setRequestId] = useState(null);
  const [mintedData, setMintedData] = useState(null);

  const initWeb3 = async () => {
    if (window.ethereum) {
      const web3Instance = new Web3(window.ethereum);
      await window.ethereum.request({ method: "eth_requestAccounts" });
      const accounts = await web3Instance.eth.getAccounts();
      const contractInstance = new web3Instance.eth.Contract(contractABI, contractAddress);

      setWeb3(web3Instance);
      setContract(contractInstance);
      setAccount(accounts[0]);
    } else {
      alert("Metamask not detected!");
    }
  };

  const handleCalculateAIResult = async () => {
    if (!contract || !account) {
      alert("Please connect to Metamask first.");
      return;
    }
    try {
      const formattedPrompt = `(prompt no line format) one tagline about : ${prompt}`;
      const tx = await contract.methods.calculateAIResult(modelId, formattedPrompt).send({ from: account, value: "10170000000000000" });
      const event = tx.events.PromptRequest;
      if (event) {
        setRequestId(event.returnValues.requestId);
        alert(`AI Calculation Requested! Request ID: ${event.returnValues.requestId}`);
      }
    } catch (error) {
      console.error(error);
      alert("Transaction failed!");
    }
  };

  
  const handleMintWithAIResult = async () => {
    if (!contract || !account || !requestId) {
      alert("Request ID not found. Please generate AI result first.");
      return;
    }
  
    try {
      const tx = await contract.methods.mintWithAIResult(requestId).send({
        from: account,
        gas: 3000000, // Gas limit diatur ke 3.000.000
      });
  
      const mintedEvent = tx.events.MintedWithAI;
      const uriEvent = tx.events.MintedWithURI;
      if (mintedEvent && uriEvent) {
        const mintedDetails = {
          to: uriEvent.returnValues.to,
          tokenId: uriEvent.returnValues.tokenId,
          uri: uriEvent.returnValues.uri,
        };
        setMintedData(mintedDetails);
        alert(`NFT Minted! Token ID: ${mintedDetails.tokenId}`);
      }
    } catch (error) {
      console.error(error);
      alert("Minting failed!");
    }
  };
  

  return (
    <div className="container py-5">
      <div className="card shadow-lg p-4 mx-auto" style={{ maxWidth: "600px" }}>
        <h2 className="text-center mb-4">Tagline 7007</h2>
        <button className="btn btn-primary w-100 mb-3" onClick={initWeb3}>Connect Wallet</button>
        <div className="mb-3">
          <input
            type="text"
            className="form-control"
            placeholder="Enter your tagline topic..."
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
          />
        </div>
        <div className="d-grid gap-2">
          <button className="btn btn-success" onClick={handleCalculateAIResult}>Generate AI Result</button>
          <button className="btn btn-warning" onClick={handleMintWithAIResult} disabled={!requestId}>Mint NFT</button>
        </div>
        {mintedData && (
          <div className="mt-4 p-3 border rounded bg-light text-center">
            <h4>Minted NFT Details</h4>
            <p><strong>To:</strong> {mintedData.to}</p>
            <p><strong>Token ID:</strong> {mintedData.tokenId}</p>
            <p><strong>URI:</strong> <a href={mintedData.uri} target="_blank" rel="noopener noreferrer">{mintedData.uri}</a></p>
          </div>
        )}
      </div>
    </div>
  );
};

export default App;
