module nft::rules {
    use std::string;
    use sui::transfer_policy as policy;
    use sui::kiosk::{Kiosk};
    use sui::coin::{Coin};
    use sui::sui::SUI;
    use kiosk::personal_kiosk_rule;
    use kiosk::kiosk_lock_rule;
    use kiosk::royalty_rule;

    // Witness type for rules
    public struct RULES has drop {}

    // Royalty configuration
    public struct RoyaltyConfig has store, drop {
        basis_points: u16, // Changed to u16
        min_amount: u64,
    }

    // Create new royalty config
    public fun new_royalty_config(basis_points: u16, min_amount: u64): RoyaltyConfig {
        RoyaltyConfig { basis_points, min_amount }
    }

    // Add personal kiosk rule
    public fun add_personal_kiosk_rule<T: key + store>(
        policy: &mut policy::TransferPolicy<T>,
        cap: &policy::TransferPolicyCap<T>,
    ) {
        personal_kiosk_rule::add(policy, cap);
    }

    // Add kiosk lock rule
    public fun add_kiosk_lock_rule<T: key + store>(
        policy: &mut policy::TransferPolicy<T>,
        cap: &policy::TransferPolicyCap<T>,
    ) {
        kiosk_lock_rule::add(policy, cap);
    }

    // Add royalty rule
    public fun add_royalty_rule<T: key + store>(
        policy: &mut policy::TransferPolicy<T>,
        cap: &policy::TransferPolicyCap<T>,
        config: RoyaltyConfig,
    ) {
        royalty_rule::add(policy, cap, config.basis_points, config.min_amount);
    }

    // Prove personal kiosk rule
    public fun prove_personal_kiosk_rule<T: key + store>(
        kiosk: &Kiosk,
        policy: &mut policy::TransferPolicy<T>,
        request: &mut policy::TransferRequest<T>
    ) {
        personal_kiosk_rule::prove(kiosk, request);
    }

    // Prove kiosk lock rule
    public fun prove_kiosk_lock_rule<T: key + store>(
        kiosk: &Kiosk,
        policy: &mut policy::TransferPolicy<T>,
        request: &mut policy::TransferRequest<T>
    ) {
        kiosk_lock_rule::prove(request, kiosk);
    }

    // Pay royalty rule
    public fun pay_royalty_rule<T: key + store>(
        policy: &mut policy::TransferPolicy<T>,
        request: &mut policy::TransferRequest<T>,
        payment: Coin<SUI>,
    ) {
        royalty_rule::pay(policy, request, payment);
    }

    // Get royalty fee amount
    public fun get_royalty_fee_amount<T: key + store>(
        policy: &policy::TransferPolicy<T>,
        paid: u64
    ): u64 {
        royalty_rule::fee_amount(policy, paid)
    }
}