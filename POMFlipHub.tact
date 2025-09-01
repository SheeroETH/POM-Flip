// POMFlipHub.tact - Smart Contract for POM Flip PvP Betting
// Deploy on TON blockchain with commit-reveal fairness

import "@stdlib/deploy";

// Operation codes
const OP_CREATE: Int = 0x01;
const OP_JOIN: Int = 0x02;
const OP_REVEAL: Int = 0x03;
const OP_CANCEL: Int = 0x04;
const OP_CLAIM_FORFEIT: Int = 0x05;

// Match states
const STATE_CREATED: Int = 0;
const STATE_JOINED: Int = 1;
const STATE_REVEALING: Int = 2;
const STATE_RESOLVED: Int = 3;
const STATE_CANCELLED: Int = 4;

// Timeouts (in seconds)
const JOIN_TTL: Int = 300;    // 5 minutes to join
const REVEAL_TTL: Int = 180;  // 3 minutes to reveal

struct Match {
    amount: Int;           // Bet amount in nanoTON
    player1: Address;      // Creator address
    player2: Address?;     // Joiner address
    commit1: slice;        // sha256(seed1) from player1
    commit2: slice?;       // sha256(seed2) from player2
    seed1: slice?;         // Revealed seed1
    seed2: slice?;         // Revealed seed2
    state: Int;            // Current state
    join_deadline: Int;    // Timestamp when join period ends
    reveal_deadline: Int;  // Timestamp when reveal period ends
    created_at: Int;       // Creation timestamp
}

