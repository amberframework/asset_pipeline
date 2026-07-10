# Phase 8 spike — Sign In controller.
#
# Spike finding #3 reshape: render_screen helper split into
# compute_screen_html (which stashes HTML in @screen_html ivar) +
# explicit render("index.ecr") (the shim template echoes the ivar).
# render(html:) does not exist in Amber.
class SignInController < ApplicationController
  @screen_html : String = ""

  def index
    compute_screen_html SignInScreen
    render("index.ecr")
  end

  def submit
    email = params["email"]?.to_s.strip
    password = params["password"]?.to_s.strip

    if email.empty? || password.empty?
      flash[:error] = "Please provide both email and password."
    elsif !email.matches?(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/)
      flash[:error] = "Email format is invalid."
    else
      session["user_email"] = email
      flash[:notice] = "Signed in as #{email}."
    end

    compute_screen_html SignInScreen
    render("index.ecr")
  end
end
