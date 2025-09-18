# 🚗 Decentralized Route Optimization

A blockchain-based route optimization system that rewards drivers for efficient routing with micro-tokens! 🪙

## 🌟 Overview

This smart contract creates a decentralized ecosystem where drivers can:
- 📊 Submit route data on-chain
- 🏆 Earn rewards for efficient routes
- 🗳️ Vote on route quality
- 📈 Build reputation through consistent performance

## ✨ Key Features

- **🔐 Driver Registration**: Secure on-chain driver profiles
- **📍 Route Submission**: Submit detailed route data with GPS coordinates
- **⚡ Efficiency Scoring**: Automated calculation based on distance, time, fuel usage, and traffic
- **💰 Token Rewards**: Earn micro-tokens for efficient routes
- **🗳️ Community Voting**: Rate routes and build driver reputation
- **📊 Analytics**: Track performance metrics and route history

## 🚀 Getting Started

### Prerequisites
- Clarinet CLI installed
- Stacks wallet for testing

### Installation

1. Clone the repository
2. Navigate to project directory
3. Run clarinet check to verify contract

```bash
clarinet check
```

## 📋 Contract Functions

### Public Functions

#### `register-driver()`
Register as a new driver in the system
- ✅ Creates driver profile
- 🎯 Initializes reputation score
- 📊 Sets up reward balance

#### `submit-route(start-lat, start-lng, end-lat, end-lng, distance, time-taken, fuel-used, traffic-conditions)`
Submit a new route for evaluation
- 📍 GPS coordinates (latitude/longitude in micro-degrees)
- 📏 Distance in meters (1-10,000)
- ⏱️ Time taken in seconds (1-14,400)
- ⛽ Fuel used in milliliters
- 🚦 Traffic conditions (0-100, lower is better)

#### `vote-route(route-id, upvote)`
Vote on a route's quality
- 👍 Upvote increases driver reputation by 10
- 👎 Downvote decreases driver reputation by 5
- 🚫 Cannot vote on your own routes

#### `withdraw-rewards(amount)`
Withdraw earned tokens from your balance

### Read-Only Functions

#### `get-driver-info(driver-principal)`
Retrieve driver statistics and performance metrics

#### `get-route-info(route-id)`
Get detailed information about a specific route

#### `get-driver-balance(driver-principal)`
Check current token balance for a driver

#### `get-total-stats()`
View system-wide statistics

## 🧮 Efficiency Calculation

Routes are scored based on:
- **Speed Efficiency**: Distance/time ratio
- **Fuel Efficiency**: Distance per unit of fuel
- **Traffic Bonus**: Reward for avoiding congested routes

```
Efficiency Score = (Speed Score + Fuel Efficiency + Traffic Bonus) / 3
Reward = Base Reward (100) + (Efficiency × Multiplier (10))
```

## 📊 Data Structures

### Driver Profile
- Registration timestamp
- Total routes submitted
- Average efficiency score
- Total rewards earned
- Reputation score

### Route Data
- Driver principal
- Start/end coordinates
- Route metrics (distance, time, fuel)
- Efficiency score and reward
- Timestamp

## 🔧 Configuration

### Constants
- **MIN_DISTANCE**: 1 meter
- **MAX_DISTANCE**: 10,000 meters
- **MIN_TIME**: 1 second
- **MAX_TIME**: 4 hours (14,400 seconds)
- **BASE_REWARD**: 100 tokens
- **EFFICIENCY_MULTIPLIER**: 10x

## 🎯 Usage Examples

### Register as Driver
```clarity
(contract-call? .decentralized-route-optimization register-driver)
```

### Submit Route
```clarity
(contract-call? .decentralized-route-optimization submit-route 
    40748817 -73985428  ;; NYC Times Square
    40761434 -73977622  ;; NYC Central Park
    u2500              ;; 2.5km distance
    u900               ;; 15 minutes
    u150               ;; 150ml fuel
    u30)               ;; Low traffic
```

### Vote on Route
```clarity
(contract-call? .decentralized-route-optimization vote-route u1 true)
```

## 🛡️ Security Features

- Owner-only reward pool management
- Input validation for all route parameters
- Protection against self-voting
- Balance checks for withdrawals

## 🚧 Future Enhancements

- 🗺️ Integration with mapping APIs
- 🤖 Machine learning route prediction
- 🌍 Multi-city expansion
- 📱 Mobile app interface
- 🏅 Achievement system

## 📝 License

MIT License - Drive efficiently! 🌱

---

Made with ❤️ for the Stacks ecosystem
