# Kebash — Rules and App Specification

Version: 1.1  
Status: Rules confirmed; engine implemented in `packages/kebash_engine`  
Name: Kebash

This document records the rules agreed in our discussion and separates them from proposed app and AI behavior.

## 1. Game overview

Two players distribute stones around a board with two rows of six holes. Players collect stones in groups of four during play. At the end of each round, collected stones determine how many holes each player can open for the next round.

The objective is to leave the opponent with fewer than four stones available at the beginning of a round, so they cannot open a single hole.

| Property | Rule |
|---|---|
| Players | Two humans, or a human and an AI |
| Board | Two rows of six holes |
| Ownership | Each player owns one row |
| Total stones | 48 |
| Initial stones per player | 24 |
| Initial stones per hole | Four |
| Direction | Clockwise |
| First round starter | Player 1 |
| Later round starters | Alternate from the previous round’s starter |
| Minimum stones to continue | Four available at the beginning of a round |

## 2. Terms

- **Hole:** A board position owned by one player.
- **Open hole:** A hole participating in the current round. It can contain zero or more stones.
- **Empty open hole:** An open hole containing zero stones. It still receives stones during distribution.
- **Closed hole:** A hole excluded for the entire current round. It is skipped during distribution and contains no stones.
- **Hand:** Stones picked up and currently being distributed by the moving player.
- **Distribution:** Placing one stone into each successive open hole clockwise.
- **Relay pickup:** Picking up all stones in the final destination hole and continuing the same turn.
- **Collection:** Moving stones from a hole into a player’s off-board collection.
- **Reserve:** Stones retained outside the board after setting up a round.
- **Turn:** One chosen starting hole followed by every resulting distribution, collection, and relay pickup until the turn ends.
- **Round:** Play using one fixed arrangement of open and closed holes.
- **Match:** All rounds played until one player cannot open a hole.

## 3. Board layout and direction

The board has two parallel rows, each with six physical positions. Ownership of a position never changes.

### Proposed fixed coordinate convention

Use the following canonical view in the app and rules engine:

```text
                    Player 2
             B1 → B2 → B3 → B4 → B5 → B6
             ↑                        ↓
             A1 ← A2 ← A3 ← A4 ← A5 ← A6
                    Player 1
```

The clockwise physical sequence is:

```text
B1 → B2 → B3 → B4 → B5 → B6 → A6 → A5 → A4 → A3 → A2 → A1 → B1
```

These labels and the fixed viewing orientation are implementation choices. The confirmed rule is clockwise movement on two rows, with each player closing holes from their own left as they sit: Player 1 closes A1 first, Player 2 closes B6 first. Which end closes does not change play, because closed holes are skipped and every open hole starts with four stones.

Closed positions are removed from the active distribution route. For example, if A1 and A2 are closed, the route passes from A3 directly to B1, assuming B1 is open.

The first stone goes into the next open hole after the chosen hole. The chosen hole becomes empty when its stones are picked up. It remains open and can receive stones when distribution travels around the board again. There is no special rule to skip the starting hole on later laps.

## 4. Initial setup

1. Open all 12 holes.
2. Put four stones in each hole.
3. Set both players’ collections and reserves to zero.
4. Set the round number to one.
5. Set Player 1 as both the round starter and the player whose turn is next.

Placing four stones in a hole during setup does **not** trigger collection. Collection rules apply to stones placed during a turn.

## 5. Starting a turn

Before a player chooses a move, count all stones in the open holes on their side.

- If the count is zero, end the round immediately.
- Otherwise, the player chooses one nonempty open hole on their own side.

The player cannot choose an opponent’s hole, an empty hole, or a closed hole.

A hole whose distribution would relay forever without ending is also not a legal choice (see section 6.4).

The chosen hole is the only decision the player makes during that turn. All subsequent distribution and relay pickups follow automatically from the rules.

## 6. Distribution and relay play

1. Pick up every stone from the chosen hole.
2. Move to the next open hole clockwise.
3. Place one stone into that hole.
4. Check whether the hand still contains stones.
5. Apply the appropriate collection or final-stone rule below.

### 6.1 When stones remain in the hand

If the destination now contains exactly four stones:

- Give all four to the **owner of the destination hole**.
- Leave that hole empty and open.
- Continue distributing the stones still in hand.

If the destination contains any other number, leave its stones in place and continue.

This rule can benefit either player, including the opponent of the moving player. A single turn can contain multiple such collections.

### 6.2 When the hand becomes empty

Use the number of stones in the destination **after** placing the final stone:

| Destination count | Action | Turn ends? |
|---|---|---|
| One | Leave the stone there. The hole was empty before the final stone arrived. | Yes |
| Four | Give all four to the moving player, regardless of hole ownership. Leave the hole empty and open. | Yes |
| Any other count | Pick up all stones in the destination and resume distribution from the next open hole. | No |

