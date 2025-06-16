module nft::simple_portraits {
    use std::string::{Self, String};
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::display;
    use sui::package;
    use sui::transfer_policy as policy;
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::coin::{Coin};
    use sui::sui::SUI;
    use nft::rules::{Self, RULES, RoyaltyConfig};

    // Error codes
    const EExceedsMintSupply: u64 = 1;
    const ENotCreator: u64 = 2;

    // One-time witness type
    public struct SIMPLE_PORTRAITS has drop {}

    // NFT type
    public struct PortraitNFT has key, store {
        id: UID,
        name: String,
        description: String,
        image_url: String,
        creator: address,
        mint_number: u64,
    }

    // Collection struct
    public struct Collection has key, store {
        id: UID,
        mint_supply: u64,
        minted: u64,
        creator: address,
    }

    fun init(witness: SIMPLE_PORTRAITS, ctx: &mut TxContext) {
        let publisher = package::claim(witness, ctx);
        let mut display = display::new<PortraitNFT>(&publisher, ctx);
        display::add(&mut display, string::utf8(b"name"), string::utf8(b"{name} #{mint_number}"));
        display::add(&mut display, string::utf8(b"description"), string::utf8(b"{description}"));
        display::add(&mut display, string::utf8(b"image_url"), string::utf8(b"{image_url}"));
        display::add(&mut display, string::utf8(b"creator"), string::utf8(b"{creator}"));
        display::update_version(&mut display);
        transfer::public_share_object(display);

        let (mut policy_obj, cap) = policy::new<PortraitNFT>(&publisher, ctx);
        // Add rules to the transfer policy
        let royalty_config = rules::new_royalty_config(100, 0); // 1% royalty (100 basis points), no min amount
        rules::add_personal_kiosk_rule(&mut policy_obj, &cap);
        rules::add_kiosk_lock_rule(&mut policy_obj, &cap);
        rules::add_royalty_rule(&mut policy_obj, &cap, royalty_config);
        transfer::public_share_object(policy_obj);
        transfer::public_transfer(cap, tx_context::sender(ctx));
        transfer::public_transfer(publisher, tx_context::sender(ctx));
    }

    // Create a new collection
    public fun create_collection(
        mint_supply: u64,
        ctx: &mut TxContext
    ): Collection {
        Collection {
            id: object::new(ctx),
            mint_supply,
            minted: 0,
            creator: tx_context::sender(ctx),
        }
    }

    // Create a new kiosk
    public fun create_kiosk(ctx: &mut TxContext): (Kiosk, KioskOwnerCap) {
        kiosk::new(ctx)
    }

    // Mint an NFT and place it in a kiosk
    public fun mint_nft_to_kiosk(
        collection: &mut Collection,
        kiosk: &mut Kiosk,
        cap: &KioskOwnerCap,
        name: String,
        description: String,
        image_url: String,
        ctx: &mut TxContext
    ) {
        assert!(collection.minted < collection.mint_supply, EExceedsMintSupply);
        assert!(collection.creator == tx_context::sender(ctx), ENotCreator);

        collection.minted = collection.minted + 1;
        let nft = PortraitNFT {
            id: object::new(ctx),
            name,
            description,
            image_url,
            creator: collection.creator,
            mint_number: collection.minted,
        };
        kiosk::place(kiosk, cap, nft);
    }

    // Mint and transfer NFT to recipient's kiosk (requires payment for royalty)
    public fun mint_and_transfer_to_kiosk(
        collection: &mut Collection,
        kiosk: &mut Kiosk,
        cap: &KioskOwnerCap,
        policy: &mut policy::TransferPolicy<PortraitNFT>,
        name: String,
        description: String,
        image_url: String,
        recipient: address,
        payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(collection.minted < collection.mint_supply, EExceedsMintSupply);
        assert!(collection.creator == tx_context::sender(ctx), ENotCreator);

        collection.minted = collection.minted + 1;
        let nft = PortraitNFT {
            id: object::new(ctx),
            name,
            description,
            image_url,
            creator: collection.creator,
            mint_number: collection.minted,
        };
        let nft_id = object::id(&nft);
        kiosk::place(kiosk, cap, nft);
        let mut request = policy::new_request(nft_id, payment.value(), object::id_from_address(recipient));
        rules::prove_personal_kiosk_rule(kiosk, policy, &mut request);
        rules::prove_kiosk_lock_rule(kiosk, policy, &mut request);
        rules::pay_royalty_rule(policy, &mut request, payment);
        policy::confirm_request(policy, request);
    }

    // Update mint supply
    public fun update_mint_supply(
        collection: &mut Collection,
        new_supply: u64,
        ctx: &mut TxContext
    ) {
        assert!(collection.creator == tx_context::sender(ctx), ENotCreator);
        assert!(collection.minted <= new_supply, EExceedsMintSupply);
        collection.mint_supply = new_supply;
    }

    // Get minted count
    public fun get_minted_count(collection: &Collection): u64 {
        collection.minted
    }
}



