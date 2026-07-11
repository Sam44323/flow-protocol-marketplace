import ExampleToken from 0xf8d6e0586b0a20c7

// Assuming ExampleToken is deployed to emulator-account

transaction {

prepare(signer: auth(Storage, Capabilities) &Account) {
    // Save Minter to deployer's storage (only do this once)

    let minter <- ExampleToken.createMinter()
    signer.storage.save(<- minter, to: /storage/exampleTokenMinter)

    // Create empty vault and save it
    let vault <- ExampleToken.createEmptyVault()
    signer.storage.save(<- vault, to: /storage/exampleTokenVault)

    // Publish a public Receiver capability so others can send tokens to us
    let cap = signer.capabilities.storage.issue<&ExampleToken.Vault>(/storage/exampleTokenVault)
    signer.capabilities.publish(cap, at: /public/exampleTokenReceiver)
  }
}
