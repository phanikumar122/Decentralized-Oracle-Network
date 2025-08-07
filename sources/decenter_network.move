module phani_addr::DecentralizedOracle {
    use aptos_framework::signer;
    use aptos_framework::coin;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::timestamp;

    /// Struct representing an oracle provider in the network
    struct OracleProvider has store, key {
        reputation_score: u64,     // Reputation score based on accuracy
        total_submissions: u64,    // Total number of data submissions
        stake_amount: u64,         // Staked tokens for network participation
        is_active: bool,           // Whether the oracle is active
    }

    /// Struct representing a data feed from the oracle network
    struct DataFeed has store, key {
        value: u64,               // The oracle data value
        timestamp: u64,           // When the data was last updated
        provider_count: u64,      // Number of providers who submitted this round
        total_stake: u64,         // Total stake backing this data
    }

    /// Function to register as an oracle provider with minimum stake
    public fun register_oracle_provider(
        provider: &signer, 
        stake_amount: u64
    ) {
        // Require minimum stake to participate
        assert!(stake_amount >= 1000, 1); // Minimum 1000 tokens
        
        // Transfer stake to contract (simplified - in real implementation would lock tokens)
        let stake = coin::withdraw<AptosCoin>(provider, stake_amount);
        coin::deposit<AptosCoin>(signer::address_of(provider), stake);
        
        let oracle = OracleProvider {
            reputation_score: 100,  // Start with base reputation
            total_submissions: 0,
            stake_amount,
            is_active: true,
        };
        
        move_to(provider, oracle);
    }

    /// Function to submit oracle data and update the network feed
    public fun submit_oracle_data(
        provider: &signer,
        data_feed_owner: address,
        new_value: u64
    ) acquires OracleProvider, DataFeed {
        let provider_addr = signer::address_of(provider);
        let oracle = borrow_global_mut<OracleProvider>(provider_addr);
        
        // Ensure oracle is active and has stake
        assert!(oracle.is_active, 2);
        assert!(oracle.stake_amount > 0, 3);
        
        // Update provider statistics
        oracle.total_submissions = oracle.total_submissions + 1;
        
        // Update or create data feed
        if (exists<DataFeed>(data_feed_owner)) {
            let feed = borrow_global_mut<DataFeed>(data_feed_owner);
            feed.value = new_value;
            feed.timestamp = timestamp::now_microseconds();
            feed.provider_count = feed.provider_count + 1;
            feed.total_stake = feed.total_stake + oracle.stake_amount;
        } else {
            let feed = DataFeed {
                value: new_value,
                timestamp: timestamp::now_microseconds(),
                provider_count: 1,
                total_stake: oracle.stake_amount,
            };
            move_to(provider, feed);
        };
    }
}

