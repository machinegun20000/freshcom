defmodule Freshcom.User do
  use Freshcom.Projection

  schema "users" do
    field :default_account_id, UUID

    field :type, :string
    field :status, :string
    field :username, :string
    field :password_hash, :string
    field :email, :string
    field :is_term_accepted, :boolean

    field :first_name, :string
    field :last_name, :string
    field :name, :string

    field :role, :string

    field :password_reset_token, :string
    field :password_reset_token_expires_at, :naive_datetime

    field :email_verified, :boolean
    field :email_verification_token, :string
    field :email_verification_token_expires_at, :naive_datetime

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, Freshcom.Account
  end
end