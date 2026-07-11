import FungibleToken from 0xee82856bf20e2aa6
import NonFungibleToken from 0xf8d6e0586b0a20c7
import ExampleToken from 0xf8d6e0586b0a20c7
import ExampleNFT from 0xf8d6e0586b0a20c7

access(all) contract Marketplace {

    access(all) var nextListingId: UInt64
    access(all) var listings: @{UInt64: Listing}

    access(all) event ListingListed(id: UInt64, nftId: UInt64, seller: Address, price: UFix64)
    access(all) event ListingSold(id: UInt64, nftId: UInt64, seller: Address, buyer: Address, price: UFix64)
    access(all) event ListingCancelled(id: UInt64, nftId: UInt64, seller: Address)

    access(all) resource Listing {
        access(all) let id: UInt64
        access(all) let nftId: UInt64
        access(all) let nftCapability: Capability<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>
        access(all) let price: UFix64
        access(all) let seller: Address

        init(id: UInt64, nftId: UInt64,
             nftCapability: Capability<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>,
             price: UFix64, seller: Address) {
            self.id = id
            self.nftId = nftId
            self.nftCapability = nftCapability
            self.price = price
            self.seller = seller
        }
    }

    access(all) fun listNFT(nftId: UInt64, price: UFix64, seller: Address,
                            nftCapability: Capability<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>): UInt64 {
        pre {
            price > 0.0: "Price must be greater than zero"
        }

        assert(nftCapability.check<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(),
               message: "Capability is invalid or expired")

        let id = self.nextListingId
        let listing <- create Listing(
            id: id,
            nftId: nftId,
            nftCapability: nftCapability,
            price: price,
            seller: seller
        )
        self.listings[id] <-! listing
        self.nextListingId = self.nextListingId + 1

        emit ListingListed(id: id, nftId: nftId, seller: seller, price: price)
        return id
    }

    access(all) fun buyNFT(listingId: UInt64, payment: @FungibleToken.Vault, buyer: Address) {
        pre {
            payment.balance == self.listings[listingId]?.price: "Payment must match listing price"
        }

        let listing <- self.listings.remove(key: listingId)
            ?? panic("Listing not found")

        // Withdraw NFT from seller using stored capability
        let collectionRef = listing.nftCapability.borrow()
            ?? panic("NFT capability no longer valid")
        let nft <- collectionRef.withdraw(withdrawID: listing.nftId)

        // Deposit NFT to buyer's collection
        let buyerNFTCap = getAccount(buyer).capabilities.get<&{NonFungibleToken.CollectionPublic}>(
            /public/exampleNFTCollection
        ) ?? panic("Buyer has no public NFT collection")
        let buyerNFTRef = buyerNFTCap.borrow()
            ?? panic("Failed to borrow buyer's NFT collection")
        buyerNFTRef.deposit(token: <- nft)

        // Send payment to seller's token receiver
        let sellerCap = getAccount(listing.seller).capabilities.get<&{FungibleToken.Receiver}>(
            /public/exampleTokenReceiver
        ) ?? panic("Seller has no public token receiver")
        let sellerRef = sellerCap.borrow()
            ?? panic("Failed to borrow seller's token receiver")
        sellerRef.deposit(from: <- payment)

        emit ListingSold(id: listingId, nftId: listing.nftId,
                         seller: listing.seller, buyer: buyer,
                         price: listing.price)

        destroy listing
    }

    access(all) fun cancelListing(listingId: UInt64, seller: Address) {
        pre {
            self.listings[listingId]?.seller == seller: "Only the seller can cancel this listing"
        }

        let listing <- self.listings.remove(key: listingId)
            ?? panic("Listing not found")

        emit ListingCancelled(id: listingId, nftId: listing.nftId, seller: seller)

        destroy listing
    }

    init() {
        self.nextListingId = 1
        self.listings = {}
    }
}