The moving player collects a final group of four even when the destination belongs to the opponent.

### 6.3 Priority of the final-stone rule

After placing a stone, check whether the hand is empty **before** deciding who receives a group of four.

- More stones in hand: the hole’s owner collects four.
- No stones in hand: the moving player collects four and the turn ends.

Never award the same group to both players. A collection triggers only when the destination count is exactly four; a final destination containing five or more causes a relay pickup.

### 6.4 Never-ending relays

In rare positions a relay sequence returns to an earlier arrangement without any hole reaching four, so the turn would never end. For example, with B5–B6 closed, B1–B4 holding 1, 0, 2, 1 and A1–A6 holding 0, 2, 1, 0, 1, 0, Player 1 choosing A2 repeats the same position every 50 relay pickups.

The rules engine detects these moves before they are played and does not offer them. In simulation about 1 in 9,000 legal moves was of this kind, and the player always had another hole to choose.

If a player has stones but every choice would relay forever, the round ends and each player collects the stones on their own side. This case has not been observed.

## 7. Ending a turn and a round

A normal turn ends when the last stone lands in an empty open hole or creates a group of four.

After a turn ends:

1. Designate the opponent as the next player.
2. Check whether that player has any stones on their side.
3. If they do, start their turn.
4. If they do not, end the round.

Do not check for a round ending in the middle of distribution or between relay pickups. Picking up a player’s last occupied hole can temporarily empty their whole side; their current turn still continues.

A player’s reserve or collection does not let them take a turn if their board side is empty. Those stones are used at the next round setup.

### 7.1 Collecting the remaining board stones

When the next player’s side is empty, the other player collects every stone remaining in their own holes. These stones need not form groups of four.

If both sides are empty, there are no remaining board stones to collect.

After this cleanup, every stone is off the board in a collection or reserve.

## 8. Preparing the next round

For each player, calculate:

```text
available stones = collected stones + previous reserve
```

If a player has fewer than four available stones, that player loses and the match ends. Do this check before starting another round.

Otherwise, calculate:

```text
open holes = min(6, floor(available stones / 4))
stones placed on board = open holes × 4
new reserve = available stones − stones placed on board
closed holes = 6 − open holes
```

Then:

1. Clear the old board arrangement.
2. Close the required number of holes starting from that player’s own left (A1 for Player 1, B6 for Player 2).
3. Open all other holes on that player’s row.
4. Put four stones into each open hole.
5. Keep all unused stones in reserve.
6. Reset the current-round collection to zero, because it has been redistributed into board stones and reserve.
7. Advance the round number.
8. Alternate the round starter and give that player the first turn.

Reserve can exceed three stones when a player has enough to open all six holes. For example, 29 available stones produce six open holes and five reserve stones.

### 8.1 Closing and reopening

The open/closed arrangement is fixed for the whole round.

- Collecting more stones during a round does not reopen holes immediately.
- An open hole becoming empty does not close it.
- Previously closed holes can reopen at the next setup if the owner can afford them.
- A player can never open more than six holes.

| Open holes | Player 1 closed | Player 1 open | Player 2 closed | Player 2 open |
|---|---|---|---|---|
| Six | None | A1–A6 | None | B1–B6 |
| Five | A1 | A2–A6 | B6 | B1–B5 |
| Four | A1–A2 | A3–A6 | B5–B6 | B1–B4 |
| Three | A1–A3 | A4–A6 | B4–B6 | B1–B3 |
| Two | A1–A4 | A5–A6 | B3–B6 | B1–B2 |
| One | A1–A5 | A6 | B2–B6 | B1 |

### 8.2 Round starters

| Round | Starter |
|---|---|
| 1 | Player 1 |
| 2 | Player 2 |
| 3 | Player 1 |
| 4 | Player 2 |

Continue alternating. The starter is determined by the previous **round’s starter**, not by who made the last move, collected more stones, or ended the round.

## 9. Worked examples

The small move examples below describe local situations; stones elsewhere on the board and in reserves are omitted.

### Example A: Final stone enters an empty hole

The player has one stone left in hand. The next open hole is empty.

- Place the stone; the hole now contains one.
- No stones are collected.
- The turn ends.

### Example B: Relay pickup

The player has one stone left in hand. The next hole contains two stones.

- Place the stone; the hole now contains three.
- Pick up all three stones.
- Continue from the next open hole clockwise.
- This remains the same turn.

### Example C: Final stone collects from an opponent

Player 1 has one stone left in hand. The next hole belongs to Player 2 and contains three stones.