// module nft::simple_portraits {
//     use std::string::{Self, String};
//     use sui::object::{Self, UID};
//     use sui::tx_context::{Self, TxContext};
//     use sui::transfer;
//     use sui::display;
//     use sui::package;
//     use sui::transfer_policy as policy;
//     use sui::kiosk::{Kiosk};
//     use sui::coin::{Coin};
//     use sui::sui::SUI;
//     use nft::rules::{Self, RULES};

//     // Error codes
//     const EExceedsMintSupply: u64 = 1;
//     const ENotCreator: u64 = 2;

//     // One-time witness type
//     public struct SIMPLE_PORTRAITS has drop {}

//     // NFT type
//     public struct PortraitNFT has key, store {
//         id: UID,
//         name: String,
//         description: String,
//         image_url: String,
//         creator: address,
//         mint_number: u64,
//     }
    
//     fun init(witness: SIMPLE_PORTRAITS, ctx: &mut TxContext) {
//         let publisher = package::claim(witness, ctx);
//         let mut display = display::new<PortraitNFT>(&publisher, ctx);
//         display::add(&mut display, string::utf8(b"name"), string::utf8(b"{name} #{mint_number}"));
//         display::add(&mut display, string::utf8(b"description"), string::utf8(b"{description}"));
//         display::add(&mut display, string::utf8(b"image_url"), string::utf8(b"{image_url}"));
//         display::add(&mut display, string::utf8(b"creator"), string::utf8(b"{creator}"));
        
//         display::update_version(&mut display);
//         transfer::public_share_object(display);

//         let (mut policy_obj, cap) = policy::new<PortraitNFT>(&publisher, ctx);
//         transfer::public_share_object(policy_obj);
//         transfer::public_transfer(cap, tx_context::sender(ctx));
//         transfer::public_transfer(publisher, tx_context::sender(ctx));
//     }

//     // Collection struct
//     public struct Collection has key, store {
//         id: UID,
//         mint_supply: u64,
//         minted: u64,
//         creator: address,
//     }

//     // Create a new collection
//     public fun create_collection(
//         mint_supply: u64,
//         ctx: &mut TxContext
//     ): Collection {
//         Collection {
//             id: object::new(ctx),
//             mint_supply,
//             minted: 0,
//             creator: tx_context::sender(ctx),
//         }
//     }

//     // Mint an NFT
//     public fun mint_nft(
//         collection: &mut Collection,
//         name: String,
//         description: String,
//         image_url: String,
//         ctx: &mut TxContext
//     ): PortraitNFT {
//         assert!(collection.minted < collection.mint_supply, EExceedsMintSupply);
//         assert!(collection.creator == tx_context::sender(ctx), ENotCreator);

//         collection.minted = collection.minted + 1;
//         PortraitNFT {
//             id: object::new(ctx),
//             name,
//             description,
//             image_url,
//             creator: collection.creator,
//             mint_number: collection.minted,
//         }
//     }

//     // Mint and transfer NFT to recipient
//     public fun mint_and_transfer(
//         collection: &mut Collection,
//         name: String,
//         description: String,
//         image_url: String,
//         recipient: address,
//         ctx: &mut TxContext
//     ) {
//         let nft = mint_nft(collection, name, description, image_url, ctx);
//         transfer::public_transfer(nft, recipient);
//     }

//     // Update mint supply
//     public fun update_mint_supply(
//         collection: &mut Collection,
//         new_supply: u64,
//         ctx: &mut TxContext
//     ) {
//         assert!(collection.creator == tx_context::sender(ctx), ENotCreator);
//         assert!(collection.minted <= new_supply, EExceedsMintSupply);
//         collection.mint_supply = new_supply;
//     }

//     // Get minted count
//     public fun get_minted_count(collection: &Collection): u64 {
//         collection.minted
//     }
// }