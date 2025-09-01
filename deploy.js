#!/usr/bin/env node

// Simple deployment script for POMFlipHub contract
// This will be used with TON Playground for easy deployment

const fs = require('fs');
const path = require('path');

console.log('🚀 POM Flip Smart Contract Deployment');
console.log('=====================================');

// Check if contract file exists
const contractPath = path.join(__dirname, 'POMFlipHub.tact');
if (!fs.existsSync(contractPath)) {
    console.error('❌ POMFlipHub.tact not found!');
    process.exit(1);
}

console.log('✅ Contract file found');
console.log('📋 Next steps:');
console.log('1. Go to https://tact-playground.com/');
console.log('2. Copy the content of POMFlipHub.tact');
console.log('3. Compile the contract');
console.log('4. Deploy to TON testnet');
console.log('5. Copy the contract address');
console.log('6. Update ton-utils.js with the address');
console.log('');
console.log('📄 Contract content:');
console.log('===================');
console.log(fs.readFileSync(contractPath, 'utf8'));
