# Devise Jwt Auth

A JWT-based port of [Devise Token Auth](https://github.com/lynndylanhurley/devise_token_auth) with silent refresh support.

If you're building SPA or a mobile app, this library takes an JWT approach to authentication. If you're new to how JWTs (pronounced 'jot') work, you can read up on them [here](https://jwt.io/introduction/). This library is designed with an access/refresh token authentication model in mind.

## How does silent refresh authentication work?

When a user is authenticated, an access token is sent in the response and usually in the body in the form of JSON data. These tokens are designed to last a "short" time - only about 15 minutes. What you do with these tokens is up to you, but the best practice is to keep these tokens in memory and NOT to store them as cookies or in local storage. That way they cannot be used in [XSS](https://en.wikipedia.org/wiki/Cross-site_scripting) or [CSRF](https://en.wikipedia.org/wiki/Cross-site_request_forgery) attacks. The access tokens are then sent as headers in requests when an authenticated user is required to access protected resources.

The downside here is that the user will need to reauthenticate themselves frequently and if the user reloads their browser, the access token disappears and the user is no longer authenticated. This is where refresh tokens come into play.

Refresh tokens are different than access tokens in the fact that they are sent as HTTP only cookies that cannot be accessed using Javascript. These tokens are expected to last a "long" time - a fews days or maybe a week. When the user's access token expires, or the user reloads the page, these tokens persist and then are used for the sole purpose of requesting new access tokens.

An additional feature can allow you to invalidate all the user's tokens by implementing a token version number. Anytime that user changes their password or their security roles change or if they choose to log out of all of their devices, updating the user's token version (usually in the form of incrementing its value) will invalidate all of the user's tokens in the wild. The way this works is by including the user's token version in the JWT payload so when the server authenticates a user, the user is found not only by their `uid` but also their `token_version`.

*Note:* Token versions are not currently supported by this library but will be in the near future.

## Main features

* Oauth2 authentication using [OmniAuth](https://github.com/intridea/omniauth).
* Email authentication using [Devise](https://github.com/plataformatec/devise), including:
  * User registration, update and deletion
  * Login and logout
  * Password reset, account confirmation
* Support for multiple user models.
* It is secure.

This project leverages the following gems:

* [Devise](https://github.com/plataformatec/devise)
* [OmniAuth](https://github.com/intridea/omniauth)

## Installation

Add the following to your `Gemfile`:

~~~ruby
gem 'devise_jwt_auth'
~~~

Then install the gem using bundle:

~~~bash
bundle install
~~~

More documentation will come later as this project progresses.

## Need help?

As this library is fairly new there will be some issues until it matures. Please feel free to post questions here and contributers are also welcome, especially if you have knowledge with continuous integration as I'm fairly new to that and as this is a port of DTA, I'm in the process of configuring the project with its own settings.

## Contributors wanted!

See our [Contribution Guidelines](https://github.com/aarona/devise_jwt_auth/blob/master/.github/CONTRIBUTING.md). Feel free to submit pull requests, review pull requests, or review open issues. If you'd like to get in contact, you can reach me [here](https://github.com/aarona/).

## Live Demos

Live demos will hopefully be added in the future. Currently, I have a [repository](https://github.com/aarona/dja_example) available that is a proof of concept for DJA that uses React as the client. However, the example application only supports sigining up, sigining in and singing out. It doesn't provide a way to reset a user's password for example and other things that DJA supports. Those will be added in the near future.

## License

This project uses the WTFPL