- Place the stone; the hole now contains four.
- Player 1 collects all four because this was the final stone.
- The hole becomes empty but stays open.
- Player 1’s turn ends.

### Example D: A collection while distribution continues

Player 1 has three stones in hand. The next hole belongs to Player 2 and contains three stones.

- Place one stone; the hole now contains four and Player 1 still has two stones in hand.
- Player 2 collects the four because Player 2 owns the hole.
- Player 1 continues distributing the remaining two stones.

### Example E: Empty side during an active turn

Player 1 picks up the stones from their only nonempty hole. Their side is now empty.

- The round does not end.
- Player 1 completes the full turn, including any relay pickups.
- Afterward, check Player 2’s side because Player 2 is next to act.

### Example F: End-of-round cleanup and reserves

At a turn boundary:

| Location | Player 1 | Player 2 |
|---|---:|---:|
| Board | 0 | 8 |
| Collected stones | 16 | 16 |
| Existing reserve | 3 | 5 |

There are 48 stones in total. Player 1 is next to act and has none on the board, so the round ends.

Player 2 collects the eight remaining board stones. The next setup is:

| Calculation | Player 1 | Player 2 |
|---|---:|---:|
| Available stones | 16 + 3 = 19 | 16 + 8 + 5 = 29 |
| Open holes | 4 | 6 |
| Board stones | 16 | 24 |
| New reserve | 3 | 5 |

Player 1 closes the two leftmost holes. All six of Player 2’s holes open.

### Example G: Reopening holes

A player had four open holes in one round. At the next setup, they have 23 available stones.

- They open five holes using 20 stones.
- Only the leftmost hole stays closed.
- They keep three stones in reserve.

### Example H: Losing the match

After end-of-round cleanup, a player has three collected stones and no reserve.

- They have only three available stones.
- They cannot fill a hole with four stones.
- They lose; another round does not begin.

## 10. AI opponent — proposed design

The following difficulty system is a proposal for the future app, not an additional traditional game rule.

### 10.1 Shared behavior

All AI levels must:

- Follow exactly the same rules as a human.
- Choose only a nonempty open hole on their own side.
- Use the same rule engine as human play.
- Simulate an entire turn, including all automatic relays and both players’ collections.
- Account for end-of-round cleanup and next-round setup when those occur.
- Never change stone counts, grant themselves extra moves, or bypass closed holes differently from a human.

Assume all board counts, collections, and reserves are visible to both players. This is a proposed app presentation choice.

### 10.2 Difficulty levels

| Level | Decision method | Intended experience |
|---|---|---|
| Easy | Mostly random legal choices; sometimes prefers moves that collect stones | Forgiving and varied |
| Medium | Simulates every legal complete turn and scores the immediate result | Understands immediate gains and gifts |
| Hard | Searches several alternating complete turns, assuming strong opponent replies | Anticipates traps and round endings |
| Expert | Uses a larger search budget, deeper lookahead, and round-transition evaluation | Plans across rounds when feasible |

Actual search depth and thinking time should be tuned after measuring game behavior and app performance. A fixed depth alone may be misleading because one complete turn can contain many relay pickups.

### 10.3 Evaluating a position

Candidate evaluation factors include:

1. **Match result:** A guaranteed win is preferable to any non-winning material gain; avoid a guaranteed loss.
2. **Secured stones:** Collections and reserves are already off the board and cannot be collected by the opponent during the current round.
3. **Round-transition result:** If the round ends, evaluate the cleanup, available totals, open holes, and reserves exactly.
4. **Opponent response:** A move that collects stones now may allow a stronger opposing move next.
5. **Board distribution:** Consider which starting holes and final destinations the remaining arrangement makes possible.
6. **Future open holes:** Consider how the next setup changes each player’s options; test this heuristic rather than assuming that more open holes always means a strategically better position.

Stones currently on a player’s side are not guaranteed future possessions. They may move to the opponent’s side or be collected by either player.

### 10.4 Suggested implementation approach

Start with deterministic simulation and a search algorithm such as minimax with alpha-beta pruning. Machine-learning training is not required for the first version.

For stronger levels, consider iterative deepening, move ordering, and a cache of previously evaluated states. A search state must include board counts, hole status, collections, reserves, the next player, and the round starter, because these can affect future outcomes.

Use seeded randomness for reproducible Easy-mode decisions and tests. Difficulty should change move quality; animation speed should be a separate setting.

## 11. Rules-engine outline

### 11.1 Suggested state

```text
GameState
  board[12]
    owner
    stoneCount
    isOpen
  collected[2]
  reserve[2]
  currentPlayer
  roundStarter
  roundNumber
  phase
  winner, if finished

ActiveTurn
  movingPlayer
  handCount
  currentPosition
```

