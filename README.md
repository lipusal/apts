# Apts

This is a scraper I put together to automate my search for my next apartment. A friend shared a link to [this blogpost](https://dev.to/fernandezpablo/scrappeando-propiedades-con-python-4cp8)
in which a basic Python scraper is built. I decided to iterate over the idea with my specific needs.

The scraper does the following:
1. Connects to your Google Drive account and attempts to read IDs of previously seen listings
1. Executes all configured parsers and extracts listings from each one
1. Notifies of all unseen listings via Telegram
1. Saves IDs of new listings in Google Drive so as to not repeat them on next run

## Installation
0. Install Ruby.
1. Install the [dependencies required for nokogiri](https://nokogiri.org/tutorials/installing_nokogiri.html) (gem to parse HTML)
1. Install bundler to install dependencies:
    ```bash
    gem install bundler
    ```
1. Install dependencies:
    ```bash
    bundle install
    ```
1. [Set up OAuth 2.0](https://support.google.com/cloud/answer/6158849) with Google. Note that this implies:
    1. Creating a project. When you create the project, activate the Drive API.
    1. Creating the client. When you create the client, give it the scope [*drive.file*](https://developers.google.com/identity/protocols/oauth2/scopes#drivev3). 
    1. Download client credentials. Store the `client_secrets.json` file in the root of the project.
1. Make a copy of `.env.example` and call it `.env`. Fill in with appropriate values. If you're not going to
use an optional entry, delete it altogether.
1. Configure your Telegram bot (for more details about bot creation, check the blogpost):
    1. Create it and save its token as `TELEGRAM_TOKEN` in `.env`.
    1. Talk to it.
    1. Get the conversation ID between you and your chatbot.
    1. Save it as `CHAT_ID` in `.env`.

## Usage
### Windows
```cmd
cd <project root>
ruby exe/apts
```
### UNIX
```cmd
cd <project root>
./exe/apts
```

**Note:** On first run, program will print a link to log into your Google account to grant it access to Drive.
Open the link in your browser, log in, copy the authorization code, paste it into the terminal and press enter.
You will not be prompted to do this again until the authorization code expires or becomes invalid.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lipusal/apts. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/apts/blob/master/CODE_OF_CONDUCT.md).


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Apts project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/apts/blob/master/CODE_OF_CONDUCT.md).
