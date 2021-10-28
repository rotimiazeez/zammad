# Copyright (C) 2012-2021 Zammad Foundation, http://zammad-foundation.org/

module Gql::Mutations
  class Login < BaseMutation
    description 'Performs a user login to create a session'

    field :current_user, Gql::Types::UserType, null: false, description: 'The logged-in user'
    field :session, Gql::Types::SessionType, null: false, description: 'The current session'

    argument :login, String, required: true, description: 'User name'
    argument :password, String, required: true, description: 'Password'
    argument :fingerprint, String, required: true, description: 'Device fingerprint - a string identifying the device used for the login'

    def self.requires_authentication?
      false
    end

    # reimplementation of `authenticate_with_password`
    def resolve(...)

      # Register user for subsequent auth checks.
      context[:current_user] = authenticate(...)

      session = context[:controller].session

      {
        current_user: context[:current_user],
        session:      { session_id: session.id, data: session.to_hash }
      }
    end

    private

    def authenticate(login:, password:, fingerprint:)
      auth = Auth.new(login, password)
      user = auth&.user

      if !auth.valid?
        raise GraphQL::ExecutionError, 'Wrong login or password combination.'
      end

      context[:controller].session.delete(:switched_from_user_id)

      # Fingerprint param is expected for session logins.
      context[:controller].params[:fingerprint] = fingerprint
      # authentication_check_prerequesits is private
      context[:controller].send(:authentication_check_prerequesits, user, 'session', {})

      user
    end
  end
end