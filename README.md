# Marketplace On Flow

Seller                   Marketplace                Buyer
  |                          |                       |
  |-- createListing(id,price)->|                      |
  |   (grants cap to pull NFT)|                      |
  |                          |-- stores Listing       |
  |                          |   resource with cap    |
  |                          |                       |
  |                          |<--- buy(listingID) ---|
  |                          |   (Buyer sends FT)    |
  |                          |                       |
  |<-- FT payment via cap ---|                       |
  |                          |--- NFT via cap ------>|
  |                          |  (to Buyer's Collection)
