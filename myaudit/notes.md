# sensitive areas 
Tracks actual value instead of pool shares
Separates regular value from BGT-earning value
----------------------------
Internal accounting via Asset struct
Optional ERC20 representation via ValueTokenFacet
---------------------------------
protocol-normalized amounts : nominal amounts
---------------------------------
there are 16 max cap on tokens
Token indices are immutable once assigned
New tokens can only be added, not removed
Token order in registration matters
Each token's position in the system is fixed
Closures can reference tokens consistently by their bit positions
-------------------------------------
So the protocl has 16 vertices and 16 vaults at most
----------------------------------
There is regular positions and BGT positions in each closure
-----------------------------------
msg.value and reverts in a loop
--------------------------------


# attack areas 
- LP token system is more sophisticated than traditional AMM
- Every require and revert can be chance to a DOS medium submission! :)
- Does this contract use Push pattern to send earnings or they claim the earnings?



# questions


# actors 
- admin(owner): simplexFacet , vaultFacet
- traders: swapFacet
- LPs: valueFacet , valueTokenFacet 
- **Lockers/Unlockers** (Special Admin Role): lockFacet
 
# state
```solidity
 
struct Asset {
    uint256 value;
    uint256 bgtValue; // Value - bgtValue is the non-bgt value.
    // Checkpoints from our Closure.
    uint256[MAX_TOKENS] earningsPerValueX128Check;
    uint256[MAX_TOKENS] unexchangedPerBgtValueX128Check;
    uint256 bgtPerValueX128Check;
    // When we modify value, we need to collect fees but we don't automatically withdraw them.
    // Instead they reside here until the user actually wants to collect fees earned.
    uint256[MAX_TOKENS] collectedBalances; // Again, these are shares in the reserve.
    uint256 bgtBalance;
}

struct Vertex {
    VertexId vid;     // Represents a token in the system
    address token;    
    bool locked;      // Safety control
    mapping(ClosureId => uint256) balances;
}

// From Token.sol
struct TokenRegistry {
    address[] tokens;     // Dynamic array of token addresses
    mapping(address => uint8) tokenIdx;  // Token address to index mapping - [0-15]
}


struct VaultProxy {
    address vault;      // The actual vault contract
    VaultType vType;   // Type of vault (e.g. ERC4626)
    VaultE4626 e4626;  // For ERC4626 vaults 
}

struct VaultStorage {
    // Vaults in use.
    mapping(VertexId => address vault) vaults;
    // Vaults we're potentially transfering into.
    mapping(VertexId => address vault) backups;
    // Vault info.
    mapping(address vault => VaultType) vTypes;
    mapping(address vault => VaultE4626) e4626s;
    mapping(address vault => VertexId) usedBy;
}

```

# concepst
## tokens
- Token name format: "brv" + pool name
- there is a bgt rewards token
## system
-asset system
-token system: brv+pool name, bgt token
## vertex and edge
- each vertex is a token with a lock attribute and a vault and amount of that token in each Closure
- we have at most 16 vertex
- vertices are used as an internal accounting system and tokens are in the valueFacet
- Vertices are created at token registration
## vaults
- vaults are optional yield-generating strategies that can be added later.
-Vertices are created at token registration (accounting)
- Vaults are optional and added later (yield)


# flows 
## LP flow

```

ValueFacet.addValue() ->
  Vertex.deposit() -> 
    VaultProxy.deposit() ->
      VaultE4626.deposit() or other vault type (which is the active vault)


a) Deploy token
b) Deploy vault for that token 
c) Call addVertex() with token + vault + vaultType
d) Now when users add value, tokens automatically flow to the specified vault

```
