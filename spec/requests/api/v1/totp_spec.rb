require 'rotp'

RSpec.describe "totp" do

  describe "POST /api/v1/totp" do
    context "TOTP was already created" do
      before do
        create(:stellar_multisig_totp, {
          address: "GDEL7NYMHKZWLAWAZNXMOKP7GG52QECJQAR33KMEN2G6TC4VV3C4ISA7",
        })
      end

      it "responds with `conflict`" do
        post("/stellar_multisig/api/v1/totp", {
          params: {
            address: "GDEL7NYMHKZWLAWAZNXMOKP7GG52QECJQAR33KMEN2G6TC4VV3C4ISA7",
            passphrase: "jollyman",
          }
        })

        expect(response).to_not be_successful
        expect(response.code).to be 409
      end
    end

    context "TOTP does not exist" do
      it "returns a totp provisioning_uri for the given address" do
        post("/stellar_multisig/api/v1/totp", {
          params: {
            address: "GDEL7NYMHKZWLAWAZNXMOKP7GG52QECJQAR33KMEN2G6TC4VV3C4ISA7",
            passphrase: "jollyman",
          }
        })

        expect(response).to be_successful

        parsed_response = JSON.parse(response.body).with_indifferent_access

        provisioning_uri = parsed_response[:provisioning_uri]
        expect(provisioning_uri).to be_present

        parsed_provisioning_uri = Addressable::URI.parse(provisioning_uri)
        expect(parsed_provisioning_uri.scheme).to eq "otpauth"
        expect(parsed_provisioning_uri.host).to eq "totp"
        expect(parsed_provisioning_uri.path).
          to eq "/issuer:#{ENV["OTP_ISSUER"]}: DEL...SA7"
        expect(parsed_provisioning_uri.query_params["secret"]).to be_present
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
        post("/stellar_multisig/api/v1/totp", {
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
        post("/stellar_multisig/api/v1/totp", {
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
        post("/stellar_multisig/api/v1/totp", {
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
