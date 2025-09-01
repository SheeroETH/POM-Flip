// ton-utils.js - Utilities for TON blockchain interaction
import { Cell, beginCell, Address } from '@ton/core';
import { TonConnectUI } from '@tonconnect/ui';

// Contract configuration
const CONTRACT_ADDRESS = "EQD..."; // Will be set after deployment
const OP_CREATE = 1;
const OP_JOIN = 2;
const OP_REVEAL = 3;
const OP_CANCEL = 4;
const OP_CLAIM_FORFEIT = 5;

// Initialize TonConnect
const tonConnectUI = new TonConnectUI({
    manifestUrl: './tonconnect-manifest.json'
});

// Generate random seed (32 bytes)
export function generateSeed() {
    const array = new Uint8Array(32);
    crypto.getRandomValues(array);
    return array;
}

// Calculate SHA256 hash of seed
export async function calculateCommit(seed) {
    const hashBuffer = await crypto.subtle.digest('SHA-256', seed);
    return new Uint8Array(hashBuffer);
}

// Build CREATE transaction payload
export function buildCreatePayload(betAmount, commit1) {
    const cell = beginCell()
        .storeUint(OP_CREATE, 32)
        .storeCoins(betAmount)
        .storeRef(beginCell().storeBuffer(commit1).endCell())
        .endCell();
    
    return cell.toBoc().toString('base64');
}

// Build JOIN transaction payload
export function buildJoinPayload(matchId, commit2) {
    const cell = beginCell()
        .storeUint(OP_JOIN, 32)
        .storeUint(matchId, 64)
        .storeRef(beginCell().storeBuffer(commit2).endCell())
        .endCell();
    
    return cell.toBoc().toString('base64');
}

// Build REVEAL transaction payload
export function buildRevealPayload(matchId, seed) {
    const cell = beginCell()
        .storeUint(OP_REVEAL, 32)
        .storeUint(matchId, 64)
        .storeRef(beginCell().storeBuffer(seed).endCell())
        .endCell();
    
    return cell.toBoc().toString('base64');
}

// Build CANCEL transaction payload
export function buildCancelPayload(matchId) {
    const cell = beginCell()
        .storeUint(OP_CANCEL, 32)
        .storeUint(matchId, 64)
        .endCell();
    
    return cell.toBoc().toString('base64');
}

// Build CLAIM_FORFEIT transaction payload
export function buildClaimForfeitPayload(matchId) {
    const cell = beginCell()
        .storeUint(OP_CLAIM_FORFEIT, 32)
        .storeUint(matchId, 64)
        .endCell();
    
    return cell.toBoc().toString('base64');
}

// Send transaction via TonConnect
export async function sendTransaction(address, amount, payload) {
    try {
        const transaction = {
            validUntil: Math.floor(Date.now() / 1000) + 300, // 5 minutes
            messages: [{
                address: address,
                amount: amount.toString(),
                payload: payload
            }]
        };
        
        const result = await tonConnectUI.sendTransaction(transaction);
        return result;
    } catch (error) {
        console.error('Transaction failed:', error);
        throw error;
    }
}

// Create a new match
export async function createMatch(betAmount) {
    const seed = generateSeed();
    const commit = await calculateCommit(seed);
    
    // Store seed locally for later reveal
    localStorage.setItem(`seed_${Date.now()}`, JSON.stringify(Array.from(seed)));
    
    const payload = buildCreatePayload(betAmount, commit);
    const totalAmount = betAmount + 50000000; // bet + gas
    
    const result = await sendTransaction(CONTRACT_ADDRESS, totalAmount, payload);
    
    return {
        result,
        seed: Array.from(seed),
        commit: Array.from(commit)
    };
}

// Join an existing match
export async function joinMatch(matchId, betAmount) {
    const seed = generateSeed();
    const commit = await calculateCommit(seed);
    
    // Store seed locally for later reveal
    localStorage.setItem(`seed_${matchId}`, JSON.stringify(Array.from(seed)));
    
    const payload = buildJoinPayload(matchId, commit);
    const totalAmount = betAmount + 50000000; // bet + gas
    
    const result = await sendTransaction(CONTRACT_ADDRESS, totalAmount, payload);
    
    return {
        result,
        seed: Array.from(seed),
        commit: Array.from(commit)
    };
}

// Reveal seed for a match
export async function revealSeed(matchId) {
    const storedSeed = localStorage.getItem(`seed_${matchId}`);
    if (!storedSeed) {
        throw new Error('Seed not found for this match');
    }
    
    const seed = new Uint8Array(JSON.parse(storedSeed));
    const payload = buildRevealPayload(matchId, seed);
    
    const result = await sendTransaction(CONTRACT_ADDRESS, 50000000, payload); // gas only
    
    // Clean up stored seed
    localStorage.removeItem(`seed_${matchId}`);
    
    return result;
}

// Cancel a match (if no one joined)
export async function cancelMatch(matchId) {
    const payload = buildCancelPayload(matchId);
    const result = await sendTransaction(CONTRACT_ADDRESS, 50000000, payload); // gas only
    return result;
}

// Claim forfeit (if opponent didn't reveal)
export async function claimForfeit(matchId) {
    const payload = buildClaimForfeitPayload(matchId);
    const result = await sendTransaction(CONTRACT_ADDRESS, 50000000, payload); // gas only
    return result;
}

// Get user's wallet address
export async function getUserAddress() {
    const wallet = await tonConnectUI.getAccount();
    return wallet?.address;
}

// Check if user is connected
export function isConnected() {
    return tonConnectUI.connected;
}

// Connect wallet
export async function connectWallet() {
    try {
        await tonConnectUI.connectWallet();
        return true;
    } catch (error) {
        console.error('Connection failed:', error);
        return false;
    }
}

// Disconnect wallet
export async function disconnectWallet() {
    await tonConnectUI.disconnect();
}

// Format TON amount (nanoTON to TON)
export function formatTON(nanoTON) {
    return (nanoTON / 1000000000).toFixed(2);
}

// Parse TON amount (TON to nanoTON)
export function parseTON(ton) {
    return Math.floor(parseFloat(ton) * 1000000000);
}

// Contract address setter (call after deployment)
export function setContractAddress(address) {
    CONTRACT_ADDRESS = address;
}

// Get contract address
export function getContractAddress() {
    return CONTRACT_ADDRESS;
}
