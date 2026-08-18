class AiAccessController < ApplicationController
  def new
  end

  def create
    if correct_code?(params[:code])
      session[:ai_authorized] = true
      redirect_to ask_path, notice: "Access granted."
    else
      flash.now[:alert] = "Incorrect code."
      render :new, status: :unprocessable_content
    end
  end

  private

  def correct_code?(submitted)
    expected = AiCredentials.access_code.to_s
    return false if expected.blank?

    ActiveSupport::SecurityUtils.secure_compare(
      Digest::SHA256.hexdigest(submitted.to_s),
      Digest::SHA256.hexdigest(expected)
    )
  end
end
