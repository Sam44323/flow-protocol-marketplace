// FT-Contract from pre-deployed contract
import FungibleToken from 0xee82856bf20e2aa6


access(all) contract ExampleToken {

    access(all) var totalSupply: UFix64

    access(all) event TokensMinted(amount: UFix64, to: Address?)
    access(all) event TokensWithdrawn(amount: UFix64, from: Address?)
    access(all) event TokensDeposited(amount: UFix64, to: Address?)

    access(all) resource Vault: FungibleToken.Vault {

        access(all) var balance: UFix64

        // setting the balance on initialization
        init(balance: UFix64) {
            self.balance = balance
        }

        // required by FT.Vault interface
        access(all) view fun isAvailableToWithdraw(amount: UFix64): Bool {
            return self.balance >= amount
        }

        // Required by FT.Balance interface
        access(all) view fun getBalance(): UFix64 {
            return self.balance
        }

        access(all) view fun getSupportedVaultTypes(): {Type: Bool} {
            return {self.getType(): true}
        }

        access(all) view fun isSupportedVaultType(type: Type): Bool {
            return type == self.getType()
        }

        access(all) fun createEmptyVault(): @{FungibleToken.Vault} {
            return <- create Vault(balance: 0.0)
        }

        access(all) view fun getViews(): [Type] {
            return []
        }

        access(all) fun resolveView(_ view: Type): AnyStruct? {
            return nil
        }

        // auth(Withdraw) required — security gate. @ prefix = resource return type
        access(FungibleToken.Withdraw) fun withdraw(amount: UFix64): @{FungibleToken.Vault} {
            post {
                result.balance == amount:
                    "Withdrawal amount must match the balance of the withdrawn Vault"
            }
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            
            // create a new Vault resource and return it
            return <- create Vault(balance: amount)
        }

        access(all) fun deposit(from: @{FungibleToken.Vault}) {
            // takes a generic Vault, does a downcast and errors if that vault is not of ExampleToken.Vault type
            let vault <- from as! @ExampleToken.Vault

            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)

            // here destroying the vault
            destroy vault
        }
        
    }

    // only this contract can mint the new-tokens
    // because access(all) is set on the resource which is stored in the storage of this deployer's account
    // and because this resource is not enititled with any capability in pub or priv storage, it can't be called by anyone else
    access(all) resource Minter {

        access(all) fun mintTokens(amount: UFix64): @Vault {
            post {
                result.balance == amount:
                    "Minted Vault must have the specified amount"
            }
            ExampleToken.totalSupply = ExampleToken.totalSupply + amount
            emit TokensMinted(amount: amount, to: nil)
            return <- create Vault(balance: amount)
        }
    }

    access(all) fun createEmptyVault(): @Vault {
        return <- create Vault(balance: 0.0)
    }

    access(all) fun createMinter(): @Minter {
        return <- create Minter()
    }

    init() {
        self.totalSupply = 0.0
    }
}
