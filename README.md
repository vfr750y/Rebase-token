# Cross-chain Rebase Token
1. A protocol that allows user to deposit into a vault and in tern, receive rebase tokens that represent their underlying balance.
2. Rebase token -> balanceOf function is dynamic to show the changing balance with time.
    - balance increases linearly with time.
    - mint tokens to our users every time they perform an action  (minting, burning, transferring, or bridging).
    3 - Interest rate. The rate at which the balance increases linearly with time. 
        - individually set an interest rate for each user based on some global interest rate of the protocol at the time the user deposits into the vault.
        - This global interest rate can only decrease to incentivise/reward early adopters.
        (if you deposit earlier you will have a higher interest rate than if you deposit later.)
    