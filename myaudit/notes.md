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


# attack areas 
- LP token system is more sophisticated than traditional AMM
- Every require and revert can be chance to a DOS medium submission! :)



# questions


# actors 
- admin(owner): simplexFacet , vaultFacet
- traders: swapFacet
- LPs: valueFacet , valueTokenFacet 
- **Lockers/Unlockers** (Special Admin Role): lockFacet
 
# state

struct Asset {
    uint256 value;     // Total value staked
    uint256 bgtValue;  // Value earning BGT rewards
    // Fee tracking
    uint256[MAX_TOKENS] earningsPerValueX128Check;
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

# concepst
## tokens
- Token name format: "brv" + pool name
- there is a bgt rewards token
## system
-assest system
-token system: brv+pool name, bgt token
## vertex and edge
- each vertex is a token with a lock attribute and a vault and amount of that token in each Closure
