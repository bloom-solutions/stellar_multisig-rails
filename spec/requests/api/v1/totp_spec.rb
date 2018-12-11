require 'rotp'
require 'stellar-sdk'

RSpec.describe "totp" do

  # TODO
  # - add a way to verify that user has control of the seed via something like
  #   signed_passphrase: "THIS IS SIGNED jollyman"
  # - what happens when creating totp record fails?
  describe "POST /api/v1/totp" do
    context "TOTP was already created" do
      let(:account) { Stellar::Account.random }
      before do
        create(:stellar_multisig_totp, address: account.address)
      end

      it "responds with `conflict`" do
        post("/stellar_multisig/api/v1/totp", {
          params: {
            address: account.address,
            passphrase: "jollyman",
            signed_passphrase: account.keypair.sign("jollyman"),
          }
        })

        expect(response).to_not be_successful
        expect(response.code.to_i).to be 409
      end
    end

    context(
      "TOTP does not exist, " \
      "signed_passphrase is signed by the address owner"
    ) do
      let(:account) { Stellar::Account.random }

      it "returns a totp provisioning_uri for the given address" do
        post("/stellar_multisig/api/v1/totp", {
          params: {
            address: account.address,
            passphrase: "jollyman",
            signed_passphrase: account.keypair.sign("jollyman"),
          }
        })

        expect(response).to be_successful

        parsed_response = JSON.parse(response.body).with_indifferent_access

        provisioning_uri = parsed_response[:provisioning_uri]
        expect(provisioning_uri).to be_present

        parsed_provisioning_uri = Addressable::URI.parse(provisioning_uri)
        expect(parsed_provisioning_uri.scheme).to eq "otpauth"
        expect(parsed_provisioning_uri.host).to eq "totp"

        expected_path = "/#{account.address}:#{account.address}"
        expect(parsed_provisioning_uri.path).to eq expected_path
        expect(parsed_provisioning_uri.query_values["secret"]).to be_present
        expect(parsed_provisioning_uri.query_values["issuer"]).to eq "#{account.address}"
      end
    end

    context(
      "TOTP does not exist, " \
      "signed_passphrase is not signed by the address owner"
    ) do
      let(:account_1) { Stellar::Account.random }
      let(:account_2) { Stellar::Account.random }

      it "responds with 401" do
        post("/stellar_multisig/api/v1/totp", {
          params: {
            address: account_1.address,
            passphrase: "jollyman",
            signed_passphrase: account_2.keypair.sign("jollyman"),
          }
        })

        expect(response).to_not be_successful
        expect(response.code.to_i).to eq 401
      end
    end
  end

  describe "POST /api/v1/totp/verify" do
    let(:otp_secret) { ROTP::Base32.random_base32 }
    let(:totp) { ROTP::TOTP.new(otp_secret) }

    before do
      create(:stellar_multisig_totp, {
        address: "GDEL7NYMHKZWLAWAZNXMOKP7GG52QECJQAR33KMEN2G6TC4VV3C4ISA7",
        passphrase: "jollyman",
        otp_secret: otp_secret,
      })
    end

    context "TOTP does not exist" do
      it "responds with 404" do
        post("/stellar_multisig/api/v1/totp/verify", {
          params: {
            address: "example",
            passphrase: "jollyman",
            otp: totp.now
          }
        })

        expect(response).to_not be_successful
        expect(response.code.to_i).to eq 404
      end
    end

    context "correct OTP and password" do
      it "responds with 200" do
        post("/stellar_multisig/api/v1/totp/verify", {
          params: {
            address: "GDEL7NYMHKZWLAWAZNXMOKP7GG52QECJQAR33KMEN2G6TC4VV3C4ISA7",
            passphrase: "jollyman",
            otp: totp.now,
          }
        })

        expect(response).to be_successful
        expect(response.code.to_i).to eq 200
      end
    end

    context "incorrect OTP and correct password" do
      it "responds with 401" do
        post("/stellar_multisig/api/v1/totp/verify", {
          params: {
            address: "GDEL7NYMHKZWLAWAZNXMOKP7GG52QECJQAR33KMEN2G6TC4VV3C4ISA7",
            passphrase: "jollyman",
            otp: "123456",
          }
        })

        expect(response).to_not be_successful
        expect(response.code.to_i).to eq 401
      end
    end

    context "correct OTP and incorrect password" do
      it "responds with 401" do
        post("/stellar_multisig/api/v1/totp/verify", {
          params: {
            address: "GDEL7NYMHKZWLAWAZNXMOKP7GG52QECJQAR33KMEN2G6TC4VV3C4ISA7",
            passphrase: "xxxxyman",
            otp: totp.now,
          }
        })

        expect(response).to_not be_successful
        expect(response.code.to_i).to eq 401
      end
    end
  end
end
