require_dependency "stellar_multisig/rails/application_controller"

module StellarMultisig::Rails
  class Api::V1::TotpController < ApplicationController
    before_action :totp_dont_exist, :invalid_signed_passphrase, only: [:create]
    before_action :totp_must_exist, only: [:verify]

    def create
      address = totp_params["address"]
      otp_secret = ROTP::Base32.random_base32
      totp = make_totp(otp_secret, address)
      StellarMultisig::Totp.create(
        address: address,
        passphrase: totp_params["passphrase"],
        otp_secret: otp_secret
      )
      render json: {
        provisioning_uri: totp.provisioning_uri(address)
      }
    end

    def verify
      sm_totp = StellarMultisig::Totp.find_by(address: totp_params["address"])
      totp = make_totp(sm_totp.otp_secret, sm_totp.address)
      head 401 and return if totp.verify(totp_params["otp"]).nil?
      head 401 and return if sm_totp.passphrase != totp_params["passphrase"]
      sm_totp.verified_at = Time.now
      head 200
    end

    private

    def totp_params
      params.permit(:address, :passphrase, :otp, :signed_passphrase)
    end

    def make_totp(otp_secret, address)
      ROTP::TOTP.new(otp_secret, issuer: address)
    end

    def totp_dont_exist
      head 409 and return if totp_exists?
    end

    def totp_must_exist
      head 404 and return unless totp_exists?
    end

    def invalid_signed_passphrase
      account = Stellar::Account.from_address(params["address"])
      head 401 and return unless account.keypair.verify(params["signed_passphrase"], params["passphrase"])
    end

    def totp_exists?
      StellarMultisig::Totp.exists?(address: totp_params["address"])
    end
  end
end
