# ✨ So you want to sponsor a contest

This `README.md` contains a set of checklists for our contest collaboration.

Your contest will use two repos: 
- **a _contest_ repo** (this one), which is used for scoping your contest and for providing information to contestants (wardens)
- **a _findings_ repo**, where issues are submitted (shared with you after the contest) 

Ultimately, when we launch the contest, this contest repo will be made public and will contain the smart contracts to be reviewed and all the information needed for contest participants. The findings repo will be made public after the contest report is published and your team has mitigated the identified issues.

Some of the checklists in this doc are for **C4 (🐺)** and some of them are for **you as the contest sponsor (⭐️)**.

---

# Repo setup

## ⭐️ Sponsor: Add code to this repo

- [ ] Create a PR to this repo with the below changes:
- [ ] Provide a self-contained repository with working commands that will build (at least) all in-scope contracts, and commands that will run tests producing gas reports for the relevant contracts.
- [ ] Make sure your code is thoroughly commented using the [NatSpec format](https://docs.soliditylang.org/en/v0.5.10/natspec-format.html#natspec-format).
- [ ] Please have final versions of contracts and documentation added/updated in this repo **no less than 24 hours prior to contest start time.**
- [ ] Be prepared for a 🚨code freeze🚨 for the duration of the contest — important because it establishes a level playing field. We want to ensure everyone's looking at the same code, no matter when they look during the contest. (Note: this includes your own repo, since a PR can leak alpha to our wardens!)


---

## ⭐️ Sponsor: Edit this README

Under "SPONSORS ADD INFO HERE" heading below, include the following:

- [ ] Modify the bottom of this `README.md` file to describe how your code is supposed to work with links to any relevent documentation and any other criteria/details that the C4 Wardens should keep in mind when reviewing. ([Here's a well-constructed example.](https://github.com/code-423n4/2022-08-foundation#readme))
  - [ ] When linking, please provide all links as full absolute links versus relative links
  - [ ] All information should be provided in markdown format (HTML does not render on Code4rena.com)
- [ ] Under the "Scope" heading, provide the name of each contract and:
  - [ ] source lines of code (excluding blank lines and comments) in each
  - [ ] external contracts called in each
  - [ ] libraries used in each
- [ ] Describe any novel or unique curve logic or mathematical models implemented in the contracts
- [ ] Does the token conform to the ERC-20 standard? In what specific ways does it differ?
- [ ] Describe anything else that adds any special logic that makes your approach unique
- [ ] Identify any areas of specific concern in reviewing the code
- [ ] Optional / nice to have: pre-record a high-level overview of your protocol (not just specific smart contract functions). This saves wardens a lot of time wading through documentation.
- [ ] See also: [this checklist in Notion](https://code4rena.notion.site/Key-info-for-Code4rena-sponsors-f60764c4c4574bbf8e7a6dbd72cc49b4#0cafa01e6201462e9f78677a39e09746)
- [ ] Delete this checklist and all text above the line below when you're ready.

---

# Timeswap contest details
- Total Prize Pool: $90,000 USDC
  - HM awards: $63,750 USDC 
  - QA report awards: $7,500 USDC 
  - Gas report awards: $3,750 USDC 
  - Judge + presort awards: $15,000 USDC
  - Scout awards: $500 USDC
- Join [C4 Discord](https://discord.gg/code4rena) to register
- Submit findings [using the C4 form](https://code4rena.com/contests/2023-01-timeswap-contest/submit)
- [Read our guidelines for more details](https://docs.code4rena.com/roles/wardens)
- Starts January 20, 2023 20:00 UTC
- Ends January 27, 2023 20:00 UTC

## C4udit / Publicly Known Issues

The C4audit output for the contest can be found [here](add link to report) within an hour of contest opening.

*Note for C4 wardens: Anything included in the C4udit output is considered a publicly known issue and is ineligible for awards.*

[ ⭐️ SPONSORS ADD INFO HERE ]

# Overview

*Please provide some context about the code being audited, and identify any areas of specific concern in reviewing the code. (This is a good place to link to your docs, if you have them.)*

# Scope

*List all files in scope in the table below (along with hyperlinks) -- and feel free to add notes here to emphasize areas of focus.*

*For line of code counts, we recommend using [cloc](https://github.com/AlDanial/cloc).* 

| Contract | SLOC | Purpose | Libraries used |  
| ----------- | ----------- | ----------- | ----------- |
| [packages/v2-library/contracts/BytesLib.sol](packages/v2-library/contracts/BytesLib.sol) | 33 |Bytes Array utils  |  |
| [packages/v2-library/contracts/SafeCast.sol](packages/v2-library/contracts/SafeCast.sol) | 18 |Library for castings  |  |
| [packages/v2-library/contracts/FullMath.sol](packages/v2-library/contracts/FullMath.sol)| 140 |Math utils  |  |
| [packages/v2-library/contracts/Error.sol](packages/v2-library/contracts/Error.sol) | 63 | Error utils  |  |
| [packages/v2-library/contracts/Math.sol](packages/v2-library/contracts/Math.sol) | 91 | Math utils  |  |
| [packages/v2-library/contracts/Ownership.sol](packages/v2-library/contracts/Ownership.sol) | 20 |Ownership utils  |  |
| [packages/v2-library/contracts/StrikeConversion.sol](packages/v2-library/contracts/StrikeConversion.sol) | 28 |Strike conversion utils  |  |
| [packages/v2-library/contracts/CatchError.sol](packages/v2-library/contracts/CatchError.sol) | 6 |Error utils  |  |

## Out of scope

*List any files/contracts that are out of scope for this audit.*

# Additional Context

*Describe any novel or unique curve logic or mathematical models implemented in the contracts*

*Sponsor, please confirm/edit the information below.*

## Scoping Details 
```
- If you have a public code repo, please share it here: N/A
- How many contracts are in scope?: 4 
- Total SLoC for these contracts?: 3310
- How many external imports are there?: 4
- How many separate interfaces and struct definitions are there for the contracts within scope?: 19 and 38
- Does most of your code generally use composition or inheritance?: Primarily inheritance, but composition is also leveraged up to some degree.  
- How many external calls?: 0
  - What is the overall line coverage percentage provided by your tests?: 50
- Is there a need to understand a separate part of the codebase / get context in order to audit this part of the protocol?: No  
- Please describe required context: N/A  
- Does it use an oracle?: No
- Does the token conform to the ERC20 standard?: Yes
- Are there any novel or unique curve logic or mathematical models?: We use a 3 variable AMM - (x+y)z=k
- Does it use a timelock function?: No
- Is it an NFT?: No
- Does it have an AMM?: Yes
- Is it a fork of a popular project?: No  
- Does it use rollups?: No
- Is it multi-chain?: No  
- Does it use a side-chain?: Yes and it evm-compatible.
```

# Tests

Tests are currently work in progress, the setup to run the tests is described below