contract POMFlipHub {
    owner: Address;
    treasury: Address;
    feeBps: Int;           // Fee in basis points (200 = 2%)
    
    nextId: Int;
    matches: map<Int, Match>;
    
    init(owner: Address, treasury: Address, feeBps: Int) {
        self.owner = owner;
        self.treasury = treasury;
        self.feeBps = feeBps;
        self.nextId = 1;
        self.matches = map_empty();
    }
    
    receive() {
        // Accept all incoming messages
    }
    
    // Helper functions
    fun onlyOwner() {
        require(msg.sender == self.owner, "not-owner");
    }
    
    fun calculateFee(amount: Int): Int {
        return amount * self.feeBps / 10000;
    }
    
    fun now(): Int {
        return timestamp();
    }
    
    fun isValidAddress(addr: Address?): Bool {
        return addr?.is_some() ?? false;
    }
    
    // CREATE MATCH
    // Body: [op(32), bet(coins), commit1(slice)]
    external fun createMatch() {
        let cs = begin_parse(msg.body);
        let op = cs~load_uint(32);
        require(op == OP_CREATE, "invalid-op");
        
        let bet = cs~load_coins();
        let commit1 = cs~load_ref().begin_parse();
        
        // Validate bet amount (minimum 0.01 TON)
        require(bet >= 10000000, "bet-too-small");
        
        // Validate message value covers bet + gas
        require(msg.value >= bet + 50000000, "insufficient-value");
        
        let id = self.nextId;
        self.nextId = id + 1;
        
        let match: Match = Match{
            amount: bet,
            player1: msg.sender,
            player2: null(),
            commit1: commit1,
            commit2: null(),
            seed1: null(),
            seed2: null(),
            state: STATE_CREATED,
            join_deadline: self.now() + JOIN_TTL,
            reveal_deadline: 0,
            created_at: self.now()
        };
        
        self.matches[id] = match;
        
        // Send match ID back to creator
        let response = begin_cell()
            .store_uint(0x18, 6)
            .store_slice(msg.sender)
            .store_grams(0)
            .store_uint(0, 1 + 4 + 4 + 64 + 32 + 1 + 1)
            .store_uint(id, 64)
            .end_cell();
        send_raw_msg(response, 1);
    }
    
    // JOIN MATCH
    // Body: [op(32), match_id(uint64), commit2(slice)]
    external fun joinMatch() {
        let cs = begin_parse(msg.body);
        let op = cs~load_uint(32);
        require(op == OP_JOIN, "invalid-op");
        
        let id = cs~load_uint(64);
        let commit2 = cs~load_ref().begin_parse();
        
        let match = self.matches.get(id);
        require(match.state == STATE_CREATED, "match-not-available");
        require(self.now() <= match.join_deadline, "join-deadline-passed");
        require(msg.value >= match.amount, "insufficient-bet");
        require(msg.sender != match.player1, "cannot-join-own-match");
        require(!self.isValidAddress(match.player2), "match-already-joined");
        
        match.player2 = some(msg.sender);
        match.commit2 = commit2;
        match.state = STATE_JOINED;
        match.reveal_deadline = self.now() + REVEAL_TTL;
        
        self.matches[id] = match;
        
        // Notify both players
        self.notifyPlayers(id, "match-joined");
    }
    
    // REVEAL SEED
    // Body: [op(32), match_id(uint64), seed(slice)]
    external fun revealSeed() {
        let cs = begin_parse(msg.body);
        let op = cs~load_uint(32);
        require(op == OP_REVEAL, "invalid-op");
        
        let id = cs~load_uint(64);
        let seed = cs~load_ref().begin_parse();
        
        let match = self.matches.get(id);
        require(match.state == STATE_JOINED || match.state == STATE_REVEALING, "not-in-reveal-phase");
        require(self.now() <= match.reveal_deadline, "reveal-deadline-passed");
        
        // Verify commit matches seed
        let seedHash = sha256(seed);
        let isValidCommit = false;
        
        if (msg.sender == match.player1) {
            require(!self.isValidAddress(match.seed1), "already-revealed");
            isValidCommit = slice_eq(seedHash, match.commit1);
            match.seed1 = seed;
        } else {
            let player2 = match.player2.get();
            require(msg.sender == player2, "not-a-player");
            require(!self.isValidAddress(match.seed2), "already-revealed");
            isValidCommit = slice_eq(seedHash, match.commit2.get());
            match.seed2 = seed;
        }
        
        require(isValidCommit, "invalid-seed");
        
        // Update state
        if (match.state == STATE_JOINED) {
            match.state = STATE_REVEALING;
        }
        
        // Check if both seeds revealed
        if (self.isValidAddress(match.seed1) && self.isValidAddress(match.seed2)) {
            self.resolveMatch(id, match);
            return;
        }
        
        self.matches[id] = match;
    }
    
    // CANCEL MATCH (if no one joined)
    // Body: [op(32), match_id(uint64)]
    external fun cancelMatch() {
        let cs = begin_parse(msg.body);
        let op = cs~load_uint(32);
        require(op == OP_CANCEL, "invalid-op");
        
        let id = cs~load_uint(64);
        let match = self.matches.get(id);
        
        require(match.state == STATE_CREATED, "cannot-cancel");
        require(msg.sender == match.player1, "only-creator-can-cancel");
        require(self.now() > match.join_deadline, "join-period-active");
        
        match.state = STATE_CANCELLED;
        self.matches[id] = match;
        
        // Refund creator
        send_raw_msg(match.player1, match.amount, 64);
    }
    
    // CLAIM FORFEIT (if opponent didn't reveal)
    // Body: [op(32), match_id(uint64)]
    external fun claimForfeit() {
        let cs = begin_parse(msg.body);
        let op = cs~load_uint(32);
        require(op == OP_CLAIM_FORFEIT, "invalid-op");
        
        let id = cs~load_uint(64);
        let match = self.matches.get(id);
        
        require(match.state == STATE_JOINED || match.state == STATE_REVEALING, "not-forfeit-eligible");
        require(self.now() > match.reveal_deadline, "reveal-period-active");
        
        let p1Revealed = self.isValidAddress(match.seed1);
        let p2Revealed = self.isValidAddress(match.seed2);
        
        require(p1Revealed != p2Revealed, "both-or-neither-revealed");
        
        let totalPot = match.amount * 2;
        let fee = self.calculateFee(totalPot);
        let payout = totalPot - fee;
        
        let winner = p1Revealed ? match.player1 : match.player2.get();
        
        match.state = STATE_RESOLVED;
        self.matches[id] = match;
        
        // Send fee to treasury
        if (fee > 0) {
            send_raw_msg(self.treasury, fee, 64);
        }
        
        // Send payout to winner
        send_raw_msg(winner, payout, 64);
    }
    
    // INTERNAL: Resolve match when both seeds revealed
    fun resolveMatch(id: Int, match: Match) {
        // Create deterministic randomness from both seeds + match ID
        let randomness = begin_cell()
            .store_slice(match.seed1.get())
            .store_slice(match.seed2.get())
            .store_uint(id, 64)
            .end_cell();
        
        let hash = sha256(randomness);
        let result = hash.begin_parse().~load_uint(1); // Last bit: 0=heads, 1=tails
        
        let totalPot = match.amount * 2;
        let fee = self.calculateFee(totalPot);
        let payout = totalPot - fee;
        
        // 0 = heads (player1 wins), 1 = tails (player2 wins)
        let winner = (result == 0) ? match.player1 : match.player2.get();
        
        match.state = STATE_RESOLVED;
        self.matches[id] = match;
        
        // Send fee to treasury
        if (fee > 0) {
            send_raw_msg(self.treasury, fee, 64);
        }
        
        // Send payout to winner
        send_raw_msg(winner, payout, 64);
        
        // Notify both players
        self.notifyPlayers(id, "match-resolved");
    }
    
    // Helper: Notify both players
    fun notifyPlayers(id: Int, message: String) {
        let match = self.matches.get(id);
        
        // Notify player1
        let msg1 = begin_cell()
            .store_uint(0x18, 6)
            .store_slice(match.player1)
            .store_grams(0)
            .store_uint(0, 1 + 4 + 4 + 64 + 32 + 1 + 1)
            .store_uint(id, 64)
            .store_string(message)
            .end_cell();
        send_raw_msg(msg1, 1);
        
        // Notify player2 if exists
        if (self.isValidAddress(match.player2)) {
            let player2 = match.player2.get();
            let msg2 = begin_cell()
                .store_uint(0x18, 6)
                .store_slice(player2)
                .store_grams(0)
                .store_uint(0, 1 + 4 + 4 + 64 + 32 + 1 + 1)
                .store_uint(id, 64)
                .store_string(message)
                .end_cell();
            send_raw_msg(msg2, 1);
        }
    }
    
    // GETTER: Get match info
    get fun getMatch(id: Int): Match {
        return self.matches.get(id);
    }
    
    // GETTER: Get next match ID
    get fun getNextId(): Int {
        return self.nextId;
    }
    
    // ADMIN: Update fee (only owner)
    external fun updateFee(newFeeBps: Int) {
        self.onlyOwner();
        require(newFeeBps <= 1000, "fee-too-high"); // Max 10%
        self.feeBps = newFeeBps;
    }
    
    // ADMIN: Update treasury (only owner)
    external fun updateTreasury(newTreasury: Address) {
        self.onlyOwner();
        self.treasury = newTreasury;
    }
    
    // ADMIN: Emergency withdraw (only owner)
    external fun emergencyWithdraw() {
        self.onlyOwner();
        send_raw_msg(self.owner, my_balance(), 64);
    }
}
