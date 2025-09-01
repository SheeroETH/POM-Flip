# 🚀 Guide de Déploiement POM Flip On-Chain

## 📋 Prérequis

1. **Node.js** (v18+)
2. **Tact Compiler** 
3. **Wallet TON** (Tonkeeper, Tonhub, etc.)
4. **TON Testnet** pour les tests

## 🔧 Installation

```bash
# Installer les dépendances
npm install

# Installer Tact compiler
npm install -g @tact-lang/compiler
```

## 📝 Configuration

### 1. Compiler le Smart Contract

```bash
# Compiler le contrat
tact --config tact.config.json
```

### 2. Déployer sur Testnet

```bash
# Déployer le contrat (remplacer les adresses)
func deploy POMFlipHub \
  --owner "YOUR_OWNER_ADDRESS" \
  --treasury "YOUR_TREASURY_ADDRESS" \
  --feeBps 200 \
  --testnet
```

### 3. Mettre à jour l'adresse du contrat

Dans `ton-utils.js`, remplacez :
```javascript
const CONTRACT_ADDRESS = "EQD..."; // Votre adresse de contrat
```

## 🎮 Utilisation

### Mode Solo
- Jeu local sans blockchain
- Score et streak sauvegardés localement

### Mode PvP Local  
- Mises virtuelles en POM
- Simulation d'adversaires
- Pas de vraies transactions

### Mode PvP On-Chain
- Vraies mises en TON
- Smart contract déployé
- Commit-reveal pour l'équité
- Timeouts anti-AFK

## 🔐 Sécurité

### Commit-Reveal
1. **Commit** : Chaque joueur envoie `sha256(seed)` 
2. **Reveal** : Chaque joueur révèle son `seed`
3. **Résultat** : `sha256(seed1 || seed2 || match_id)` → bit final

### Timeouts
- **Join** : 5 minutes pour rejoindre
- **Reveal** : 3 minutes pour révéler
- **Forfeit** : Récupération automatique si timeout

### Anti-Triche
- ✅ Seeds générés côté client
- ✅ Commits vérifiés cryptographiquement  
- ✅ Résultat déterministe et vérifiable
- ✅ Pas d'oracle externe nécessaire

## 📊 Structure du Contrat

```tact
contract POMFlipHub {
  // État
  matches: map<Int, Match>
  nextId: Int
  feeBps: Int
  
  // Opérations
  createMatch()    // Créer un match
  joinMatch()      // Rejoindre un match  
  revealSeed()     // Révéler son seed
  cancelMatch()    // Annuler si pas de join
  claimForfeit()   // Récupérer si timeout
}
```

## 🎯 Flux de Jeu

1. **Création** : P1 crée un match avec commit1
2. **Join** : P2 rejoint avec commit2  
3. **Choix** : Les deux choisissent heads/tails
4. **Reveal** : Les deux révèlent leurs seeds
5. **Résolution** : Calcul automatique + payout

## 💰 Économie

- **Mise** : Montant fixe par match
- **Gain** : Double de la mise (moins les fees)
- **Fees** : 2% vers treasury (configurable)
- **Gas** : ~0.05 TON par transaction

## 🐛 Debug

### Logs
```javascript
// Activer les logs détaillés
localStorage.setItem('debug', 'true');
```

### Vérifications
- ✅ Wallet connecté
- ✅ Balance suffisante  
- ✅ Contrat déployé
- ✅ Seeds stockés localement

## 🔄 Mise à Jour

### Contrat
```bash
# Recompiler et redéployer
tact --config tact.config.json
func deploy --upgrade
```

### Frontend
```bash
# Mettre à jour les dépendances
npm update

# Redéployer le site
git push origin main
```

## 📞 Support

- **Issues** : GitHub Issues
- **Docs** : Ce fichier
- **Community** : Telegram @SheeroETH

## ⚠️ Avertissements

- **Testnet uniquement** pour les tests
- **Mainnet** avec prudence et audits
- **Fees** configurables par le owner
- **Emergency** withdraw disponible

---

**🎮 Bon jeu et bonne chance !** 🍀
