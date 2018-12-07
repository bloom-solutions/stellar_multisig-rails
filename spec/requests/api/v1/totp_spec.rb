require 'rotp'

RSpec.describe "totp" do

  describe "POST /api/v1/totp" do
    context "TOTP was already created" do
      let(:account) { Stellar::Account.random }
      before do
        create(:stellar_multisig_totp, address: account.address)
      end

      it "responds with `conflict`" do
        post("/api/v1/totp", {
          params: {
            address: account.address,
            passphrase: "jollyman",
            signed_passphrase: account.keypair.sign("jollyman"),
          }
        })

        expect(response).to_not be_successful
        expect(response.code).to be 409
      end
    end

    context(
      "TOTP does not exist, " \
      "signed_passphrase is signed by the address owner"
    ) do
      let(:account) { Stellar::Account.random }

      it "returns a totp provisioning_uri for the given address" do
        post("/api/v1/totp", {
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
        expected_address_abbrev = [
          account_1.address[0..2],
          account_1.address[-3..-1],
        ].join("...")
        expected_path =
          "/issuer:#{ENV["OTP_ISSUER"]}: #{expected_address_abbrev}"
        expect(parsed_provisioning_uri.path).to eq expected_path
        expect(parsed_provisioning_uri.query_params["secret"]).to be_present
      end
    end

    context(
      "TOTP does not exist, " \
      "signed_passphrase is not signed by the address owner"
    ) do
      let(:account_1) { Stellar::Account.random }
      let(:account_2) { Stellar::Account.random }

      it "responds with 401" do
        post("/api/v1/totp", {
          params: {
            address: account_1.address,
            passphrase: "jollyman",
            signed_passphrase: account_2.keypair.sign("jollyman"),
          }
        })

        expect(response).to_not be_successful
        expect(response.code).to eq 401
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

    context "correct OTP and password" do
      it "responds with 200" do
        post("/api/v1/totp", {
          params: {
            address: "GDEL7NYMHKZWLAWAZNXMOKP7GG52QECJQAR33KMEN2G6TC4VV3C4ISA7",
            passphrase: "jollyman",
            otp: totp.now,
          }
        })

        expect(response).to be_successful
        expect(response.code).to eq 200
      end
    end

    context "incorrect OTP and correct password" do
      it "responds with 401" do
        post("/api/v1/totp", {
          params: {
            address: "GDEL7NYMHKZWLAWAZNXMOKP7GG52QECJQAR33KMEN2G6TC4VV3C4ISA7",
            passphrase: "jollyman",
            otp: "123456",
          }
        })

        expect(response).to_not be_successful
        expect(response.code).to eq 401
      end
    end

    context "correct OTP and incorrect password" do
      it "responds with 401" do
        post("/api/v1/totp", {
          params: {
            address: "GDEL7NYMHKZWLAWAZNXMOKP7GG52QECJQAR33KMEN2G6TC4VV3C4ISA7",
            passphrase: "xxxxyman",
            otp: totp.now,
          }
        })

        expect(response).to_not be_successful
        expect(response.code).to eq 401
      end
    end
  end

end
