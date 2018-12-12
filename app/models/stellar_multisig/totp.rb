require 'bcrypt'

module StellarMultisig
  class Totp < ApplicationRecord
    include BCrypt

    def passphrase
      @passphrase ||= Password.new(self.passphrase_hash)
    end

    def passphrase=(new_passphrase)
      @passphrase = Password.create(new_passphrase)
      self.passphrase_hash = @passphrase
    end
  end
end
