# sensitive areas 
Tracks actual value instead of pool shares
Separates regular value from BGT-earning value
----------------------------
Internal accounting via Asset struct
Optional ERC20 representation via ValueTokenFacet
---------------------------------
protocol-normalized amounts : nominal amounts
---------------------------------

# attack areas 
LP token system is more sophisticated than traditional AMM



# questions


# actors 
- admin(owner): simplexFacet , vaultFacet
- traders: swapFacet
- LPs: valueFacet , valueTokenFacet 
- **Lockers/Unlockers** (Special Admin Role): lockFacet
 


# concepst
## tokens
- Token name format: "brv" + pool name
- there is a bgt rewards token
## system
-assest system
-token system: brv+pool name, bgt token
## vertex and edge