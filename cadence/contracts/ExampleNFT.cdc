import NonFungibleToken from 0xf8d6e0586b0a20c7


access(all) contract ExampleNFT: NonFungibleToken {

    access(all) var totalSupply: UInt64

    access(all) event NFTMinted(id: UInt64, metadata: {String: String}, to: Address)

    access(all) resource NFT: NonFungibleToken.NFT {
        access(all) let id: UInt64
        access(all) var metadata: {String: String}

        init(id: UInt64, metadata: {String: String}) {
            self.id = id
            self.metadata = metadata
        }

        access(all) view fun getViews(): [Type] {
            return []
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return nil
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- create Collection()
        }
    }

    access(all) resource Collection: NonFungibleToken.Collection {
        access(all) var ownedNFTs: @{UInt64: {NonFungibleToken.NFT}}

        init() {
            self.ownedNFTs <- {}
        }

        access(NonFungibleToken.Withdraw) fun withdraw(withdrawID: UInt64): @{NonFungibleToken.NFT} {
            let nft <- self.ownedNFTs.remove(key: withdrawID)
                ?? panic("NFT not found in collection")
            return <- nft
        }

        access(all) fun deposit(token: @{NonFungibleToken.NFT}) {
            let nft <- token as! @NFT
            let id = nft.id
            let oldToken <- self.ownedNFTs[id] <- nft
            destroy oldToken
        }

        access(all) view fun getLength(): Int {
            return self.ownedNFTs.length
        }

        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        access(all) fun forEachID(_ f: fun (UInt64): Bool): Void {
            self.ownedNFTs.forEachKey(f)
        }

        access(all) view fun borrowNFT(_ id: UInt64): &{NonFungibleToken.NFT}? {
            return &self.ownedNFTs[id]
        }

        access(all) view fun getSupportedNFTTypes(): {Type: Bool} {
            return {Type<@NFT>(): true}
        }

        access(all) view fun isSupportedNFTType(type: Type): Bool {
            return type == Type<@NFT>()
        }

        access(all) fun createEmptyCollection(): @{NonFungibleToken.Collection} {
            return <- create Collection()
        }

        access(all) view fun getViews(): [Type] {
            return []
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return nil
        }
    }

    access(all) resource Minter {
        access(all) fun mintNFT(metadata: {String: String}, recipient: Address): @NFT {
            ExampleNFT.totalSupply = ExampleNFT.totalSupply + 1
            let newId = ExampleNFT.totalSupply
            let nft <- create NFT(id: newId, metadata: metadata)
            emit NFTMinted(id: newId, metadata: metadata, to: recipient)
            return <- nft
        }
    }

    access(all) fun createEmptyCollection(nftType: Type): @{NonFungibleToken.Collection} {
        return <- create Collection()
    }

    access(all) fun createMinter(): @Minter {
        return <- create Minter()
    }

    access(all) view fun getContractViews(resourceType: Type?): [Type] {
        return []
    }

    access(all) fun resolveContractView(resourceType: Type?, viewType: Type): AnyStruct? {
        return nil
    }

    init() {
        self.totalSupply = 0
    }
}       
