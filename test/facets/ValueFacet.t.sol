// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {MultiSetupTest} from "./MultiSetup.u.sol";
import {console2} from "forge-std/console2.sol";
import {console} from "forge-std/console.sol";
import {ValueFacet} from "../../src/multi/facets/ValueFacet.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";
import {AssetBookImpl} from "../../src/multi/Asset.sol";
import {MAX_TOKENS} from "../../src/multi/Token.sol";
import {MockERC20} from "../mocks/MockERC20.sol";

contract ValueFacetTest is MultiSetupTest {
    function setUp() public {
        vm.startPrank(owner);

        _newDiamond(); //@>i create a new diamond with all it's facets

        _newTokens(4); //@>i create 4 new test tokens

        _fundAccount(alice); //@>i fund and approve 1e30 of all tokens to address
        _fundAccount(bob);
        // Its annoying we have to fund first.
        _fundAccount(address(this));
        _fundAccount(owner);

        // So we have to redo the prank.
        vm.startPrank(owner);

        //@>i simplexFacet.addClosure(cid, initValue, 0, 0)with zero basefee and zero protocolTake
        //@>i all combinations of our 4 test tokens in 16 closures
        _initializeClosure(0xF, 100e18); // 1,2,3,4
        _initializeClosure(0xE, 100e18); // 2,3,4
        _initializeClosure(0xD, 100e18); // 1,3,4
        _initializeClosure(0xc, 1e12); // 3,4
        _initializeClosure(0xB, 100e18); // 1,2,4
        _initializeClosure(0xa, 1e12); // 2,4
        //@>i realneeded for each token calculated in simplexFacet and transfered from owner to SimplexFacet
        _initializeClosure(0x9, 1e18); // 1,4 //@>i initial value for tokens 1,4 is 1e18 minted for owner
        _initializeClosure(0x8, 1e12); // 4
        _initializeClosure(0x7, 100e18); // 1,2,3
        _initializeClosure(0x6, 1e12); // 2,3
        _initializeClosure(0x5, 1e12); // 1,3
        _initializeClosure(0x4, 1e12); // 3
        _initializeClosure(0x3, 100e18); // 1,2
        _initializeClosure(0x2, 1e12); // 2
        _initializeClosure(0x1, 1e12); // 1
        vm.stopPrank();

        //logAllBalances("=========== after funding in setup==========");
    }

    function getBalances(
        address who
    ) public view returns (uint256[4] memory balances) {
        for (uint8 i = 0; i < 4; ++i) {
            balances[i] = ERC20(tokens[i]).balanceOf(who);
        }
    }

    function diffBalances(
        uint256[4] memory a,
        uint256[4] memory b
    ) public pure returns (int256[4] memory diffs) {
        for (uint8 i = 0; i < 4; ++i) {
            diffs[i] = int256(a[i]) - int256(b[i]);
        }
    }

    function logAllBalances(string memory label) public view {
        console.log(string.concat("\n=== Balances: ", label, " ==="));

        uint256[4] memory testContractBal = getBalances(address(this));
        uint256[4] memory aliceBal = getBalances(alice);
        uint256[4] memory ownerBal = getBalances(owner);
        uint256[4] memory valueFacetBal = getBalances(address(diamond)); // Diamond proxy holds the tokens
        uint256[4] memory vault0Bal = getBalances(address(vaults[0]));
        uint256[4] memory vault1Bal = getBalances(address(vaults[1]));
        uint256[4] memory vault2Bal = getBalances(address(vaults[2]));
        uint256[4] memory vault3Bal = getBalances(address(vaults[3]));

        console.log("Test Contract Balances:");
        for (uint i = 0; i < 4; i++) {
            console.log("Token %d: %s", i, vm.toString(testContractBal[i]));
        }

        console.log("\nValueFacet (Diamond) Balances:"); // Added this section
        for (uint i = 0; i < 4; i++) {
            console.log("Token %d: %s", i, vm.toString(valueFacetBal[i]));
        }

        console.log("\nAlice Balances:");
        for (uint i = 0; i < 4; i++) {
            console.log("Token %d: %s", i, vm.toString(aliceBal[i]));
        }

        console.log("\nOwner Balances:");
        for (uint i = 0; i < 4; i++) {
            console.log("Token %d: %s", i, vm.toString(ownerBal[i]));
        }

        console.log("\nVault0 Balances  %s", vm.toString(vault0Bal[0]));
         

        console.log("\nVault1 Balances %s", vm.toString(vault1Bal[1]));
        console.log("\nVault2 Balances %s", vm.toString(vault2Bal[2]));
        console.log("\nVault3 Balances %s", vm.toString(vault3Bal[3]));
         
 

            // Value position
           (uint256 value, uint256 bgtValue,uint256[MAX_TOKENS] memory earnings ,uint256 bgtEarnings ) = valueFacet.queryValue(address(this), 0xA);
           console.log("\n Test contract Position - query value:");
           console.log("Total Value: %s", vm.toString(value));
           console.log("BGT Value: %s", vm.toString(bgtValue));
           for(uint i = 0; i< 16; i++) {
                console.log("Token earning %d: %s", i, vm.toString(earnings[i]));
           }
           console.log("BGT Earning: %s", vm.toString(bgtEarnings));
    }

    function testMyaudit() public {
        //============================================
        // Capture the returned array
        uint256[MAX_TOKENS] memory requiredBalances = valueFacet.addValue(
            alice,
            0x7,
            5e28,
            1e28
        );

        // Log the values
        console.log("\n ===== \n Required balances after addValue:");
        for (uint8 i = 0; i < MAX_TOKENS; i++) {
            // Only log if the balance is non-zero
            if (requiredBalances[i] > 0) {
                console.log(
                    "Token %d required balance: %d",
                    i,
                    requiredBalances[i]
                );
            }
        }

        // To verify current state, you can also call queryValue
        (
            uint256 value,
            uint256 bgtValue,
            uint256[MAX_TOKENS] memory earnings,
            uint256 bgtEarnings
        ) = valueFacet.queryValue(alice, 0x7);

        console.log("\nCurrent state for alice in closure 0x7:");
        console.log("Total value: %d", value);
        console.log("BGT value: %d", bgtValue);
        console.log("BGT earnings: %d", bgtEarnings);

        console.log("\nEarnings per token:");
        for (uint8 i = 0; i < MAX_TOKENS; i++) {
            if (earnings[i] > 0) {
                console.log("Token %d earnings: %d", i, earnings[i]);
            }
        }

        //============================================

        (value, bgtValue, , ) = valueFacet.queryValue(alice, 0x7);

        vm.startPrank(alice);

        valueFacet.removeValue(alice, 0x7, 5e27, 5e27);

        logAllBalances("\n   balances after alice remove 5e27:");

        vm.stopPrank();
 

        //============================================
    }

    function testAddRemoveValue() public {
        logAllBalances("\n initial balances:");

        // Add and remove value will fund using multiple tokens and has no size limitations like the single methods do.
        uint256[4] memory initBalances = getBalances(address(this));
        //@>q everyone can add value for everyone. possible calculation disruption
        //@>i 5e27: bgtValue (part of total value that earns BGT) + Test contract  will transfer 5e27 to every closures vault and a 5e27 position is opened for Alice
        //valueFacet.addValue(alice, 0x9, 1e28, 5e27);//@>i reciepent,cid,value,bgt value

        //============================================
        // Capture the returned array
        uint256[MAX_TOKENS] memory requiredBalances = valueFacet.addValue(
            alice,
            0x9,
            5e28,
            0
        );

        // Log the values
        console.log("Required balances after addValue:");
        for (uint8 i = 0; i < MAX_TOKENS; i++) {
            // Only log if the balance is non-zero
            if (requiredBalances[i] > 0) {
                console.log(
                    "Token %d required balance: %d",
                    i,
                    requiredBalances[i]
                );
            }
        }

        // To verify current state, you can also call queryValue
        (
            uint256 value,
            uint256 bgtValue,
            uint256[MAX_TOKENS] memory earnings,
            uint256 bgtEarnings
        ) = valueFacet.queryValue(alice, 0x9);

        console.log("\nCurrent state for alice in closure 0x9:");
        console.log("Total value: %d", value);
        console.log("BGT value: %d", bgtValue);
        console.log("BGT earnings: %d", bgtEarnings);

        console.log("\nEarnings per token:");
        for (uint8 i = 0; i < MAX_TOKENS; i++) {
            if (earnings[i] > 0) {
                console.log("Token %d earnings: %d", i, earnings[i]);
            }
        }

        //============================================

        (value, bgtValue, , ) = valueFacet.queryValue(alice, 0x9);

        logAllBalances("\n after add value to alice: ");

        assertEq(value, 1e28);
        assertEq(bgtValue, 5e27);

        //@>i 5e27 bgt earning Value + 5e27 regular earning Value ()
        //  - Regular value position (5e27) earns fees in the pool tokens
        //  - BGT value position (5e27) converts earned fees into BGT token

        uint256[4] memory currentBalances = getBalances(address(this));
        int256[4] memory diffs = diffBalances(initBalances, currentBalances);

        assertEq(diffs[0], 5e27);
        assertEq(diffs[1], 0);
        assertEq(diffs[2], 0);
        assertEq(diffs[3], 5e27);
        //@>q everyone can addvalue for anyone but only the reciepent can removeValue
        // Of course we have no value to remove.
        vm.expectRevert();
        valueFacet.removeValue(alice, 0x9, 5e27, 1e27);
        // But alice does.
        initBalances = getBalances(alice);

        vm.startPrank(alice);

        valueFacet.removeValue(alice, 0x9, 5e27, 5e27);

        logAllBalances("\n   balances after alice remove 5e27:");

        // But she can't remove more bgt value now even though she has more value.
        vm.expectRevert();
        valueFacet.removeValue(alice, 0x9, 5e27, 1);
        // She can only remove regular value.
        valueFacet.removeValue(alice, 0x9, 5e27, 0);
        // And now she's out.
        vm.expectRevert();
        valueFacet.removeValue(alice, 0x9, 1, 0);

        vm.stopPrank();

        //============================================
        // Capture the returned array

        // Log the values
        console.log("Required balances after remove value:");
        for (uint8 i = 0; i < MAX_TOKENS; i++) {
            // Only log if the balance is non-zero
            if (requiredBalances[i] > 0) {
                console.log(
                    "Token %d required balance: %d",
                    i,
                    requiredBalances[i]
                );
            }
        }

        // To verify current state, you can also call queryValue
        (value, bgtValue, earnings, bgtEarnings) = valueFacet.queryValue(
            alice,
            0x9
        );

        console.log("\nCurrent state for alice in closure 0x9:");
        console.log("Total value: %d", value);
        console.log("BGT value: %d", bgtValue);
        console.log("BGT earnings: %d", bgtEarnings);

        console.log("\nEarnings per token:");
        for (uint8 i = 0; i < MAX_TOKENS; i++) {
            if (earnings[i] > 0) {
                console.log("Token %d earnings: %d", i, earnings[i]);
            }
        }

        //============================================

        currentBalances = getBalances(alice);
        diffs = diffBalances(currentBalances, initBalances);

        assertApproxEqAbs(diffs[0], 5e27, 2, "0"); //@>i  with at most 2 units diff is ok
        assertEq(diffs[1], 0);
        assertEq(diffs[2], 0);
        assertApproxEqAbs(diffs[3], 5e27, 2, "3");
    }

    function testAddRemoveValueSingle() public {
        uint256[4] memory initBalances = getBalances(address(this));
        // This is too much to put into one token.
        vm.expectRevert(); // XTooSmall
        valueFacet.addValueSingle(alice, 0x9, 1e28, 5e27, tokens[0], 0);
        // So we add less.
        // Of course bgt can't be larger.
        vm.expectRevert(); // InsufficientValueForBgt
        valueFacet.addValueSingle(alice, 0x9, 1e19, 5e19, tokens[0], 0);
        // Finally okay.
        uint256 requiredBalance = valueFacet.addValueSingle(
            alice,
            0x9,
            1e19,
            5e18,
            tokens[0],
            0
        );
        assertGt(requiredBalance, 1e19);
        assertApproxEqRel(requiredBalance, 1e19, 1e17);
        // We can't add irrelevant tokens though.
        vm.expectRevert(); // IrrelevantVertex
        uint128 remainingValue = 1e19;
        uint128 remainingBgt = 5e18;
        valueFacet.addValueSingle(
            alice,
            0x9,
            remainingValue,
            remainingBgt,
            tokens[1],
            0
        );

        (uint256 value, uint256 bgtValue, , ) = valueFacet.queryValue(
            alice,
            0x9
        );
        assertEq(value, 1e19);
        assertEq(bgtValue, 5e18);
        uint256[4] memory currentBalances = getBalances(address(this));
        int256[4] memory diffs = diffBalances(initBalances, currentBalances);
        assertEq(uint256(diffs[0]), requiredBalance);
        assertEq(diffs[1], 0);
        assertEq(diffs[2], 0);
        assertEq(diffs[3], 0);

        // We have no value to remove.
        vm.expectRevert(
            abi.encodeWithSelector(
                AssetBookImpl.InsufficientValue.selector,
                0,
                5e18
            )
        );
        valueFacet.removeValueSingle(alice, 0x9, 5e18, 1e18, tokens[0], 0);
        // But alice does.
        initBalances = getBalances(alice);
        vm.startPrank(alice);
        // But she can't remove from some other token, there aren't enough tokens.
        vm.expectRevert();
        valueFacet.removeValueSingle(alice, 0x9, 5e18, 1, tokens[3], 0);
        // Removing a small amount is fine.
        uint256 received = valueFacet.removeValueSingle(
            alice,
            0x9,
            1e6,
            1,
            tokens[3],
            0
        );
        remainingValue -= 1e6;
        remainingBgt -= 1;
        // But token3 is so valuable now, so you won't get much back.
        assertLt(received, 1e6);
        vm.expectRevert(); // PastSlippageBounds
        valueFacet.removeValueSingle(alice, 0x9, 1e6, 1, tokens[3], 9e5);
        // But she can't remove from an irrelevant token. even if its small.
        vm.expectRevert(); // IrrelevantVertex
        valueFacet.removeValueSingle(alice, 0x9, 1e6, 1, tokens[1], 0);
        // token 0 is fine.
        valueFacet.removeValueSingle(
            alice,
            0x9,
            remainingBgt,
            remainingBgt,
            tokens[0],
            0
        );
        remainingValue -= remainingBgt;
        // But she can't remove more bgt value now even though she has more value.
        vm.expectRevert(); // InsufficientBgtValue
        valueFacet.removeValueSingle(
            alice,
            0x9,
            remainingValue,
            1,
            tokens[0],
            0
        );
        // She can only remove regular value.
        valueFacet.removeValueSingle(
            alice,
            0x9,
            remainingValue,
            0,
            tokens[0],
            0
        );
        // And now she's out.
        vm.expectRevert(); // InsufficientValue
        valueFacet.removeValueSingle(alice, 0x9, 1, 0, tokens[0], 0);
        vm.stopPrank();
        currentBalances = getBalances(alice);
        diffs = diffBalances(currentBalances, initBalances);
        assertApproxEqRel(uint256(diffs[0]), requiredBalance, 1e7, "0"); // lost a little to 3
        assertEq(diffs[1], 0);
        assertEq(diffs[2], 0);
        assertEq(uint256(diffs[3]), received, "3");
    }

    function testAddRemoveSingleForValue() public {
        vm.startPrank(alice);
        // Simply add and remove.
        valueFacet.addSingleForValue(alice, 0xF, tokens[2], 1e18, 0, 0);
        // Too large
        vm.expectRevert();
        valueFacet.addSingleForValue(alice, 0xF, tokens[2], 1e24, 0, 0);
        valueFacet.addSingleForValue(alice, 0xF, tokens[2], 1e20, 0, 0);
        // Too large from other token.
        vm.expectRevert();
        valueFacet.removeSingleForValue(alice, 0xF, tokens[0], 1e20, 0, 0);
        valueFacet.removeSingleForValue(alice, 0xF, tokens[0], 1e18, 0, 0);
        vm.stopPrank();
    }

    function testAddRemoveSymmetries() public {
        // Single for value symmetry
        (, uint256 t0, , uint256 v0, ) = simplexFacet.getClosureValue(0xD);
        uint256 valueReceived = valueFacet.addSingleForValue(
            address(this),
            0xD,
            tokens[2],
            17e18,
            0,
            0
        );
        (, uint256 t1, , uint256 v1, ) = simplexFacet.getClosureValue(0xD);
        assertGt(t1, t0);
        assertEq(v1, v0 + valueReceived);
        valueFacet.removeSingleForValue(
            address(this),
            0xD,
            tokens[2],
            17e18 - 1,
            0,
            0
        );
        (, t1, , v1, ) = simplexFacet.getClosureValue(0xD);
        assertApproxEqRel(t1, t0, 1, "tsv");
        assertApproxEqRel(v1, v0, 1, "vsv");

        // Single for value symmetric with valueSingle
        valueReceived = valueFacet.addSingleForValue(
            address(this),
            0xD,
            tokens[2],
            2.1e19,
            0,
            0
        );
        uint256 tokensReceived = valueFacet.removeValueSingle(
            address(this),
            0xD,
            uint128(valueReceived),
            0,
            tokens[2],
            0
        );
        (, t0, , v0, ) = simplexFacet.getClosureValue(0xD);
        assertApproxEqRel(t1, t0, 1, "tsvs");
        assertGt(t0, t1); // The target should round up.
        assertApproxEqRel(v1, v0, 1, "vsvs");
        assertLt(tokensReceived, 2.1e19);
        assertApproxEqRel(tokensReceived, 2.1e19, 1, "tksvs");

        // valueSingle symmetry
        uint256 tokensSent = valueFacet.addValueSingle(
            address(this),
            0xD,
            13e13,
            12e12,
            tokens[2],
            0
        );
        tokensReceived = valueFacet.removeValueSingle(
            address(this),
            0xD,
            13e13,
            12e12,
            tokens[2],
            0
        );
        (, t1, , v1, ) = simplexFacet.getClosureValue(0xD);
        assertApproxEqRel(t1, t0, 1, "tvvs");
        assertGt(t1, t0); // The target should round up.
        assertApproxEqRel(v1, v0, 1, "vvvs");
        assertLt(tokensReceived, tokensSent);
        assertApproxEqRel(tokensReceived, tokensSent, 1e5, "tkvvs");
    }

    function testSymmetryWithFees() public {
        // When fees exist, we lose value so we can't remove the same amount anymore.
        uint256 oneX128 = 1 << 128;
        vm.prank(owner);
        simplexFacet.setClosureFees(0xD, uint128(oneX128 / 10000), 0); // One basis point. Realistic.
        valueFacet.addSingleForValue(
            address(this),
            0xD,
            tokens[2],
            17e18,
            0,
            0
        );
        vm.expectRevert();
        valueFacet.removeSingleForValue(
            address(this),
            0xD,
            tokens[2],
            17e18 - 1,
            0,
            0
        );

        uint256 tokensSent = valueFacet.addValueSingle(
            address(this),
            0xD,
            13e13,
            12e12,
            tokens[2],
            0
        );
        uint256 tokensReceived = valueFacet.removeValueSingle(
            address(this),
            0xD,
            13e13,
            12e12,
            tokens[2],
            0
        );
        assertGt(tokensSent, tokensReceived);
    }

    /// TODO: Test  that add n* value split among n tokens is the same as m*value split among m tokens.

    function testFeeEarn() public {

        uint256 oneX128 = 1 << 128;

        vm.prank(owner);

        simplexFacet.setClosureFees(0xA, uint128(oneX128 / 10000), 0); // One basis point. Realistic.

        valueFacet.addValue(address(this), 0xA, 1e12, 0); // tokens 1 and 3.

        (
            uint256 valueStaked,
            ,
            uint256[MAX_TOKENS] memory earnings,
            uint256 bgtEarnings
        ) = valueFacet.queryValue(address(this), 0xA);


        logAllBalances("balances after owner add 1e12 to test contract: ");

        assertEq(valueStaked, 1e12);
        assertEq(earnings[1], 0);
        assertEq(earnings[3], 0);
        assertEq(bgtEarnings, 0);


        // Collect swap fees.
        (uint256 inAmount , uint256 outAmount) = swapFacet.swap(address(this), tokens[1], tokens[3], 1e10, 0, 0xA);


        // Add log after swap
            console.log("Actual Input Amount: %d", inAmount);
            console.log("Output Amount Received: %d", outAmount);
   

        (, , earnings, bgtEarnings) = valueFacet.queryValue(address(this), 0xA);


        logAllBalances("after swap ");

        assertEq(bgtEarnings, 0);
        assertGt(earnings[1], 0);
        assertEq(earnings[3], 0);


        uint256 earnings1 = earnings[1];
        
        // Collect fees from single adds
        valueFacet.addValueSingle(alice, 0xA, 3e12, 0, tokens[1], 0);

        (, , earnings, bgtEarnings) = valueFacet.queryValue(address(this), 0xA);

        logAllBalances("after alic add value to token[1]");

        // The original position has earned even more fees!
        assertGt(earnings[1], earnings1);

        earnings1 = earnings[1];
        // Also sends more fees to the assets.
        valueFacet.addSingleForValue(alice, 0xA, tokens[1], 6e12, 1 << 255, 0);
        (, , earnings, bgtEarnings) = valueFacet.queryValue(address(this), 0xA);
        assertGt(earnings[1], earnings1);
        assertEq(bgtEarnings, 0);
        earnings1 = earnings[1];

        // We should also collect fees from rehypothecation gains.
        MockERC20(tokens[1]).mint(address(vaults[1]), 3e12);
        (, , earnings, bgtEarnings) = valueFacet.queryValue(address(this), 0xA);
        assertGt(earnings[1], earnings1);
        assertEq(bgtEarnings, 0);
        earnings1 = earnings[1];

        // Now check that the query reported earnings are accurate with respect to our actual collect.
        uint256[4] memory initBalances = getBalances(address(this));
        (
            uint256[MAX_TOKENS] memory collectedBalances,
            uint256 collectedBgt
        ) = valueFacet.collectEarnings(address(this), 0xA);


        uint256[4] memory finalBalances = getBalances(address(this));
        int256[4] memory diffs = diffBalances(finalBalances, initBalances);
        assertEq(collectedBgt, 0);

        assertEq(collectedBalances[1], earnings[1]);
        assertEq(uint256(diffs[1]), collectedBalances[1]);

        // Now we add some value with bgtValue.
        valueFacet.addValue(address(this), 0xA, 5e12, 4e12);
        // We don't quite earn bgt yet without an exchanger.
        MockERC20(tokens[1]).mint(address(vaults[1]), 1e12);
        (, , earnings, bgtEarnings) = valueFacet.queryValue(address(this), 0xA);
        assertEq(bgtEarnings, 0);
        earnings1 = earnings[1];

        vm.startPrank(owner);
        _installBGTExchanger();
        vm.stopPrank();
        // Now when we earn fees, part of it is 1 to 1 exchanged for bgt.
        MockERC20(tokens[1]).mint(address(vaults[1]), 1e12);
        uint256 bgtValueStaked;
        (valueStaked, bgtValueStaked, earnings, bgtEarnings) = valueFacet
            .queryValue(address(this), 0xA);
        assertGt(bgtEarnings, 0);
        assertApproxEqAbs(bgtEarnings + earnings[1], 2 * earnings1, 2);

        /// Test after removing, there are no more fees earned. Test that with query then an add and remove. As in fee claims remain unchanged.
        valueFacet.removeValue(
            address(this),
            0xA,
            uint128(valueStaked),
            uint128(bgtValueStaked)
        );
        MockERC20(tokens[1]).mint(address(vaults[1]), 1e12);
        (, , earnings, bgtEarnings) = valueFacet.queryValue(address(this), 0xA);
        assertEq(earnings[1], 0);
        assertEq(bgtEarnings, 0);
    }



    function testMyauditFeeEarn() public {

        uint256 oneX128 = 1 << 128;

        vm.prank(owner);

        simplexFacet.setClosureFees(0xA, uint128(oneX128 / 10000), 0); // One basis point. Realistic.

        valueFacet.addValue(address(this), 0xA, 1e12, 0); // tokens 1 and 3.

        (
            uint256 valueStaked,
            uint256 bgtValueStaked,
            uint256[MAX_TOKENS] memory earnings,
            uint256 bgtEarnings
        ) = valueFacet.queryValue(address(this), 0xA);

        console.log("\n Test contract Position after testcontract addvalue to testcontract - query value:");
        console.log("Total Value staked: %s", vm.toString(valueStaked));
        console.log("BGT Value staked: %s", vm.toString(bgtValueStaked));
        for(uint i = 0; i< 16; i++) {
            console.log("Token earning %d: %s", i, vm.toString(earnings[i]));
        }
        console.log("BGT Earning: %s", vm.toString(bgtEarnings));


        // Collect swap fees.
        (uint256 inAmount , uint256 outAmount) = swapFacet.swap(address(this), tokens[1], tokens[3], 1e10, 0, 0xA);


        // Add log after swap
            console.log("\n Test contract after testcontract swap 1e10 token[1] with token[4] :");
            console.log("Actual Input Amount: %d", inAmount);
            console.log("Output Amount Received: %d", outAmount);
   

        (valueStaked, bgtValueStaked, earnings, bgtEarnings) = valueFacet.queryValue(address(this), 0xA);

        console.log("\n Test contract Position after testcontract swap 1e10 token[1] with token[4] :- query value:");
        console.log("Total Value: %s", vm.toString(valueStaked));
        console.log("BGT Value: %s", vm.toString(bgtValueStaked));
        for(uint i = 0; i< 16; i++) {
            console.log("Token earning %d: %s", i, vm.toString(earnings[i]));
        }
        console.log("BGT Earning: %s", vm.toString(bgtEarnings));
 
 
        
        // Collect fees from single adds
        valueFacet.addValueSingle(alice, 0xA, 3e12, 0, tokens[1], 0);

        (valueStaked, bgtValueStaked, earnings, bgtEarnings) = valueFacet.queryValue(address(this), 0xA);


        console.log("\n Test contract Position after testcontract add 3e12 token[1] for alice :- query value:");
        console.log("Total Value: %s", vm.toString(valueStaked));
        console.log("BGT Value: %s", vm.toString(bgtValueStaked));
        for(uint i = 0; i< 16; i++) {
            console.log("Token earning %d: %s", i, vm.toString(earnings[i]));
        }
        console.log("BGT Earning: %s", vm.toString(bgtEarnings));


        
  
        // Also sends more fees to the assets.
        valueFacet.addSingleForValue(alice, 0xA, tokens[1], 6e12, 1 << 255, 0);
        (valueStaked, bgtValueStaked, earnings, bgtEarnings) = valueFacet.queryValue(address(this), 0xA);

        
        console.log("\n Test contract Position after testcontract addsingleforvalue 6e12 token[1] for alice :- query value:");
        console.log("Total Value: %s", vm.toString(valueStaked));
        console.log("BGT Value: %s", vm.toString(bgtValueStaked));
        for(uint i = 0; i< 16; i++) {
            console.log("Token earning %d: %s", i, vm.toString(earnings[i]));
        }
        console.log("BGT Earning: %s", vm.toString(bgtEarnings));



        // We should also collect fees from rehypothecation gains.
        MockERC20(tokens[1]).mint(address(vaults[1]), 3e12);
        (valueStaked, bgtValueStaked, earnings, bgtEarnings) = valueFacet.queryValue(address(this), 0xA);
         


        console.log("\n Test contract Position after testcontract mint 3e12 token[1] for vault[1]:- query value:");
        console.log("Total Value: %s", vm.toString(valueStaked));
        console.log("BGT Value: %s", vm.toString(bgtValueStaked));
        for(uint i = 0; i< 16; i++) {
            console.log("Token earning %d: %s", i, vm.toString(earnings[i]));
        }
        console.log("BGT Earning: %s", vm.toString(bgtEarnings));


        // Now check that the query reported earnings are accurate with respect to our actual collect.
        uint256[4] memory initBalances = getBalances(address(this));
        (
            uint256[MAX_TOKENS] memory collectedBalances,
            uint256 collectedBgt
        ) = valueFacet.collectEarnings(address(this), 0xA);



        console.log("\n Test contract earnings after testcontract add 3e12 token[1] for alice :- colletc earnings ");
         
        for(uint i = 0; i< 16; i++) {
            console.log("Token earning %d: %s", i, vm.toString(collectedBalances[i]));
        }
        console.log("collected BGT: %s", vm.toString(collectedBgt));
 

        // Now we add some value with bgtValue.
        valueFacet.addValue(address(this), 0xA, 5e12, 4e12);
        (valueStaked, bgtValueStaked, earnings, bgtEarnings) = valueFacet.queryValue(address(this), 0xA);

        console.log("\n Test contract Position after testcontract addvalue 5e12 and 4e12 bgt:- query value:");
        console.log("Total Value: %s", vm.toString(valueStaked));
        console.log("BGT Value: %s", vm.toString(bgtValueStaked));
        for(uint i = 0; i< 16; i++) {
            console.log("Token earning %d: %s", i, vm.toString(earnings[i]));
        }
        console.log("BGT Earning: %s", vm.toString(bgtEarnings));




        // We don't quite earn bgt yet without an exchanger.
        MockERC20(tokens[1]).mint(address(vaults[1]), 1e12);
        (valueStaked, bgtValueStaked, earnings, bgtEarnings) = valueFacet.queryValue(address(this), 0xA);
         


        console.log("\n Test contract Position after testcontract mint 1e12 for vault[1]:- query value:");
        console.log("Total Value: %s", vm.toString(valueStaked));
        console.log("BGT Value: %s", vm.toString(bgtValueStaked));
        for(uint i = 0; i< 16; i++) {
            console.log("Token earning %d: %s", i, vm.toString(earnings[i]));
        }
        console.log("BGT Earning: %s", vm.toString(bgtEarnings));


        vm.startPrank(owner);
        _installBGTExchanger();
        vm.stopPrank();


        // Now when we earn fees, part of it is 1 to 1 exchanged for bgt.
        MockERC20(tokens[1]).mint(address(vaults[1]), 1e12);
         
        (valueStaked, bgtValueStaked, earnings, bgtEarnings) = valueFacet
            .queryValue(address(this), 0xA);



        console.log("\n Test contract Position after testcontract again mint 1e12 for vault[1]:- query value:");
        console.log("Total Value: %s", vm.toString(valueStaked));
        console.log("BGT Value: %s", vm.toString(bgtValueStaked));
        for(uint i = 0; i< 16; i++) {
            console.log("Token earning %d: %s", i, vm.toString(earnings[i]));
        }
        console.log("BGT Earning: %s", vm.toString(bgtEarnings));



        /// Test after removing, there are no more fees earned. Test that with query then an add and remove. As in fee claims remain unchanged.
        valueFacet.removeValue(
            address(this),
            0xA,
            uint128(valueStaked),
            uint128(bgtValueStaked)
        );
        
        (valueStaked, bgtValueStaked, earnings, bgtEarnings) = valueFacet.queryValue(address(this), 0xA);



        console.log("\n Test contract Position after testcontract remove value :- query value:");
        console.log("Total Value: %s", vm.toString(valueStaked));
        console.log("BGT Value: %s", vm.toString(bgtValueStaked));
        for(uint i = 0; i< 16; i++) {
            console.log("Token earning %d: %s", i, vm.toString(earnings[i]));
        }
        console.log("BGT Earning: %s", vm.toString(bgtEarnings));


        MockERC20(tokens[1]).mint(address(vaults[1]), 1e12);
        (valueStaked, bgtValueStaked, earnings, bgtEarnings) = valueFacet.queryValue(address(this), 0xA);

        console.log("\n Test contract Position after testcontract mint  1e12 for vault[1] :- query value:");
        console.log("Total Value: %s", vm.toString(valueStaked));
        console.log("BGT Value: %s", vm.toString(bgtValueStaked));
        for(uint i = 0; i< 16; i++) {
            console.log("Token earning %d: %s", i, vm.toString(earnings[i]));
        }
        console.log("BGT Earning: %s", vm.toString(bgtEarnings));




         
    }

 
}
