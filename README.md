# UnionChain

A decentralized labor union democratic voting system for transparent union governance on Stacks blockchain.

## Features

- Union ballot creation and candidate management
- Member voting with seniority-weighted decisions
- Delegate assignment for union representation
- Contract cycle governance and timeline management
- Comprehensive union democracy statistics

## Smart Contract Functions

### Public Functions
- `create-ballot` - Create union ballot for member voting (president only)
- `cast-union-vote` - Cast vote on union ballot with seniority weight
- `assign-delegate` - Assign delegate for union representation
- `close-ballot` - Close ballot voting (president only)
- `advance-contract-cycle` - Advance union contract cycle (president only)

### Read-Only Functions
- `get-ballot-votes-total` - Get total votes cast on ballot
- `get-member-seniority-level` - Get member's seniority level
- `get-ballot-status` - Check if ballot voting is active
- `get-current-contract-cycle` - Get current contract cycle
- `get-union-stats` - Get comprehensive union statistics

## Governance Features
- Seniority-weighted voting system
- Delegate representation mechanism
- Contract cycle decision periods
- President authorization controls

## Usage

Deploy the contract to create a union governance system where members can vote on ballots, assign delegates, and participate in democratic union decision making.

## License

MIT