require_dependency "stellar_multisig/rails/application_controller"

module StellarMultisig::Rails
  class Api::V1::TotpController < ApplicationController
    before_action :totp_dont_exist, only: [:create]

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

    private

    def totp_params
      params.permit(:address, :passphrase, :otp_secret, :verified_at)
    end

    def make_totp(otp_secret, address)
      ROTP::TOTP.new(otp_secret, issuer: address)
    end

    def totp_dont_exist
      head 409 and return if StellarMultisig::Totp.exists?(address: totp_params["address"])
    end
  end
end
