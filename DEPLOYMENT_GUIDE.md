# 🚀 POM Flip Smart Contract Deployment Guide

## 📋 Overview
This guide will help you deploy the POMFlipHub smart contract to TON testnet and integrate it with the frontend.

## 🛠️ Prerequisites
- TON wallet with testnet TON (get from https://testnet.toncenter.com/)
- Basic understanding of TON blockchain

## 📝 Step 1: Deploy Contract via TON Playground

### 1.1 Go to TON Playground
- Visit: https://tact-playground.com/
- This is the easiest way to compile and deploy Tact contracts

### 1.2 Copy Contract Code
- Open `POMFlipHub.tact` in your editor
- Copy the entire content
- Paste it into the TON Playground editor

### 1.3 Compile Contract
- Click "Compile" button
- Wait for compilation to complete
- If there are errors, fix them and recompile

### 1.4 Deploy to Testnet
- Click "Deploy" button
- Connect your TON wallet (Tonkeeper recommended)
- Set deployment parameters:
  - **Owner**: Your wallet address
  - **Treasury**: Your wallet address (for fees)
  - **FeeBps**: 200 (2% fee)
- Confirm deployment
- **IMPORTANT**: Copy the contract address!

## 🔧 Step 2: Update Frontend Configuration

### 2.1 Update ton-utils.js
Open `ton-utils.js` and update the contract address:

```javascript
// Replace this line:
const CONTRACT_ADDRESS = "YOUR_CONTRACT_ADDRESS_HERE";

// With your actual contract address:
const CONTRACT_ADDRESS = "EQD..."; // Your deployed contract address
```

### 2.2 Test Connection
- Open your deployed site
- Go to "PvP On-Chain" mode
- Click "Connect TON Wallet"
- Verify connection works

## 🧪 Step 3: Test On-Chain Functionality

### 3.1 Create a Match
- Set a small bet amount (0.01 TON)
- Click "Create Match"
- Confirm transaction in wallet
- Note the match ID

### 3.2 Join a Match
- Use a different wallet/browser
- Find the match in the list
- Click "Join Match"
- Confirm transaction

### 3.3 Play the Game
- Both players make their choice
- Both players reveal their seeds
- Check if the contract resolves correctly

## 🔍 Step 4: Verify Everything Works

### 4.1 Check Contract State
- Use TON testnet explorer to view your contract
- Verify matches are created correctly
- Check that funds are escrowed properly

### 4.2 Test Edge Cases
- Test match cancellation
- Test forfeit claims
- Test with different bet amounts

## 🚨 Troubleshooting

### Common Issues:

**1. "Contract not found" error**
- Double-check contract address in ton-utils.js
- Ensure contract is deployed on testnet

**2. "Insufficient funds" error**
- Make sure you have enough testnet TON
- Get more from https://testnet.toncenter.com/

**3. "Transaction failed" error**
- Check gas fees are sufficient
- Try increasing gas limit

**4. "Invalid operation" error**
- Verify contract is compiled correctly
- Check operation codes match

## 📊 Contract Details

### Operation Codes:
- `0x01`: Create Match
- `0x02`: Join Match  
- `0x03`: Reveal Seed
- `0x04`: Cancel Match
- `0x05`: Claim Forfeit

### Match States:
- `0`: Created
- `1`: Joined
- `2`: Revealing
- `3`: Resolved
- `4`: Cancelled

### Timeouts:
- Join: 5 minutes
- Reveal: 3 minutes

## 🎯 Next Steps After Deployment

1. **Test thoroughly** with small amounts
2. **Monitor contract** for any issues
3. **Update frontend** with any needed fixes
4. **Deploy to mainnet** when ready
5. **Add more features** (tournaments, etc.)

## 📞 Support

If you encounter issues:
1. Check TON testnet explorer
2. Verify contract state
3. Test with different wallets
4. Check browser console for errors

---

**Happy deploying! 🚀**
