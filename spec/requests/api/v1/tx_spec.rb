require 'rotp'
require 'stellar-sdk'

RSpec.describe "Transaction signing" do

  describe "GET /api/v1/tx/fee" do
    it "returns the fee required for the server to sign a tx" do
      get("/api/v1/tx/fee")

      expect(response).to be_successful

      parsed_response = JSON.parse(response.body).with_indifferent_access
      expect(parsed_response[:fee_in_stroops]).to eq ENV["FEE_IN_STROOPS"].to_i
    end
  end

  describe "POST /api/v1/tx/sign" do
    let(:otp_secret) { ROTP::Base32.random_base32 }
    let(:totp) { ROTP::TOTP.new(otp_secret) }
    let(:signer_account) do
      Stellar::Account.from_address(CONFIG[:sender_address])
    end
    let(:sender_account) { Stellar::Account.from_seed(CONFIG[:sender_seed]) }
    let(:destination_account) { Stellar::Account.random }
    let(:stellar_client) { Stellar::Client.default_testnet }

    before do
      create(:stellar_multisig_totp, {
        address: "GDEL7NYMHKZWLAWAZNXMOKP7GG52QECJQAR33KMEN2G6TC4VV3C4ISA7",
        passphrase: "jollyman",
        otp_secret: otp_secret,
        verified_at: Time.now,
      })
    end

    context "OTP and password is correct and fee is attached" do
      let(:tx) do
        sequence = stellar_client.account_info(sender_account).sequence.to_i + 1
        Stellar::Transaction.for_account({
          account: sender_account,
          sequence: sequence,
          fee: 100,
        }).tap do |tx|
          tx.operations << Stellar::Operation.create_account(
            destination: destination_account.keypair,
            starting_balance: 0.5
          )
          tx.operations << Stellar::Operation.payment(
            destination: signer_account.keypair,
            amount: CONFIG[:fee_in_stroops] * 1_000_000,
          )
        end
      end
      let(:sender_signed_tx_base64) do
        tx.to_envelope(sender_account.keypair).to_xdr(:base64)
      end

      it "signs the tx" do
        post("/api/v1/tx/sign", params: {
          tx: sender_signed_tx_base64,
          otp: totp.now,
          passphrase: "jollyman"
        })

        expect(response).to be_successful

        parsed_response = JSON.parse(response.body).with_indifferent_access

        signed_tx_envelope_base64 = parsed_response[:tx]
        expect(signed_tx_envelope_base64).to be_present

        envelope_xdr = Stellar::Convert.from_base64(signed_tx_envelope_base64)
        envelope = Stellar::TransactionEnvelope.from_xdr(envelope_xdr)
        expect(envelope).to be_signed_correctly(
          signer_account.keypair,
          destination_account.keypair
        )
      end
    end

    context "OTP and password is correct and no fee is attached" do
      let(:tx) do
        sequence = stellar_client.account_info(sender_account).sequence.to_i + 1
        Stellar::Transaction.for_account({
          account: sender_account,
          sequence: sequence,
          fee: 100,
        }).tap do |tx|
          tx.operations << Stellar::Operation.create_account(
            destination: destination_account.keypair,
            starting_balance: 0.5
          )
        end
      end
      let(:sender_signed_tx_base64) do
        tx.to_envelope(sender_account.keypair).to_xdr(:base64)
      end

      it "responds with 402" do
        post("/api/v1/tx/sign", params: {
          tx: sender_signed_tx_base64,
          otp: totp.now,
          passphrase: "jollyman"
        })

        expect(response).to_not be_successful
        expect(response.code).to eq 402

        parsed_response = JSON.parse(response.body).with_indifferent_access
        expect(parsed_response[:error]).to eq "missing or insufficient fee"
      end
    end

    context "OTP is wrong, password is correct, and fee is attached" do
      let(:tx) do
        sequence = stellar_client.account_info(sender_account).sequence.to_i + 1
        Stellar::Transaction.for_account({
          account: sender_account,
          sequence: sequence,
          fee: 100,
        }).tap do |tx|
          tx.operations << Stellar::Operation.create_account(
            destination: destination_account.keypair,
            starting_balance: 0.5
          )
          tx.operations << Stellar::Operation.payment(
            destination: signer_account.keypair,
            amount: CONFIG[:fee_in_stroops] * 1_000_000,
          )
        end
      end
      let(:sender_signed_tx_base64) do
        tx.to_envelope(sender_account.keypair).to_xdr(:base64)
      end

      it "responds with 401" do
        post("/api/v1/tx/sign", params: {
          tx: sender_signed_tx_base64,
          otp: "123456",
          passphrase: "jollyman"
        })

        expect(response).to_not be_successful
        expect(response.code).to eq 401

        parsed_response = JSON.parse(response.body).with_indifferent_access
        expect(parsed_response[:error]).to eq "Unauthorized"
      end
    end

    context "OTP is correct, password is wrong, and fee is attached" do
      let(:tx) do
        sequence = stellar_client.account_info(sender_account).sequence.to_i + 1
        Stellar::Transaction.for_account({
          account: sender_account,
          sequence: sequence,
          fee: 100,
        }).tap do |tx|
          tx.operations << Stellar::Operation.create_account(
            destination: destination_account.keypair,
            starting_balance: 0.5
          )
          tx.operations << Stellar::Operation.payment(
            destination: signer_account.keypair,
            amount: CONFIG[:fee_in_stroops] * 1_000_000,
          )
        end
      end
      let(:sender_signed_tx_base64) do
        tx.to_envelope(sender_account.keypair).to_xdr(:base64)
      end

      it "responds with 401" do
        post("/api/v1/tx/sign", params: {
          tx: sender_signed_tx_base64,
          otp: totp.now,
          passphrase: "xxxxyman"
        })

        expect(response).to_not be_successful
        expect(response.code).to eq 401

        parsed_response = JSON.parse(response.body).with_indifferent_access
        expect(parsed_response[:error]).to eq "Unauthorized"
      end
    end

  end
end
