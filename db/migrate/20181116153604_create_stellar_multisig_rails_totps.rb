class CreateStellarMultisigRailsTotps < ActiveRecord::Migration[5.2]
  def change
    create_table :stellar_multisig_rails_totps do |t|
      t.string :address
      t.string :passphrase
      t.string :otp_secret, :null => true
      t.datetime :verified_at, :null => true
      t.timestamps
    end
  end
end
