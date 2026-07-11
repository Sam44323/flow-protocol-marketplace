import ExampleToken from 0xf8d6e0586b0a20c7

transaction(amount: UFix64) {

    prepare(signer: auth(Storage) &Account) {
        // Here borrow Minter from signer's storage (only deployer can do this)
        let minter = signer.storage.borrow<&ExampleToken.Minter>(from: /storage/exampleTokenMinter)
            ?? panic("Minter not found in signer's storage")

        // Mint the tokens — creates a new Vault resource
        let mintedVault <- minter.mintTokens(amount: amount)

        // Here borrow our vault and deposit the minted tokens
        let vault = signer.storage.borrow<&ExampleToken.Vault>(from: /storage/exampleTokenVault)
            ?? panic("Vault not found in signer's storage")
        vault.deposit(from: <- mintedVault)
    }
}
