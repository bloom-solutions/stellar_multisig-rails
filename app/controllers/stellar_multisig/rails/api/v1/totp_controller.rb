require_dependency "stellar_multisig/rails/application_controller"

module StellarMultisig::Rails
  class Api::V1::TotpController < ApplicationController
    def create
    end

    private

    def totp_params
      params.permit(:address, :passphrase, :otp_secret, :verified_at)
    end
  end
end