Suggested phases are `awaiting_move`, `distributing`, `round_cleanup`, `round_setup`, and `finished`.

### 11.2 Complete-turn pseudocode

```text
playTurn(state, chosenHole):
    require phase is awaiting_move
    require current player has stones on their side
    require chosenHole belongs to current player
    require chosenHole is open and nonempty

    mover = currentPlayer
    hand = chosenHole.stoneCount
    chosenHole.stoneCount = 0
    position = chosenHole

    repeat:
        position = nextOpenHoleClockwise(position)
        position.stoneCount += 1
        hand -= 1

        if hand > 0:
            if position.stoneCount == 4:
                collect(position.owner, position)
            continue

        if position.stoneCount == 4:
            collect(mover, position)
            break

        if position.stoneCount == 1:
            break

        hand = position.stoneCount
        position.stoneCount = 0

    currentPlayer = opponent(mover)

    if stonesOnSide(currentPlayer) == 0:
        finishRoundAndPrepareNext()
    else:
        phase = awaiting_move
```

Here, `collect(player, hole)` transfers every stone in that hole into the specified player’s collection, sets its count to zero, and leaves its open status unchanged.

The round-ending routine sweeps the remaining board stones to their owner, combines collections with reserves, checks for a loser, and either finishes the match or sets up the next round with the alternate round starter.

## 12. Verification requirements

### 12.1 Invariants

At every stage, including while a player is holding stones:

```text
board stones + stones in hand + both collections + both reserves = 48
```

Also verify:

- All counts are nonnegative integers.
- Closed holes always contain zero stones.
- Hole ownership never changes.
- Open/closed status does not change within a round.
- Each open hole starts a round with four stones.
- Every collection empties its source hole without closing it.
- Only one player’s turn is active at a time.
- A relay pickup does not switch players.
- Setup does not trigger collection.

### 12.2 Essential rule tests

| Scenario | Expected result |
|---|---|
| Last stone enters an empty open hole | One stone remains; turn ends |
| Last stone enters a hole containing three | Moving player collects four; turn ends |
| Non-final stone enters a hole containing three | Hole owner collects four; distribution continues |
| Last stone enters a hole containing two | Pick up three; continue same turn |
| Last stone enters a hole containing four | Pick up five; continue same turn |
| Route reaches a closed hole | Skip it without placing a stone |
| Route completes a lap to the original open hole | That hole can receive a stone |
| Moving player temporarily empties their side | Continue the active turn |
| Next player has an empty side at the turn boundary | End the round |
| Remaining board stones do not total a multiple of four | Collect all of them in round cleanup |
| A player has 19 available stones at setup | Four open holes; three reserve stones |
| A player has 29 available stones at setup | Six open holes; five reserve stones |
| A player can afford more holes next round | Reopen holes at setup |
| A player collects enough for more holes mid-round | Keep the current closed holes closed |
| A player has fewer than four available stones at setup | That player loses |
| New round begins | Starter alternates from previous round’s starter |

## 13. Proposed app experience

### 13.1 First playable version

- Local two-player mode.
- Human-versus-AI mode with selectable difficulty.
- Two rows of six clearly owned holes.
- Visible counts for every hole, collection, reserve, and stones in hand.
- Distinct appearance for closed holes and empty open holes.
- Highlighted legal starting holes.
- Clockwise direction indicator.
- Animated distribution, relay pickups, and collections.
- A clear indication of who received each collection and why.
- Round number, current player, and round starter display.
- Round summary showing cleanup stones, available totals, holes opened, and reserve.
- Match result when a player cannot open a hole.

### 13.2 Helpful controls

Proposed options include adjustable animation speed, a skip-animation control, and a practice mode with move explanations. Undo and hints should be explicit mode features, especially for two-human play.

The interface should animate events generated by the rules engine rather than contain its own separate copy of the rules. This helps keep human play, AI simulation, replays, and tests consistent.

## 14. Decisions

Resolved:

1. **Meaning of left:** Each player closes from their own left: A1 first for Player 1, B6 first for Player 2.
2. **Never-ending relays:** They are reachable. A move that would relay forever is not legal (section 6.4).
3. **Match length:** Elimination only. A match is played until one player cannot open a hole; there is no round limit or draw rule. Simulated matches always reached a winner.
4. **Name, platform, languages:** Kebash, built with Flutter, in Arabic and English.

Still open:

1. **AI tuning:** Select search budgets and evaluation weights using measured performance and human playtesting.
2. **Seat balance:** With two equal search-based AIs, Player 2 won far more often than Player 1. Check with human play whether the second seat has a real advantage.
3. **Product choices:** Visual style, sound, and whether later versions need online multiplayer.
